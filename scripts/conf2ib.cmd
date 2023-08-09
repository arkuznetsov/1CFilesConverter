@rem ----------------------------------------------------------
@rem This Source Code Form is subject to the terms of the
@rem Mozilla Public License, v.2.0. If a copy of the MPL
@rem was not distributed with this file, You can obtain one
@rem at http://mozilla.org/MPL/2.0/.
@rem ----------------------------------------------------------
@rem Codebase: https://github.com/ArKuznetsov/1CFilesConverter/
@rem ----------------------------------------------------------

@ECHO OFF

SETLOCAL

set CONVERT_VERSION=UNKNOWN
IF exist "..\VERSION" FOR /F "usebackq tokens=* delims=" %%i IN ("..\VERSION") DO set CONVERT_VERSION=%%i
echo 1C files converter v.%CONVERT_VERSION%
echo ===
echo Load 1C configuration to 1C infobase

set ERROR_CODE=0

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290
IF not defined V8_TEMP set V8_TEMP=%TEMP%\1c

IF not "%V8_CONVERT_TOOL%" equ "designer" IF not "%V8_CONVERT_TOOL%" equ "ibcmd" set V8_CONVERT_TOOL=designer
set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
IF "%V8_CONVERT_TOOL%" equ "designer" IF not exist %V8_TOOL% (
    echo Could not find 1C:Designer with path %V8_TOOL%
    exit /b 1
)
set IBCMD_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\ibcmd.exe"
IF "%V8_CONVERT_TOOL%" equ "ibcmd" IF not exist %IBCMD_TOOL% (
    echo Could not find ibcmd tool with path %IBCMD_TOOL%
    exit /b 1
)
IF not defined V8_RING_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
        set V8_RING_TOOL="%%i"
    )
)
IF not defined V8_RING_TOOL (
    echo [ERROR] Can't find "ring" tool. Add path to "ring.bat" to "PATH" environment variable, or set "V8_RING_TOOL" variable with full specified path 
    set ERROR_CODE=1
)

set LOCAL_TEMP=%V8_TEMP%\%~n0
set XML_PATH=%LOCAL_TEMP%\tmp_xml
set WS_PATH=%LOCAL_TEMP%\edt_ws

set ARG=%1
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_SRC_PATH=%ARG%
set ARG=%2
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_DST_PATH=%ARG%

IF not defined V8_SRC_PATH (
    echo [ERROR] Missed parameter 1 - "path to 1C configuration source (1C configuration file (*.cf), 1C:Designer XML files or 1C:EDT project)"
    set ERROR_CODE=1
)
IF not defined V8_DST_PATH (
    echo [ERROR] Missed parameter 2 - "path to folder contains 1C infobase"
    set ERROR_CODE=1
)
IF %ERROR_CODE% neq 0 (
    echo ===
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - path to 1C configuration source ^(1C configuration file ^(*.cf^), 1C:Designer XML files or 1C:EDT project^)
    echo     %%2 - path to folder contains 1C infobase
    echo.
    exit /b %ERROR_CODE%
)

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"
md "%LOCAL_TEMP%"
IF exist "%V8_DST_PATH%" rd /S /Q "%V8_DST_PATH%"
md "%V8_DST_PATH%"

echo [INFO] Checking configuration source type...

IF /i "%V8_SRC_PATH:~-3%" equ ".cf" (
    echo [INFO] Source type: Configuration file ^(CF^)
    goto export_cf
)
IF exist "%V8_SRC_PATH%\DT-INF\" (
    echo [INFO] Source type: 1C:EDT project
    goto export_edt
)
IF exist "%V8_SRC_PATH%\Configuration.xml" (
    echo [INFO] Source type: 1C:Designer XML files
    set XML_PATH=%V8_SRC_PATH%
    goto export_xml
)

echo [ERROR] Error cheking type of configuration "%V8_SRC_PATH%"!
echo Configuration file ^(*.cf^), 1C:Designer XML files or 1C:EDT project expected.
exit /b 1

:export_edt

echo [INFO] Export "%V8_SRC_PATH%" to 1C:Designer XML format "%XML_PATH%"...

md "%XML_PATH%"
md "%WS_PATH%"

call %V8_RING_TOOL% edt workspace export --project "%V8_SRC_PATH%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%"

:export_xml

IF "%V8_CONVERT_TOOL%" equ "designer" (
    echo [INFO] Creating infobase "%V8_DST_PATH%"...
    %V8_TOOL% CREATEINFOBASE File="%V8_DST_PATH%"; /DisableStartupDialogs

    echo [INFO] Loading infobase "%V8_DST_PATH%" configuration from XML-files "%XML_PATH%"...
    %V8_TOOL% DESIGNER /IBConnectionString File="%V8_DST_PATH%"; /DisableStartupDialogs /LoadConfigFromFiles "%XML_PATH%"
) ELSE (
    echo [INFO] Creating infobase "%V8_DST_PATH%" from XML files "%XML_PATH%"...
    %IBCMD_TOOL% infobase create --db-path="%V8_DST_PATH%" --create-database --import="%XML_PATH%"
)

goto end

:export_cf

echo [INFO] Creating infobase "%V8_DST_PATH%" from file "%V8_SRC_PATH%"...
IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% CREATEINFOBASE File="%V8_DST_PATH%"; /DisableStartupDialogs /UseTemplate "%V8_SRC_PATH%"
) ELSE (
    %IBCMD_TOOL% infobase create --db-path="%V8_DST_PATH%" --create-database --load="%V8_SRC_PATH%"
)

:end

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"

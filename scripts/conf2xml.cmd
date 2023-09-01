@rem ----------------------------------------------------------
@rem This Source Code Form is subject to the terms of the
@rem Mozilla Public License, v.2.0. If a copy of the MPL
@rem was not distributed with this file, You can obtain one
@rem at http://mozilla.org/MPL/2.0/.
@rem ----------------------------------------------------------
@rem Codebase: https://github.com/ArKuznetsov/1CFilesConverter/
@rem ----------------------------------------------------------

@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

set CONVERT_VERSION=UNKNOWN
IF exist "..\VERSION" FOR /F "usebackq tokens=* delims=" %%i IN ("..\VERSION") DO set CONVERT_VERSION=%%i
echo 1C files converter v.%CONVERT_VERSION%
echo ===
echo Convert 1C configuration to 1C:Designer XML format

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
set IB_PATH=%LOCAL_TEMP%\tmp_db
set WS_PATH=%LOCAL_TEMP%\edt_ws

set ARG=%1
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_SRC_PATH=%ARG%
set ARG=%2
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_DST_PATH=%ARG%

IF not defined V8_SRC_PATH (
    echo [ERROR] Missed parameter 1 - "path to 1C configuration source (1C configuration file (*.cf), infobase or 1C:EDT project)"
    set ERROR_CODE=1
)
IF not defined V8_DST_PATH (
    echo [ERROR] Missed parameter 2 - "path to folder to save configuration files in 1C:Designer XML format"
    set ERROR_CODE=1
)
IF %ERROR_CODE% neq 0 (
    echo ===
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - path to 1C configuration source ^(1C configuration file ^(*.cf^), infobase or 1C:EDT project^)
    echo     %%2 - path to folder to save configuration files in 1C:Designer XML format
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
    set V8_IB_CONNECTION=File="!IB_PATH!";
    goto export_cf
)
IF /i "%V8_SRC_PATH:~0,2%" equ "/F" (
    set V8_IB_PATH=%V8_SRC_PATH:~2%
    echo [INFO] Source type: File infobase ^(!V8_IB_PATH!^)
    set V8_IB_CONNECTION=File="!V8_IB_PATH!";
    goto export_ib
)
IF /i "%V8_SRC_PATH:~0,2%" equ "/S" (
    set V8_IB_PATH=%V8_SRC_PATH:~2%
    FOR /F "tokens=1,2 delims=\" %%a IN ("!V8_IB_PATH!") DO (
        set V8_IB_SERVER=%%a
        set V8_IB_NAME=%%b
    )
    echo [INFO] Source type: File infobase ^(!V8_IB_SERVER!\!V8_IB_NAME!^)
    set IB_PATH=!V8_IB_SERVER!\!V8_IB_NAME!
    set V8_IB_CONNECTION=Srvr="!V8_IB_SERVER!";Ref="!V8_IB_NAME!";
    IF not defined V8_DB_SRV_DBMS set V8_DB_SRV_DBMS=MSSQLServer
    goto export_ib
)
IF exist "%V8_SRC_PATH%\1cv8.1cd" (
    echo [INFO] Source type: File infobase ^(!V8_SRC_PATH!^)
    set IB_PATH=%V8_SRC_PATH%
    set V8_IB_CONNECTION=File="!V8_SRC_PATH!";
    goto export_ib
)
IF exist "%V8_SRC_PATH%\DT-INF\" (
    echo [INFO] Source type: 1C:EDT project
    set V8_IB_CONNECTION=File="!IB_PATH!";
    goto export_edt
)

echo [ERROR] Error cheking type of configuration "%V8_SRC_PATH%"!
echo Infobase, configuration file ^(*.cf^) or 1C:EDT project expected.
exit /b 1

:export_cf

echo [INFO] Creating infobase "%IB_PATH%" from file "%V8_SRC_PATH%"...

md "%IB_PATH%"

IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% CREATEINFOBASE File="%IB_PATH%"; /DisableStartupDialogs /UseTemplate "%V8_SRC_PATH%"
) ELSE (
    %IBCMD_TOOL% infobase create --db-path="%IB_PATH%" --create-database --load="%V8_SRC_PATH%"
)

:export_ib

echo [INFO] Export configuration from infobase "%IB_PATH%" to 1C:Designer XML format "%V8_DST_PATH%"...
IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% DESIGNER /IBConnectionString %V8_IB_CONNECTION% /DisableStartupDialogs /DumpConfigToFiles "%V8_DST_PATH%" -force
) ELSE (
    IF defined V8_IB_SERVER (
        %IBCMD_TOOL% infobase config export --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_IB_SERVER% --db-name="%V8_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" "%V8_DST_PATH%" --force
    ) ELSE (
        %IBCMD_TOOL% infobase config export --db-path="%IB_PATH%" "%V8_DST_PATH%" --force
    )
)

goto end

:export_edt

echo [INFO] Export "%V8_SRC_PATH%" to 1C:Designer XML format "%V8_DST_PATH%"...

md "%WS_PATH%"

call %V8_RING_TOOL% edt workspace export --project "%V8_SRC_PATH%" --configuration-files "%V8_DST_PATH%" --workspace-location "%WS_PATH%"

:end

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"

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

IF not defined V8_ENCODING set V8_ENCODING=65001
chcp %V8_ENCODING% > nul

set CONVERT_VERSION=UNKNOWN
IF exist "%~dp0..\VERSION" FOR /F "usebackq tokens=* delims=" %%i IN ("%~dp0..\VERSION") DO set CONVERT_VERSION=%%i
echo 1C files converter v.%CONVERT_VERSION%
echo ======
echo [INFO] Convert 1C configuration extension to binary format ^(*.cfe^)

set ERROR_CODE=0

IF exist "%cd%\.env" (
    FOR /F "tokens=*" %%a in (%cd%\.env) DO (
        FOR /F "tokens=1,2 delims==" %%b IN ("%%a") DO (
            IF not defined %%b set "%%b=%%c"
        )
    )
)

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290
IF not defined V8_TEMP set V8_TEMP=%TEMP%\1c

echo [INFO] Using 1C:Enterprise, version %V8_VERSION%
echo [INFO] Using temporary folder "%V8_TEMP%"

IF not "%V8_CONVERT_TOOL%" equ "designer" IF not "%V8_CONVERT_TOOL%" equ "ibcmd" set V8_CONVERT_TOOL=designer
set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
IF "%V8_CONVERT_TOOL%" equ "designer" IF not exist %V8_TOOL% (
    echo Could not find 1C:Designer with path %V8_TOOL%
    set ERROR_CODE=1
    goto finally
)
set IBCMD_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\ibcmd.exe"
IF "%V8_CONVERT_TOOL%" equ "ibcmd" IF not exist %IBCMD_TOOL% (
    echo Could not find ibcmd tool with path %IBCMD_TOOL%
    set ERROR_CODE=1
    goto finally
)

IF defined V8_EDT_VERSION (
    set V8_EDT_VERSION=@%V8_EDT_VERSION:@=%
)

echo [INFO] Start conversion using "%V8_CONVERT_TOOL%"

set LOCAL_TEMP=%V8_TEMP%\%~n0
set IB_PATH=%LOCAL_TEMP%\tmp_db
set XML_PATH=%LOCAL_TEMP%\tmp_xml
set WS_PATH=%LOCAL_TEMP%\edt_ws

set ARG=%1
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_SRC_PATH=%ARG%
set ARG=%2
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_DST_PATH=%ARG%
set V8_DST_FOLDER=%~dp2
set V8_DST_FOLDER=%V8_DST_FOLDER:~0,-1%
set ARG=%3
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_EXT_NAME=%ARG%

IF not defined V8_SRC_PATH (
    echo [ERROR] Missed parameter 1 - "path to folder contains 1C extension in 1C:Designer XML format or EDT project"
    set ERROR_CODE=1
) ELSE (
    IF not exist "%V8_SRC_PATH%" (
        echo [ERROR] Path "%V8_SRC_PATH%" doesn't exist ^(parameter 1^).
        set ERROR_CODE=1
    )
)
IF not defined V8_DST_PATH (
    echo [ERROR] Missed parameter 2 - "path to 1C configuration extension file (*.cfe)"
    set ERROR_CODE=1
)
IF not defined V8_EXT_NAME (
    echo [ERROR] Missed parameter 3 - "configuration extension name"
    set ERROR_CODE=1
)
IF defined V8_BASE_IB (
    set V8_BASE_IB=%V8_BASE_IB:"=%
) ELSE (
    echo [INFO] Environment variable "V8_BASE_IB" is not defined, temporary file infobase will be used.
    set V8_BASE_IB=
)
IF defined V8_BASE_CONFIG (
    set V8_BASE_CONFIG=%V8_BASE_CONFIG:"=%
) ELSE (
    echo [INFO] Environment variable "V8_BASE_CONFIG" is not defined, empty configuration will be used.
    set V8_BASE_CONFIG=
)
IF %ERROR_CODE% neq 0 (
    echo ======
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - path to folder contains 1C extension in 1C:Designer XML format or EDT project
    echo     %%2 - path to 1C configuration extension file ^(*.cfe^)
    echo     %%3 - configuration extension name
    echo.
    goto finally
)

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"
md "%LOCAL_TEMP%"
IF not exist "%V8_DST_FOLDER%" md "%V8_DST_FOLDER%"

echo [INFO] Set infobase for export configuration extension...

IF "%V8_BASE_IB%" equ "" (
    md "%IB_PATH%"
    echo [INFO] Creating temporary file infobase "%IB_PATH%"...
    set V8_BASE_IB_CONNECTION=File="%IB_PATH%";
    %V8_TOOL% CREATEINFOBASE !V8_BASE_IB_CONNECTION! /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!"
    goto prepare_ib
)
IF /i "%V8_BASE_IB:~0,2%" equ "/F" (
    set IB_PATH=%V8_BASE_IB:~2%
    echo [INFO] Basic config type: File infobase ^(!IB_PATH!^)
    set V8_BASE_IB_CONNECTION=File="!IB_PATH!";
    goto prepare_ib
)
IF /i "%V8_BASE_IB:~0,2%" equ "/S" (
    set IB_PATH=%V8_BASE_IB:~2%
    FOR /F "tokens=1,2 delims=\" %%a IN ("!IB_PATH!") DO (
        set V8_BASE_IB_SERVER=%%a
        set V8_BASE_IB_NAME=%%b
    )
    set IB_PATH=!V8_BASE_IB_SERVER!\!V8_BASE_IB_NAME!
    echo [INFO] Basic config type: Server infobase ^(!V8_BASE_IB_SERVER!\!V8_BASE_IB_NAME!^)
    set V8_BASE_IB_CONNECTION=Srvr="!V8_BASE_IB_SERVER!";Ref="!V8_BASE_IB_NAME!";
    IF not defined V8_DB_SRV_DBMS set V8_DB_SRV_DBMS=MSSQLServer
    goto prepare_ib
)
IF exist "%V8_BASE_IB%\1cv8.1cd" (
    set IB_PATH=%V8_BASE_IB%
    echo [INFO] Basic config type: File infobase ^(!V8_SRC_PATH!^)
    set V8_BASE_IB_CONNECTION=File="!IB_PATH!";
    goto prepare_ib
)

:prepare_ib

IF "%V8_BASE_CONFIG%" equ "" goto export

IF not exist "%IB_PATH%" md "%IB_PATH%"
call %~dp0conf2ib.cmd "%V8_BASE_CONFIG%" "%IB_PATH%"
IF ERRORLEVEL 0 goto export

echo [ERROR] Error cheking type of basic configuration "%V8_BASE_CONFIG%"!
echo File or server infobase, configuration file ^(*.cf^), 1C:Designer XML, 1C:EDT project or no configuration expected.
    set ERROR_CODE=1
    goto finally

:export

echo [INFO] Checking 1C extension source type...

IF exist "%V8_SRC_PATH%\DT-INF\" (
    IF exist "%V8_SRC_PATH%\src\Configuration\Configuration.mdo" (
        FOR /F "delims=" %%t IN ('findstr /r /i "<objectBelonging>" "%V8_SRC_PATH%\src\Configuration\Configuration.mdo"') DO (
            echo [INFO] Source type: 1C:EDT project
            md "%XML_PATH%"
            md "%WS_PATH%"
            goto export_edt
        )
    )
)
IF exist "%V8_SRC_PATH%\Configuration.xml" (
    FOR /F "delims=" %%t IN ('findstr /r /i "<objectBelonging>" "%V8_SRC_PATH%\Configuration.xml"') DO (
        echo [INFO] Source type: 1C:Designer XML files
        set XML_PATH=%V8_SRC_PATH%
        goto export_xml
    )
)

echo [ERROR] Wrong path "%V8_SRC_PATH%"!
echo Folder containing configuration extension in 1C:Designer XML format or 1C:EDT project expected.
set ERROR_CODE=1
goto finally

:export_edt

echo [INFO] Export configuration extension from 1C:EDT format "%V8_SRC_PATH%" to 1C:Designer XML format "%XML_PATH%"...
IF not defined V8_RING_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
        set V8_RING_TOOL="%%i"
    )
)
IF not defined V8_RING_TOOL (
    echo [ERROR] Can't find "ring" tool. Add path to "ring.bat" to "PATH" environment variable, or set "V8_RING_TOOL" variable with full specified path 
    set ERROR_CODE=1
    goto finally
)
call %V8_RING_TOOL% edt%V8_EDT_VERSION% workspace export --project "%V8_SRC_PATH%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%"
IF not ERRORLEVEL 0 (
    set ERROR_CODE=%ERRORLEVEL%
    goto finally
)

:export_xml

echo [INFO] Loading configuration extension from XML-files "%XML_PATH%" to infobase "%IB_PATH%"...
IF "%V8_CONVERT_TOOL%" equ "designer" (
    set V8_DESIGNER_LOG=%LOCAL_TEMP%\v8_designer_output.log
    %V8_TOOL% DESIGNER /IBConnectionString %V8_BASE_IB_CONNECTION% /N"%V8_IB_USER%" /P"%V8_IB_PWD%" /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!" /LoadConfigFromFiles "%XML_PATH%" -Extension %V8_EXT_NAME%
    FOR /F "tokens=* delims=" %%i IN (!V8_DESIGNER_LOG!) DO IF "%%i" neq "" echo [WARN] %%i
) ELSE (
    IF defined V8_BASE_IB_SERVER (
        %IBCMD_TOOL% infobase config import --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_BASE_IB_SERVER% --db-name="%V8_BASE_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%" --extension=%V8_EXT_NAME% "%XML_PATH%"
    ) ELSE (
        %IBCMD_TOOL% infobase config import --db-path="%IB_PATH%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%" --extension=%V8_EXT_NAME% "%XML_PATH%"
    )
)
IF not ERRORLEVEL 0 (
    set ERROR_CODE=%ERRORLEVEL%
    goto finally
)

:export_ib

echo [INFO] Export configuration extension from infobase "%IB_PATH%" configuration to "%V8_DST_PATH%"...
IF "%V8_CONVERT_TOOL%" equ "designer" (
    set V8_DESIGNER_LOG=%LOCAL_TEMP%\v8_designer_output.log
    %V8_TOOL% DESIGNER /IBConnectionString %V8_BASE_IB_CONNECTION% /N"%V8_IB_USER%" /P"%V8_IB_PWD%" /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!" /DumpCfg  "%V8_DST_PATH%" -Extension %V8_EXT_NAME%
    FOR /F "tokens=* delims=" %%i IN (!V8_DESIGNER_LOG!) DO IF "%%i" neq "" echo [WARN] %%i
) ELSE (
    IF defined V8_BASE_IB_SERVER (
        %IBCMD_TOOL% infobase config save --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_BASE_IB_SERVER% --db-name="%V8_BASE_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%" --extension=%V8_EXT_NAME% "%V8_DST_PATH%"
    ) ELSE (
        %IBCMD_TOOL% infobase config save --db-path="%IB_PATH%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%" --extension=%V8_EXT_NAME% "%V8_DST_PATH%"
    )
)
set ERROR_CODE=%ERRORLEVEL%

:finally

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"

exit /b %ERROR_CODE%

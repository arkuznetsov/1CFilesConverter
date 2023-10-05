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
echo [INFO] Load 1C configuration to 1C infobase

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
set XML_PATH=%LOCAL_TEMP%\tmp_xml
set WS_PATH=%LOCAL_TEMP%\edt_ws

set ARG=%1
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_SRC_PATH=%ARG%
set ARG=%2
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_DST_PATH=%ARG%
set ARG=%3
IF defined ARG set ARG=%ARG:"=%
IF /i "%ARG%" equ "create" (
    set V8_IB_CREATE=1
) ELSE (
    set V8_IB_CREATE=0
)

IF not defined V8_SRC_PATH (
    echo [ERROR] Missed parameter 1 - "path to 1C configuration source (1C configuration file (*.cf), 1C:Designer XML files or 1C:EDT project)"
    set ERROR_CODE=1
)
IF not defined V8_DST_PATH (
    echo [ERROR] Missed parameter 2 - "path to folder contains 1C infobase"
    set ERROR_CODE=1
)
IF %ERROR_CODE% neq 0 (
    echo ======
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - path to 1C configuration source ^(1C configuration file ^(*.cf^), 1C:Designer XML files or 1C:EDT project^)
    echo     %%2 - path to folder contains 1C infobase
    echo.
    goto finally
)

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"
md "%LOCAL_TEMP%"

echo [INFO] Checking configuration %V8_DST_PATH% destination type...

IF /i "%V8_DST_PATH:~0,2%" equ "/F" (
    set IB_PATH=%V8_DST_PATH:~2%
    echo [INFO] Destination type: File infobase ^(!IB_PATH!^)
    set V8_IB_CONNECTION=File="!IB_PATH!";
    goto check_src
)
IF /i "%V8_DST_PATH:~0,2%" equ "/S" (
    set IB_PATH=%V8_DST_PATH:~2%
    FOR /F "tokens=1,2 delims=\" %%a IN ("!IB_PATH!") DO (
        set V8_IB_SERVER=%%a
        set V8_IB_NAME=%%b
    )
    echo [INFO] Destination type: Server infobase ^(!V8_IB_SERVER!\!V8_IB_NAME!^)
    set IB_PATH=!V8_IB_SERVER!\!V8_IB_NAME!
    set V8_IB_CONNECTION=Srvr="!V8_IB_SERVER!";Ref="!V8_IB_NAME!";
    IF not defined V8_DB_SRV_DBMS set V8_DB_SRV_DBMS=MSSQLServer
    goto check_src
)
set IB_PATH=%V8_DST_PATH%
IF exist "%IB_PATH%\1cv8.1cd" (
    echo [INFO] Destination type: File infobase ^(%IB_PATH%^)
    set V8_IB_CONNECTION=File="%IB_PATH%";
    goto check_src
)
IF not exist "%IB_PATH%" (
    echo [INFO] Destination type: New file infobase ^(%IB_PATH%^)
    set V8_IB_CONNECTION=File="%IB_PATH%";
    md "%IB_PATH%"
    goto check_src
)
IF "%V8_IB_CREATE%" equ "1" (
    echo [INFO] Destination type: New file infobase ^(%IB_PATH%^)
    set V8_IB_CONNECTION=File="%IB_PATH%";
    IF exist "%IB_PATH%" rd /S /Q "%IB_PATH%"
    md "%IB_PATH%"
    goto check_src
)

echo [ERROR] Error cheking type of destination "%V8_DST_PATH%"!
echo Server or file infobase expected.
set ERROR_CODE=1
goto finally

:check_src

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
set ERROR_CODE=1
goto finally

:export_edt

echo [INFO] Export "%V8_SRC_PATH%" to 1C:Designer XML format "%XML_PATH%"...

md "%XML_PATH%"
md "%WS_PATH%"

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

IF "%V8_CONVERT_TOOL%" equ "designer" (
    set V8_DESIGNER_LOG=%LOCAL_TEMP%\v8_designer_output.log
    IF "%V8_IB_CREATE%" equ "1" (
        echo [INFO] Creating infobase "%IB_PATH%"...
        %V8_TOOL% CREATEINFOBASE %V8_IB_CONNECTION% /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!"
        FOR /F "tokens=* delims=" %%i IN (!V8_DESIGNER_LOG!) DO IF "%%i" neq "" echo [WARN] %%i
    )
    echo [INFO] Loading infobase "%IB_PATH%" configuration from XML-files "%XML_PATH%"...
    %V8_TOOL% DESIGNER /IBConnectionString %V8_IB_CONNECTION% /N"%V8_IB_USER%" /P"%V8_IB_PWD%" /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!" /LoadConfigFromFiles "%XML_PATH%"
    FOR /F "tokens=* delims=" %%i IN (!V8_DESIGNER_LOG!) DO IF "%%i" neq "" echo [WARN] %%i
) ELSE (
    IF defined V8_IB_SERVER (
        IF "%V8_IB_CREATE%" equ "1" (
            echo [INFO] Creating infobase "%IB_PATH%" from XML-files "%XML_PATH%"...
            %IBCMD_TOOL% infobase create --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_IB_SERVER% --db-name="%V8_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" --create-database --import="%XML_PATH%"
        ) ELSE (
            echo [INFO] Loading infobase "%IB_PATH%" configuration from XML-files "%XML_PATH%"...
            %IBCMD_TOOL% infobase config import --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_IB_SERVER% --db-name="%V8_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%" "%XML_PATH%"
        )
    ) ELSE (
        IF "%V8_IB_CREATE%" equ "1" (
            echo [INFO] Creating infobase "%IB_PATH%" from XML-files "%XML_PATH%"...
            %IBCMD_TOOL% infobase create --db-path="%V8_DST_PATH%" --create-database --import="%XML_PATH%"
        ) ELSE (
            echo [INFO] Loading infobase "%IB_PATH%" configuration from XML-files "%XML_PATH%"...
            %IBCMD_TOOL% infobase config import --db-path="%V8_DST_PATH%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%" "%XML_PATH%"
        )
    )
)
set ERROR_CODE=%ERRORLEVEL%
goto finally

:export_cf

IF "%V8_CONVERT_TOOL%" equ "designer" (
    set V8_DESIGNER_LOG=%LOCAL_TEMP%\v8_designer_output.log
    IF "%V8_IB_CREATE%" equ "1" (
        echo [INFO] Creating infobase "%IB_PATH%" from file "%V8_SRC_PATH%"...
        %V8_TOOL% CREATEINFOBASE %V8_IB_CONNECTION% /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!" /UseTemplate "%V8_SRC_PATH%"
    ) ELSE (
        echo [INFO] Loading infobase "%IB_PATH%" configuration from file "%V8_SRC_PATH%"...
        %V8_TOOL% DESIGNER /IBConnectionString %V8_IB_CONNECTION% /N"%V8_IB_USER%" /P"%V8_IB_PWD%" /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!" /LoadCfg "%V8_SRC_PATH%"
    )
    FOR /F "tokens=* delims=" %%i IN (!V8_DESIGNER_LOG!) DO IF "%%i" neq "" echo [WARN] %%i
) ELSE (
    IF defined V8_IB_SERVER (
        IF "%V8_IB_CREATE%" equ "1" (
            echo [INFO] Creating infobase "%IB_PATH%" from file "%V8_SRC_PATH%"...
            %IBCMD_TOOL% infobase create --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_IB_SERVER% --db-name="%V8_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" --create-database --load="%V8_SRC_PATH%"
        ) ELSE (
            echo [INFO] Loading infobase "%IB_PATH%" configuration from file "%V8_SRC_PATH%"...
            %IBCMD_TOOL% infobase config load --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_IB_SERVER% --db-name="%V8_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%" "%V8_SRC_PATH%"
        )
    ) ELSE (
        IF "%V8_IB_CREATE%" equ "1" (
            echo [INFO] Creating infobase "%IB_PATH%" from file "%V8_SRC_PATH%"...
            %IBCMD_TOOL% infobase create --db-path="%V8_DST_PATH%" --create-database --load="%V8_SRC_PATH%"
        ) ELSE (
            echo [INFO] Loading infobase "%IB_PATH%" configuration from file "%V8_SRC_PATH%"...
            %IBCMD_TOOL% infobase config load --db-path="%V8_DST_PATH%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%" "%V8_SRC_PATH%"
        )
    )
)
IF not ERRORLEVEL 0 (
    set ERROR_CODE=%ERRORLEVEL%
)

:finally

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"

exit /b %ERROR_CODE%

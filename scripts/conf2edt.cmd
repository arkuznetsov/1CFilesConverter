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
echo [INFO] Convert 1C configuration to 1C:EDT project

set ERROR_CODE=0

IF exist "%cd%\.env" IF "%V8_SKIP_ENV%" neq "1" (
    FOR /F "usebackq tokens=*" %%a in ("%cd%\.env") DO (
        FOR /F "tokens=1* delims==" %%b IN ("%%a") DO ( 
            IF not defined %%b set "%%b=%%c"
        )
    )
)

IF not defined V8_VERSION set V8_VERSION=8.3.23.2040
IF not defined V8_TEMP set V8_TEMP=%TEMP%\1c

echo [INFO] Using 1C:Enterprise, version %V8_VERSION%
echo [INFO] Using temporary folder "%V8_TEMP%"

IF not "%V8_CONVERT_TOOL%" equ "designer" IF not "%V8_CONVERT_TOOL%" equ "ibcmd" set V8_CONVERT_TOOL=designer
IF not defined V8_TOOL set V8_TOOL="%PROGRAMW6432%\1cv8\%V8_VERSION%\bin\1cv8.exe"
IF "%V8_CONVERT_TOOL%" equ "designer" IF not exist %V8_TOOL% (
    echo Could not find 1C:Designer with path %V8_TOOL%
    set ERROR_CODE=1
    goto finally
)
IF not defined IBCMD_TOOL set IBCMD_TOOL="%PROGRAMW6432%\1cv8\%V8_VERSION%\bin\ibcmd.exe"
IF "%V8_CONVERT_TOOL%" equ "ibcmd" IF not exist %IBCMD_TOOL% (
    echo Could not find ibcmd tool with path %IBCMD_TOOL%
    set ERROR_CODE=1
    goto finally
)

echo [INFO] Start conversion using "%V8_CONVERT_TOOL%"

set LOCAL_TEMP=%V8_TEMP%\%~n0
if not defined IBCMD_DATA set IBCMD_DATA=%V8_TEMP%\ibcmd_data
set IB_PATH=%LOCAL_TEMP%\tmp_db
set XML_PATH=%LOCAL_TEMP%\tmp_xml
set WS_PATH=%LOCAL_TEMP%\edt_ws

set ARG=%1
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_SRC_PATH=%ARG%
set ARG=%2
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_DST_PATH=%ARG%

IF not defined V8_SRC_PATH (
    echo [ERROR] Missed parameter 1 - "path to 1C configuration source (1C configuration file (*.cf), infobase or 1C:Designer XML files)"
    set ERROR_CODE=1
)
IF not defined V8_DST_PATH (
    echo [ERROR] Missed parameter 2 - "path to folder to save configuration files in 1C:EDT peoject format"
    set ERROR_CODE=1
)
IF %ERROR_CODE% neq 0 (
    echo ======
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - path to 1C configuration source ^(1C configuration file ^(*.cf^), infobase or 1C:Designer XML files^)
    echo     %%2 - path to folder to save configuration files in 1C:EDT project format
    echo.
    goto finally
)

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"
md "%LOCAL_TEMP%"
IF exist "%V8_DST_PATH%" IF "%V8_CONF_CLEAN_DST%" equ "1" (
    del /f /s /q "%V8_DST_PATH%\*.*" > nul
    rd /S /Q "%V8_DST_PATH%"
)
IF not exist "%V8_DST_PATH%" md "%V8_DST_PATH%"

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
    echo [INFO] Source type: Server infobase ^(!V8_IB_SERVER!\!V8_IB_NAME!^)
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
IF exist "%V8_SRC_PATH%\Configuration.xml" (
    echo [INFO] Source type: 1C:Designer XML files
    set XML_PATH=%V8_SRC_PATH%
    set V8_IB_CONNECTION=File="!IB_PATH!";
    goto export_xml
)

echo [ERROR] Error cheking type of configuration "%V8_SRC_PATH%"!
echo Infobase, configuration file ^(*.cf^) or 1C:Designer XML files expected.
set ERROR_CODE=1
goto finally

:export_cf

echo [INFO] Creating infobase "%IB_PATH%" from file "%V8_SRC_PATH%"...

IF not exist "%IB_PATH%" md "%IB_PATH%"

IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% CREATEINFOBASE %V8_IB_CONNECTION% /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!" /UseTemplate "%V8_SRC_PATH%"
) ELSE (
    IF defined V8_IB_SERVER (
        %IBCMD_TOOL% infobase create --data="%IBCMD_DATA%" --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_IB_SERVER% --db-name="%V8_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" --create-database --load="%V8_SRC_PATH%"
    ) ELSE (
        %IBCMD_TOOL% infobase create --data="%IBCMD_DATA%" --db-path="%IB_PATH%" --create-database --load="%V8_SRC_PATH%"
    )
)
IF not ERRORLEVEL 0 (
    set ERROR_CODE=%ERRORLEVEL%
    goto finally
)

:export_ib

echo [INFO] Export configuration from infobase "%IB_PATH%" to 1C:Designer XML format "%XML_PATH%"...

md "%XML_PATH%"

IF "%V8_CONVERT_TOOL%" equ "designer" (
    set V8_DESIGNER_LOG=%LOCAL_TEMP%\v8_designer_output.log
    %V8_TOOL% DESIGNER /IBConnectionString %V8_IB_CONNECTION% /N"%V8_IB_USER%" /P"%V8_IB_PWD%" /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!" /DumpConfigToFiles "%XML_PATH%" -force
    FOR /F "tokens=* delims=" %%i IN (!V8_DESIGNER_LOG!) DO IF "%%i" neq "" echo [WARN] %%i
) ELSE (
    set IBCMD_EXPORT_FLAGS=--force
    IF exist "%V8_DST_PATH%\Configuration.xml" IF exist "%V8_DST_PATH%\ConfigDumpInfo.xml" set IBCMD_EXPORT_FLAGS=!IBCMD_EXPORT_FLAGS! --sync
    IF defined V8_IB_SERVER (
        %IBCMD_TOOL% infobase config export --data="%IBCMD_DATA%" --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_IB_SERVER% --db-name="%V8_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%" !IBCMD_EXPORT_FLAGS! "%XML_PATH%"
    ) ELSE (
        %IBCMD_TOOL% infobase config export --data="%IBCMD_DATA%" --db-path="%IB_PATH%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%" !IBCMD_EXPORT_FLAGS! "%XML_PATH%"
    )
)
IF not ERRORLEVEL 0 (
    set ERROR_CODE=%ERRORLEVEL%
    goto finally
)

:export_xml

md "%WS_PATH%"

echo [INFO] Export configuration from "%XML_PATH%" to 1C:EDT format "%V8_DST_PATH%"...
IF not defined RING_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
        set RING_TOOL="%%i"
    )
)
IF not defined EDTCLI_TOOL (
    IF defined V8_EDT_VERSION (
        IF %V8_EDT_VERSION:~0,4% lss 2024 goto checktool
        set EDT_MASK="%PROGRAMW6432%\1C\1CE\components\1c-edt-%V8_EDT_VERSION%*"
    ) ELSE (
        set EDT_MASK="%PROGRAMW6432%\1C\1CE\components\1c-edt-*"
    )
    FOR /F "tokens=*" %%d IN ('"dir /B /S !EDT_MASK! | findstr /r /i ".*1c-edt-[0-9]*\.[0-9]*\.[0-9].*""') DO (
        IF exist "%%d\1cedtcli.exe" set EDTCLI_TOOL="%%d\1cedtcli.exe"
    )
)

:checktool

IF not defined RING_TOOL IF not defined EDTCLI_TOOL (
    echo [ERROR] Can't find "ring" or "edtcli" tool. Add path to "ring.bat" to "PATH" environment variable, or set "RING_TOOL" variable with full specified path to "ring.bat", or set "EDTCLI_TOOL" variable with full specified path to "1cedtcli.exe".
    set ERROR_CODE=1
    goto finally
)
IF defined EDTCLI_TOOL (
    echo [INFO] Start conversion using "edt cli"
    call %EDTCLI_TOOL% -data "%WS_PATH%" -command import --project "%V8_DST_PATH%" --configuration-files "%XML_PATH%" --version "%V8_VERSION%"
) ELSE (
    echo [INFO] Start conversion using "ring"
    call %RING_TOOL% edt@%V8_EDT_VERSION% workspace import --project "%V8_DST_PATH%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%" --version "%V8_VERSION%"
)
IF not ERRORLEVEL 0 (
    set ERROR_CODE=%ERRORLEVEL%
    goto finally
)

IF defined EDTCLI_TOOL (
    call %EDTCLI_TOOL% -data "%WS_PATH%" -command clean-up-source --project "%V8_DST_PATH%"
) ELSE (
    call %RING_TOOL% edt@%V8_EDT_VERSION% workspace clean-up-source --workspace-location "%WS_PATH%" --project "%V8_DST_PATH%"
)
set ERROR_CODE=%ERRORLEVEL%

:finally

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"

exit /b %ERROR_CODE%

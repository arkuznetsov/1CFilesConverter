@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

chcp 65001 > nul

echo START: %date% %time%

set RELATIVE_REPO_PATH=%~dp0..\..
set RELATIVE_SRC_PATH=src

FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%RELATIVE_REPO_PATH%" /M "%RELATIVE_SRC_PATH%" /C "cmd /c echo @path"`) DO set SRC_PATH=%%i
IF not defined SRC_PATH (
    echo [ERROR] Path to source files "%RELATIVE_REPO_PATH%\%RELATIVE_SRC_PATH%" not found
    exit /b 1
)
set SRC_PATH=%SRC_PATH:"=%
set REPO_PATH=%SRC_PATH%
FOR /L %%i IN (1, 1, 10) DO (
    set REPO_PATH=!REPO_PATH:~0,-1!
    IF "!REPO_PATH:~-1,1!" equ "\" (
        set REPO_PATH=!REPO_PATH:~0,-1!
        goto script
    )
)
:script

IF exist "%REPO_PATH%\.env" (
    FOR /F "usebackq tokens=*" %%a in ("%REPO_PATH%\.env") DO (
        FOR /F "tokens=1,2 delims==" %%b IN ("%%a") DO (
            set "%%b=%%c"
        )
    )
)

set FILE_NAME=%~n0
set V8_EXT_NAME=%FILE_NAME:~10%
IF not defined V8_EXT_NAME (
    echo [ERROR] Extension name is not defined ^(rename script to apply_ext_^<Extension name^>.cmd^)
    exit /b 1
) 

IF defined V8_IMPORT_TOOL set V8_CONVERT_TOOL=%V8_IMPORT_TOOL%

set V8_CONNECTION_STRING=/S%V8_DB_SRV_ADDR%\%V8_IB_NAME%
IF /i "%V8_CONVERT_TOOL%" equ "designer" set V8_CONNECTION_STRING=/S%V8_SRV_ADDR%\%V8_IB_NAME%

echo.
echo ======
echo Updating database extension "%EXT_NAME%"...
echo ======
IF "%V8_CONVERT_TOOL%" equ "designer" (
    set V8_IB_CONNECTION=Srvr="%V8_SRV_ADDR%";Ref="%V8_IB_NAME%";
    set V8_DESIGNER_LOG=%~dp0v8_designer_output.log
    %V8_TOOL% DESIGNER /IBConnectionString !V8_IB_CONNECTION! /N"%V8_IB_USER%" /P"%V8_IB_PWD%" /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!" /UpdateDBCfg -Dynamic+
    FOR /F "tokens=* delims=" %%i IN (!V8_DESIGNER_LOG!) DO IF "%%i" neq "" echo [WARN] %%i
) ELSE (
    %IBCMD_TOOL% infobase config apply --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_DB_SRV_ADDR% --db-name="%V8_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%" --extension="%EXT_NAME%" --dynamic=force --session-terminate=force --force
)

echo FINISH: %date% %time%

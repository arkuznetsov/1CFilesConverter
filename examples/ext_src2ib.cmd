@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

chcp 65001 > nul

echo START: %date% %time%

set ARG=%1
IF defined ARG set ARG=%ARG:"=%
set V8_UPDATE_DB=0
IF /i "%ARG%" equ "apply" set V8_UPDATE_DB=1

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
        FOR /F "tokens=1* delims==" %%b IN ("%%a") DO ( 
            set "%%b=%%c"
        )
    )
)

IF /i "%V8_SRC_TYPE%" equ "edt" (
    set RELATIVE_CF_PATH=main
) ELSE (
    set RELATIVE_CF_PATH=cf
    set RELATIVE_CFE_PATH=cfe
)

IF defined RELATIVE_CFE_PATH (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%SRC_PATH%" /M "%RELATIVE_CFE_PATH%" /C "cmd /c echo @path"`) DO (
        set EXT_PATH=%%i
        set EXT_PATH=!EXT_PATH:"=!
        echo [INFO] Found extensions root folder "!EXT_PATH!"
    )
) ELSE (
    set EXT_PATH=%SRC_PATH%
)
set FILE_NAME=%~n0
set EXT_NAME=%FILE_NAME:~11%
IF not defined V8_IB_NAME (
    echo [ERROR] Extension name is not defined ^(rename script to ext_src2ib_^<Extension name^>.cmd^)
    exit /b 1
) 

set "GIT_COMMAND=git rev-parse HEAD"
FOR /f "tokens=1 delims=" %%a in (' "!GIT_COMMAND!" ') do (
    set ACTUAL_COMMIT=%%a
    echo [INFO] Actual commit "!ACTUAL_COMMIT!"
)
IF defined V8_IMPORT_TOOL set V8_CONVERT_TOOL=%V8_IMPORT_TOOL%

set V8_CONNECTION_STRING=/S%V8_DB_SRV_ADDR%\%V8_IB_NAME%
IF /i "%V8_CONVERT_TOOL%" equ "designer" set V8_CONNECTION_STRING=/S%V8_SRV_ADDR%\%V8_IB_NAME%

set EXT_CHANGED=0
set SYNC_COMMIT=commit not found
IF exist "%EXT_PATH%\%EXT_NAME%\SYNC_COMMIT" (
    FOR /f "tokens=*" %%a in (%EXT_PATH%\%EXT_NAME%\SYNC_COMMIT) do (
        FOR /F "tokens=1,2 delims=:" %%b IN ("%%a") DO (
            IF "%%b" equ "%V8_IB_NAME%" (
                set SYNC_COMMIT=%%c
                set SYNC_COMMIT=!SYNC_COMMIT: =!
            )
        )
    )
    echo [INFO] Extension "!EXT_NAME!" last synchronized commit: "!SYNC_COMMIT!"
    IF "!SYNC_COMMIT!" equ "commit not found" (
        set EXT_CHANGED=1
    ) ELSE IF "!SYNC_COMMIT!" neq "%ACTUAL_COMMIT%" (
        set "GIT_COMMAND=git diff --name-only !SYNC_COMMIT! %ACTUAL_COMMIT% -- "%EXT_PATH%\!EXT_NAME!""
        FOR /f "tokens=1 delims=" %%a in (' "!GIT_COMMAND!" ') do (
            set EXT_CHANGED=1
        )
    )
    set "GIT_COMMAND=git status --short -- "%EXT_PATH%\!EXT_NAME!""
    FOR /f "tokens=1 delims=" %%a in (' "!GIT_COMMAND!" ') do (
        set EXT_CHANGED=1
    )
) ELSE (
    set EXT_CHANGED=1
)
IF "%EXT_CHANGED%" equ "1" (
    echo.
    echo ======
    echo Import extension "%EXT_NAME%"
    echo ======
    call %REPO_PATH%\tools\1CFilesConverter\scripts\ext2ib.cmd "%EXT_PATH%\%EXT_NAME%" "%V8_CONNECTION_STRING%" "%EXT_NAME%"
    IF ERRORLEVEL 0 echo %V8_IB_NAME%:%ACTUAL_COMMIT%> "%EXT_PATH%\%EXT_NAME%\SYNC_COMMIT"
) ELSE (
    echo [INFO] Extension "!EXT_NAME!" wasn't changed since last synchronized commit
)

IF "%EXT_CHANGED%" equ "1" IF "%V8_UPDATE_DB%" equ "1" (
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
)

echo FINISH: %date% %time%

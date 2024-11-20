@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

chcp 65001 > nul

echo START: %date% %time%

set ARG=%1
IF defined ARG set V8_BRANCH=%ARG:"=%
IF not defined V8_BRANCH set V8_BRANCH=local

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

set FILE_NAME=%~n0
set V8_IB_NAME=%FILE_NAME:~7%
IF not defined V8_IB_NAME (
    echo [ERROR] Infobase name is not defined ^(rename script to upd_ib_^<Infobase name^>.cmd^)
    exit /b 1
) 

IF exist "%REPO_PATH%\%V8_IB_NAME%.env" (
    FOR /F "usebackq tokens=*" %%a in ("%REPO_PATH%\%V8_IB_NAME%.env") DO (
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

FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%SRC_PATH%" /M "%RELATIVE_CF_PATH%" /C "cmd /c echo @path"`) DO (
    set CONF_PATH=%%i
    set CONF_PATH=!CONF_PATH:"=!
    echo [INFO] Found main configuration folder "!CONF_PATH!"
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

IF defined V8_IMPORT_TOOL set V8_CONVERT_TOOL=%V8_IMPORT_TOOL%
IF not "%V8_CONVERT_TOOL%" equ "designer" IF not "%V8_CONVERT_TOOL%" equ "ibcmd" set V8_CONVERT_TOOL=designer

set V8_CONNECTION_STRING="/S%V8_DB_SRV_ADDR%\%V8_IB_NAME%"
IF /i "%V8_CONVERT_TOOL%" equ "designer" set V8_CONNECTION_STRING="/S%V8_SRV_ADDR%\%V8_IB_NAME%"

IF not defined V8_TOOL set V8_TOOL="%PROGRAMW6432%\1cv8\%V8_VERSION%\bin\1cv8.exe"
IF "%V8_CONVERT_TOOL%" equ "designer" IF not exist %V8_TOOL% (
    echo [ERROR] Could not find 1C:Designer with path %V8_TOOL%
    set ERROR_CODE=1
    goto finally
)
IF not defined IBCMD_TOOL set IBCMD_TOOL="%PROGRAMW6432%\1cv8\%V8_VERSION%\bin\ibcmd.exe"
IF "%V8_CONVERT_TOOL%" equ "ibcmd" IF not exist %IBCMD_TOOL% (
    echo [ERROR] Could not find ibcmd tool with path %IBCMD_TOOL%
    set ERROR_CODE=1
    goto finally
)

echo [INFO] Pulling actual sources from %V8_BRANCH%
cd %REPO_PATH%
set "GIT_COMMAND=git rev-parse --abbrev-ref HEAD"
FOR /f "tokens=1 delims=" %%a in (' "!GIT_COMMAND!" ') do (
    set WORKING_BRANCH=%%a
)

IF /i "%V8_BRANCH%" neq "local" IF /i "%V8_BRANCH%" neq "current" git checkout %V8_BRANCH%
IF /i "%V8_BRANCH%" neq "local" git pull

set "GIT_COMMAND=git rev-parse HEAD"
FOR /f "tokens=1 delims=" %%a in (' "!GIT_COMMAND!" ') do (
    set ACTUAL_COMMIT=%%a
    echo [INFO] Actual commit "!ACTUAL_COMMIT!"
)

IF defined V8_EXTENSIONS (
    FOR %%j IN (%V8_EXTENSIONS%) DO echo [INFO] Found extension in environment settings: %%j
) ELSE (
    IF "%V8_EXT_LOOKUP%" equ "folder" (
        echo [INFO] Found extensions root folder "%EXT_PATH%"
        FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%EXT_PATH%" /C "cmd /c echo @path"`) DO (
            set EXT_NAME=%%i
            set EXT_NAME=!EXT_NAME:%EXT_PATH%\=!
            set EXT_NAME=!EXT_NAME:"=!
            echo [INFO] Found extension folder "!EXT_NAME!"
            IF not !EXT_NAME! equ %RELATIVE_CF_PATH% (
                IF defined V8_EXTENSIONS (
                    set V8_EXTENSIONS=!V8_EXTENSIONS! !EXT_NAME!
                ) ELSE (
                    set V8_EXTENSIONS=!EXT_NAME!
                )
            )
        )
        goto process_ext
    )
    IF "%V8_CONVERT_TOOL%" equ "designer" (
        set EXT_LIST_FILE=%~dp0v8_ext_list.txt
        %V8_TOOL% DESIGNER /IBConnectionString !V8_IB_CONNECTION! /N"%V8_IB_USER%" /P"%V8_IB_PWD%" /DisableStartupDialogs  /DisableStartupMessages /Out "!EXT_LIST_FILE!" /DumpDBCfgList -AllExtensions
        FOR /F "tokens=* delims=" %%i IN (!EXT_LIST_FILE!) DO (
            set EXT_NAME=%%i
            set EXT_NAME=!EXT_NAME: =!
            set EXT_NAME=!EXT_NAME:"=!
            IF /i "!EXT_NAME!" equ "%%i" (
                echo [INFO] Found extension in infobase: !EXT_NAME!
                IF defined V8_EXTENSIONS (
                    set V8_EXTENSIONS=!V8_EXTENSIONS! !EXT_NAME!
                ) ELSE (
                    set V8_EXTENSIONS=!EXT_NAME!
                )
            )
        )
        del /f /s /q "!EXT_LIST_FILE!" > nul
        goto process_ext
    ) ELSE (
        set "COMMAND_EXT_LIST=%IBCMD_TOOL% infobase config extension list --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_DB_SRV_ADDR% --db-name="%V8_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%""
        FOR /f "tokens=1,2 delims==:" %%i IN (' "!COMMAND_EXT_LIST!" ') DO (
            set PARAM_NAME=%%i
            set PARAM_NAME=!PARAM_NAME: =!
            IF "!PARAM_NAME!" equ "name" (
                set EXT_NAME=%%j
                set EXT_NAME=!EXT_NAME: =!
                set EXT_NAME=!EXT_NAME:"=!
                echo [INFO] Found extension in infobase: !EXT_NAME!
                IF defined V8_EXTENSIONS (
                    set V8_EXTENSIONS=!V8_EXTENSIONS! !EXT_NAME!
                ) ELSE (
                    set V8_EXTENSIONS=!EXT_NAME!
                )
            )
        )
        goto process_ext
    )
)

set V8_CONNECTION_STRING=/S%V8_DB_SRV_ADDR%\%V8_IB_NAME%
IF /i "%V8_CONVERT_TOOL%" equ "designer" set V8_CONNECTION_STRING=/S%V8_SRV_ADDR%\%V8_IB_NAME%

set CONF_CHANGED=0
set SYNC_COMMIT=commit not found
IF exist "%CONF_PATH%\SYNC_COMMIT" (
    FOR /f "tokens=*" %%a in (%CONF_PATH%\SYNC_COMMIT) do (
        FOR /F "tokens=1,2 delims=:" %%b IN ("%%a") DO (
            IF "%%b" equ "%V8_IB_NAME%" (
                set SYNC_COMMIT=%%c
                set SYNC_COMMIT=!SYNC_COMMIT: =!
            )
        )
    )
    echo [INFO] Main configuration last synchronized commit "!SYNC_COMMIT!"
    IF "!SYNC_COMMIT!" equ "commit not found" (
        set CONF_CHANGED=1
    ) ELSE IF "!SYNC_COMMIT!" neq "%ACTUAL_COMMIT%" (
        set "GIT_COMMAND=git diff --name-only !SYNC_COMMIT! %ACTUAL_COMMIT% -- "%CONF_PATH%""
        FOR /f "tokens=1 delims=" %%a in (' "!GIT_COMMAND!" ') do (
            set CONF_CHANGED=1
        )
    )
    set "GIT_COMMAND=git status --short -- "%CONF_PATH%""
    FOR /f "tokens=1 delims=" %%a in (' "!GIT_COMMAND!" ') do (
        set CONF_CHANGED=1
    )
) ELSE (
    set CONF_CHANGED=1
)
IF "%CONF_CHANGED%" equ "1" (
    echo.
    echo ======
    echo Import main configuration
    echo ======
    call %REPO_PATH%\tools\1CFilesConverter\scripts\conf2ib.cmd "%CONF_PATH%" "%V8_CONNECTION_STRING%"
    IF ERRORLEVEL 0 echo %V8_IB_NAME%:%ACTUAL_COMMIT%> "%CONF_PATH%\SYNC_COMMIT"
) ELSE (
    echo [INFO] Main configuration wasn't changed since last synchronized commit
)

FOR %%j IN (%V8_EXTENSIONS%) DO (
    set EXT_NAME=%%j
    set EXT_CHANGED=0
    set SYNC_COMMIT=commit not found
    IF exist "%EXT_PATH%\!EXT_NAME!\SYNC_COMMIT" (
        FOR /f "tokens=*" %%a in (%EXT_PATH%\!EXT_NAME!\SYNC_COMMIT) do (
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
    IF "!EXT_CHANGED!" equ "1" (
        echo.
        echo ======
        echo Import extension "!EXT_NAME!"
        echo ======
        call %REPO_PATH%\tools\1CFilesConverter\scripts\ext2ib.cmd "%EXT_PATH%\!EXT_NAME!" "%V8_CONNECTION_STRING%" "!EXT_NAME!"
        IF ERRORLEVEL 0 echo %V8_IB_NAME%:%ACTUAL_COMMIT%> "%EXT_PATH%\!EXT_NAME!\SYNC_COMMIT"
        IF not defined EXT_UPDATE_DB (
            set EXT_UPDATE_DB=!EXT_NAME!
        ) ELSE (
            set EXT_UPDATE_DB=!EXT_UPDATE_DB! !EXT_NAME!
        )
    ) ELSE (
        echo [INFO] Extension "!EXT_NAME!" wasn't changed since last synchronized commit
    )
)

set "GIT_COMMAND=git rev-parse --abbrev-ref HEAD"
FOR /f "tokens=1 delims=" %%a in (' "!GIT_COMMAND!" ') do (
    set CURRENT_BRANCH=%%a
)

IF "%WORKING_BRANCH%" neq "%CURRENT_BRANCH%" git checkout %WORKING_BRANCH%

IF "%CONF_CHANGED%" equ "1" (
    echo.
    echo ======
    echo Updating database main configuration
    echo ======
    IF "%V8_CONVERT_TOOL%" equ "designer" (
        set V8_IB_CONNECTION=Srvr="%V8_SRV_ADDR%";Ref="%V8_IB_NAME%";
        set V8_DESIGNER_LOG=%~dp0v8_designer_output.log
        %V8_TOOL% DESIGNER /IBConnectionString !V8_IB_CONNECTION! /N"%V8_IB_USER%" /P"%V8_IB_PWD%" /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!" /UpdateDBCfg -Dynamic+
        FOR /F "tokens=* delims=" %%i IN (!V8_DESIGNER_LOG!) DO IF "%%i" neq "" echo [WARN] %%i
    ) ELSE (
        %IBCMD_TOOL% infobase config apply --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_DB_SRV_ADDR% --db-name="%V8_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%" --dynamic=force --session-terminate=force --force
    )
)

FOR %%j IN (%EXT_UPDATE_DB%) DO (
    set EXT_NAME=%%j
    echo.
    echo ======
    echo Updating database extension "!EXT_NAME!"...
    echo ======
    IF "%V8_CONVERT_TOOL%" equ "designer" (
        set V8_IB_CONNECTION=Srvr="%V8_SRV_ADDR%";Ref="%V8_IB_NAME%";
        set V8_DESIGNER_LOG=%~dp0v8_designer_output.log
        %V8_TOOL% DESIGNER /IBConnectionString !V8_IB_CONNECTION! /N"%V8_IB_USER%" /P"%V8_IB_PWD%" /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!" /UpdateDBCfg -Dynamic+ -Extension "!EXT_NAME!"
        FOR /F "tokens=* delims=" %%i IN (!V8_DESIGNER_LOG!) DO IF "%%i" neq "" echo [WARN] %%i
    ) ELSE (
        %IBCMD_TOOL% infobase config apply --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_DB_SRV_ADDR% --db-name="%V8_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" --user="%V8_IB_USER%" --password="%V8_IB_PWD%" --extension="!EXT_NAME!" --dynamic=force --session-terminate=force --force
    )
)
:finally

echo FINISH: %date% %time%

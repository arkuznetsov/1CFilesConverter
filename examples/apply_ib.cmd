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
set V8_IB_NAME=%FILE_NAME:~9%
IF not defined V8_IB_NAME (
    echo [ERROR] Infobase name is not defined ^(rename script to apply_ib_^<Infobase name^>.cmd^)
    exit /b 1
) 

IF exist "%REPO_PATH%\%V8_IB_NAME%.env" (
    FOR /F "usebackq tokens=*" %%a in ("%REPO_PATH%\%V8_IB_NAME%.env") DO (
        FOR /F "tokens=1,2 delims==" %%b IN ("%%a") DO (
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

IF defined V8_IMPORT_TOOL set V8_CONVERT_TOOL=%V8_IMPORT_TOOL%

set V8_CONNECTION_STRING="/S%V8_DB_SRV_ADDR%\%V8_IB_NAME%"
IF /i "%V8_CONVERT_TOOL%" equ "designer" set V8_CONNECTION_STRING="/S%V8_SRV_ADDR%\%V8_IB_NAME%"

IF not "%V8_CONVERT_TOOL%" equ "designer" IF not "%V8_CONVERT_TOOL%" equ "ibcmd" set V8_CONVERT_TOOL=designer
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

set V8_CONNECTION_STRING=/S%V8_DB_SRV_ADDR%\%V8_IB_NAME%
IF /i "%V8_CONVERT_TOOL%" equ "designer" set V8_CONNECTION_STRING=/S%V8_SRV_ADDR%\%V8_IB_NAME%

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

IF defined RELATIVE_CFE_PATH (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%SRC_PATH%" /M "%RELATIVE_CFE_PATH%" /C "cmd /c echo @path"`) DO (
        set EXT_PATH=%%i
        set EXT_PATH=!EXT_PATH:"=!
    )
) ELSE (
    set EXT_PATH=%SRC_PATH%
)

IF defined V8_EXTENSIONS (
    FOR %%j IN (%V8_EXTENSIONS%) DO echo [INFO] Found extension: %%j
) ELSE (
    IF "%V8_EXT_LOOKUP%" equ "folder" (
        echo [INFO] Found extensions root folder "%EXT_PATH%"
        FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%EXT_PATH%" /C "cmd /c echo @path"`) DO (
            set EXT_NAME=%%i
            set EXT_NAME=!EXT_NAME:%EXT_PATH%\=!
            set EXT_NAME=!EXT_NAME:"=!
            echo [INFO] Found extension "!EXT_NAME!"
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
        echo [INFO] V8_CONVERT_TOOL: !V8_CONVERT_TOOL!
        echo [INFO] V8_IB_CONNECTION: !V8_IB_CONNECTION!
        FOR /F "tokens=* delims=" %%i IN (!EXT_LIST_FILE!) DO (
            set EXT_NAME=%%i
            set EXT_NAME=!EXT_NAME: =!
            set EXT_NAME=!EXT_NAME:"=!
            IF /i "!EXT_NAME!" equ "%%i" (
                echo [INFO] Found extension: !EXT_NAME!
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
                echo [INFO] Found extension: !EXT_NAME!
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

FOR %%j IN (%V8_EXTENSIONS%) DO (
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

@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

chcp 65001 > nul

set ARG=%1
IF defined ARG set V8_CONF_TO_RESET=%ARG:"=%

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

FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%SRC_PATH%" /M "%RELATIVE_CF_PATH%" /C "cmd /c echo @path"`) DO (
    set CONF_PATH=%%i
    set CONF_PATH=!CONF_PATH:"=!
)
IF /i "%V8_CONF_TO_RESET%" equ "main" IF not defined CONF_PATH (
    echo [ERROR] Path to main configuration source files "%CONF_PATH%" not found
    exit /b 1
)

FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%SRC_PATH%" /M "%RELATIVE_CFE_PATH%" /C "cmd /c echo @path"`) DO (
    set EXT_PATH=%%i
    set EXT_PATH=!EXT_PATH:"=!
)
IF defined V8_CONF_TO_RESET IF not defined EXT_PATH (
    echo [ERROR] Path to extensions source files "%EXT_PATH%" not found
    exit /b 1
)
IF defined V8_CONF_TO_RESET IF /i "%V8_CONF_TO_RESET%" neq "main" IF /i "%V8_CONF_TO_RESET%" neq "ext" IF not exist "%EXT_PATH%\%V8_CONF_TO_RESET%" (
    echo [ERROR] Path to extension "%V8_CONF_TO_RESET%" source files "%EXT_PATH%\%V8_CONF_TO_RESET%" not found
    exit /b 1
)

IF defined V8_CONF_TO_RESET (
    IF /i "%V8_CONF_TO_RESET%" equ "main" del /f /s /q "%CONF_PATH%\SYNC_COMMIT"
    IF /i "%V8_CONF_TO_RESET%" equ "ext" del /f /s /q "%EXT_PATH%\SYNC_COMMIT"
    IF /i "%V8_CONF_TO_RESET%" neq "main" IF /i "%V8_CONF_TO_RESET%" neq "ext" del /f /s /q "%EXT_PATH%\%V8_CONF_TO_RESET%\SYNC_COMMIT"
) ELSE (
    del /f /s /q "%SRC_PATH%\SYNC_COMMIT"
)

@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

echo START: %date% %time%

chcp 65001 > nul

set V8_COMMIT_AUTHOR=1c
set V8_COMMIT_EMAIL=1c@1c.ru
set V8_COMMIT_MESSAGE=Обновлена конфигурация поставщика до версии

set V8_COMMIT_DATE=%date%
echo V8_COMMIT_DATE: %V8_COMMIT_DATE%
set V8_COMMIT_YEAR=%V8_COMMIT_DATE:~6,4%
set V8_COMMIT_MONTH=%V8_COMMIT_DATE:~3,2%
set V8_COMMIT_DAY=%V8_COMMIT_DATE:~0,2%
set V8_COMMIT_TIME=%time%
echo V8_COMMIT_TIME: %V8_COMMIT_TIME%
set V8_COMMIT_HOUR=%V8_COMMIT_TIME:~0,2%
set V8_COMMIT_MIN=%V8_COMMIT_TIME:~3,2%
set V8_COMMIT_SEC=%V8_COMMIT_TIME:~6,2%
set V8_COMMIT_DATE=%V8_COMMIT_YEAR%-%V8_COMMIT_MONTH%-%V8_COMMIT_DAY% %V8_COMMIT_HOUR%:%V8_COMMIT_MIN%:%V8_COMMIT_SEC%

set V8_VERSION=8.3.23.2040
set V8_EXPORT_TOOL=ibcmd
set V8_CONF_XML_CLEAN_DST=1
set V8_SKIP_ENV=1

set V8_SUPPORT_INFO={6,0,0,0,1,0}

set V8_VENDOR_BRANCH=base1c
set V8_UPDATE_BRANCH=develop

set RELATIVE_REPO_PATH=%~dp0..\..
set RELATIVE_SRC_PATH=src
set RELATIVE_SRC_CF_PATH=cf
set RELATIVE_SRC_CFE_PATH=cfe

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

FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%RELATIVE_REPO_PATH%\%V8_VENDOR_BRANCH%" /M "1cv8.cf" /C "cmd /c echo @path"`) DO set V8_VENDOR_CF=%%i
set V8_VENDOR_CF=%V8_VENDOR_CF:"=%

FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%SRC_PATH%" /M "%RELATIVE_SRC_CF_PATH%" /C "cmd /c echo @path"`) DO set CONF_PATH=%%i
set CONF_PATH=%CONF_PATH:"=%

cd %REPO_PATH%
git checkout %V8_VENDOR_BRANCH%
git pull

IF defined V8_EXPORT_TOOL set V8_CONVERT_TOOL=%V8_EXPORT_TOOL%

call %REPO_PATH%\tools\1CFilesConverter\scripts\conf2xml.cmd "%V8_VENDOR_CF%" "%CONF_PATH%"

IF exist "%CONF_PATH%\ConfigDumpInfo.xml" del /Q /F "%CONF_PATH%\ConfigDumpInfo.xml"

IF exist "%CONF_PATH%\Ext\ParentConfigurations.bin" echo %V8_SUPPORT_INFO% > "%CONF_PATH%\Ext\ParentConfigurations.bin"

for /f "tokens=*" %%i in ('findstr /r /i "version.*[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*.*/version" "%CONF_PATH%\Configuration.xml"') do (
    set V8_BASE1C_VERSION=%%i
    set V8_BASE1C_VERSION=!V8_BASE1C_VERSION:^<Version^>=!
    set V8_BASE1C_VERSION=!V8_BASE1C_VERSION:^</Version^>=!
)

git add %CONF_PATH%

call commit.cmd "%V8_COMMIT_AUTHOR%" "%V8_COMMIT_EMAIL%" "%V8_COMMIT_DATE%" "%V8_COMMIT_MESSAGE% %V8_BASE1C_VERSION%"

git checkout %V8_UPDATE_BRANCH%

git merge --no-commit %V8_VENDOR_BRANCH%

echo FINISH: %date% %time%

@ECHO off

SETLOCAL ENABLEDELAYEDEXPANSION

chcp 65001 > nul

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
        FOR /F "tokens=1,2 delims==" %%b IN ("%%a") DO (
            set "%%b=%%c"
        )
    )
)

SET QUERY="RESTORE DATABASE [%V8_IB_NAME%] FROM  DISK = N'D:\SQL.Template\%V8_IB_TEMPLATE%.bak' WITH  FILE = 1,  MOVE N'Temlate_ERP_2_5_12' TO N'D:\SQL.Data\%V8_IB_NAME%.mdf', MOVE N'Temlate_ERP_2_5_12_log' TO N'D:\SQL.Log\%V8_IB_NAME%_log.ldf',  NOUNLOAD,  REPLACE,  STATS = 5"

SET V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"

echo START: %date% %time%

ECHO "Create database %V8_IB_NAME% "
sqlcmd -S %V8_DB_SRV_ADDR% -U %V8_DB_SRV_USR%  -P %V8_DB_SRV_PWD% -d master -Q %QUERY%

timeout 10

ECHO "[INFO] CREATE INFOBASE ON %V8_SRV_ADDR%:%V8_SRV_CLUSTER_PORT% WITH NAME %V8_IB_NAME%"
%V8_TOOL% CREATEINFOBASE Srvr="%V8_SRV_ADDR%:%V8_SRV_CLUSTER_PORT%";Ref="%V8_IB_NAME%";DBMS="mssqlserver";DBSrvr="%V8_DB_SRV_ADDR%";DB="%V8_IB_NAME%";DBUID="%V8_DB_SRV_USR%";DBPwd="%V8_DB_SRV_PWD%";LicDstr="Y";CrSQLDB="N";SchJobDn="Y";
ECHO "INFOBASE CREATED."

echo FINISHED: %date% %time%

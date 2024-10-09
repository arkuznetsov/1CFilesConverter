@ECHO OFF

set TEST_NAME="Conf XML -> load to server infobase (ibcmd) with designer running"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\Catalogs\Контрагенты.xml
set V8_PATH=%PROGRAMW6432%\1cv8\%V8_VERSION%\bin
set RAC_TOOL="%V8_PATH%\rac.exe"
set V8_CONVERT_TOOL=ibcmd

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

SETLOCAL ENABLEDELAYEDEXPANSION

set TMP_IB_NAME=TMP_IB_%~n0
set TMP_IB_NAME=%TMP_IB_NAME: =_%

echo [INFO] Starting RAS service

set "tasks_ras=tasklist /fi "imagename eq ras.exe" /fo "list" | findstr "PID""
for /f "tokens=2 delims==:" %%i in (' "%tasks_ras%" ') do (
   if not defined pids_ras (
      set pids_ras=%%i
   ) else (
      set pids_ras=!pids_ras!,%%i
   )
)
set pids_ras=%pids_ras: =%

start /D "%V8_PATH%" ras.exe cluster --port=%V8_RAS_PORT% %V8_SRV_ADDR%:%V8_SRV_AGENT_PORT%

echo [INFO] Looking for 1C cluster

set "command_rac=%RAC_TOOL% localhost:%V8_RAS_PORT% cluster list"
for /f "tokens=1,2 delims==:" %%i in (' "%command_rac%" ') do (
   set param_name=%%i
   set param_name=!param_name: =!
   if "!param_name!" equ "cluster" (
      set cluster_uuid=%%j
      set cluster_uuid=!cluster_uuid: =!
      set cluster_uuid=!cluster_uuid:"=!
      echo [INFO] Cluster UUID: !cluster_uuid!
      goto create_ib
   )
)
:create_ib

echo [INFO] Creating temporary infobase "%V8_SRV_ADDR%\%TMP_IB_NAME%"

%RAC_TOOL% ^
localhost:%V8_RAS_PORT% ^
infobase create ^
--cluster=%cluster_uuid% ^
--create-database ^
--name="%TMP_IB_NAME%" ^
--dbms="%V8_DB_SRV_DBMS%" ^
--db-server="%V8_DB_SRV_ADDR%" ^
--db-name="%TMP_IB_NAME%" ^
--db-user="%V8_DB_SRV_USR%" ^
--db-pwd="%V8_DB_SRV_PWD%" ^
--locale=ru_RU ^
--descr="Temp infobase for 1C files converter tests" ^
--date-offset=2000 ^
--scheduled-jobs-deny=on ^
--license-distribution=allow

echo [INFO] Start designer with infobase "%V8_SRV_ADDR%\%TMP_IB_NAME%"

set "tasks_1c=tasklist /fi "imagename eq 1cv8.exe" /fo "list" | findstr "PID""
for /f "tokens=2 delims==:" %%i in (' "%tasks_1c%" ') do (
   if not defined pids_1c (
      set pids_1c=%%i
   ) else (
      set pids_1c=!pids_1c!,%%i
   )
)
set pids_1c=%pids_1c: =%

start /D "%V8_PATH%" 1cv8.exe DESIGNER /IBConnectionString Srvr="%V8_SRV_ADDR%";Ref="%TMP_IB_NAME%"; /DisableStartupDialogs
timeout /t 5 /nobreak

call %SCRIPTS_PATH%\conf2ib.cmd "%TEST_XML_CF%" "/S%V8_DB_SRV_ADDR%\%TMP_IB_NAME%"

call %SCRIPTS_PATH%\conf2xml.cmd "/S%V8_DB_SRV_ADDR%\%TMP_IB_NAME%" "%TEST_OUT_PATH%"

echo [INFO] Killing designer for infobase "%V8_SRV_ADDR%\%TMP_IB_NAME%"

for /f "tokens=2 delims==:" %%i in (' "%tasks_1c%" ') do (
   set cur_1c_pid=%%i
   set cur_1c_pid=!cur_1c_pid: =!
   set cur_1c_pid_isnew=1
   for %%t in (%pids_1c%) do (
       if "!cur_1c_pid!" equ "%%t" set cur_1c_pid_isnew=0
   )
   if "!cur_1c_pid_isnew!" equ "1" taskkill /PID !cur_1c_pid! /T /F
)

echo [INFO] Dropping temporary database "%V8_DB_SRV_ADDR%\%TMP_IB_NAME%"

sqlcmd -S "%V8_DB_SRV_ADDR%" -U "%V8_DB_SRV_USR%" -P "%V8_DB_SRV_PWD%" -Q "USE [master]; ALTER DATABASE [%TMP_IB_NAME%] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [%TMP_IB_NAME%]" -b -y 0

echo [INFO] Looking for temporary infobase "%V8_SRV_ADDR%\%TMP_IB_NAME%"

set "command_rac=%RAC_TOOL% localhost:%V8_RAS_PORT% infobase summary list --cluster=%cluster_uuid%"
for /f "tokens=1,2 delims==:" %%i in (' "%command_rac%" ') do (
   set param_name=%%i
   set param_name=!param_name: =!
   set param_value=%%j
   set param_value=!param_value: =!
   set param_value=!param_value:"=!
   if "!param_name!" equ "infobase" set infobase_uuid=!param_value!
   if "!param_name!" equ "name" if /i "!param_value!" equ "%TMP_IB_NAME%" (
      echo [INFO] Found infobase "%TMP_IB_NAME%" UUID "!infobase_uuid!"
      goto drop_ib
   )
)

:drop_ib

echo [INFO] Dropping temporary infobase "%V8_SRV_ADDR%\%TMP_IB_NAME%"

%RAC_TOOL% ^
localhost:%V8_RAS_PORT% ^
infobase drop ^
--cluster=%cluster_uuid% ^
--infobase=%infobase_uuid% ^

echo [INFO] Killing RAS service

for /f "tokens=2 delims==:" %%i in (' "%tasks_ras%" ') do (
   set cur_ras_pid=%%i
   set cur_ras_pid=!cur_ras_pid: =!
   set cur_ras_pid_isnew=1
   for %%t in (%pids_ras%) do (
       if "!cur_ras_pid!" equ "%%t" set cur_ras_pid_isnew=0
   )
   if "!cur_ras_pid_isnew!" equ "1" taskkill /PID !cur_ras_pid! /T /F
)

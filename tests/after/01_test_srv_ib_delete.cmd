@ECHO OFF

set TEST_NAME="Delete test server infobase..."
set TEST_OUT_PATH=%TEST_IB%
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=
set V8_PATH=C:\Program Files\1cv8\%V8_VERSION%\bin
set RAC_TOOL="%V8_PATH%\rac.exe"

echo ===
echo Clear %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

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

echo [INFO] Dropping temporary database "%V8_DB_SRV_ADDR%\%V8_IB_NAME%"

sqlcmd -S "%V8_DB_SRV_ADDR%" -U "%V8_DB_SRV_USR%" -P "%V8_DB_SRV_PWD%" -Q "USE [master]; ALTER DATABASE [%V8_IB_NAME%] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [%V8_IB_NAME%]" -b -y 0

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
      goto find_ib
   )
)
:find_ib

echo [INFO] Looking for temporary infobase "%V8_SRV_ADDR%\%V8_IB_NAME%"

set "command_rac=%RAC_TOOL% localhost:%V8_RAS_PORT% infobase summary list --cluster=%cluster_uuid%"
for /f "tokens=1,2 delims==:" %%i in (' "%command_rac%" ') do (
   set param_name=%%i
   set param_name=!param_name: =!
   set param_value=%%j
   set param_value=!param_value: =!
   set param_value=!param_value:"=!
   if "!param_name!" equ "infobase" set infobase_uuid=!param_value!
   if "!param_name!" equ "name" if /i "!param_value!" equ "%V8_IB_NAME%" (
      echo [INFO] Found infobase "%V8_IB_NAME%" UUID "!infobase_uuid!"
      goto drop_ib
   )
)

:drop_ib

echo [INFO] Dropping temporary infobase "%V8_SRV_ADDR%\%V8_IB_NAME%"

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

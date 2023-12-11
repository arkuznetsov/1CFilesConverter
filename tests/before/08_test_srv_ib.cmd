@ECHO OFF

set TEST_NAME="Prepare test server infobase..."
set TEST_OUT_PATH=%TEST_IB%
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=
set V8_PATH=C:\Program Files\1cv8\%V8_VERSION%\bin
set IBCMD_TOOL="%V8_PATH%\ibcmd.exe"
set RAC_TOOL="%V8_PATH%\rac.exe"

echo ===
echo Prepare %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

echo [INFO] Starting 1C:Enterprise Server agent

set "tasks_ragent=tasklist /fi "imagename eq ragent.exe" /fo "list" | findstr "PID""
for /f "tokens=2 delims==:" %%i in (' "%tasks_ragent%" ') do (
   if not defined pids_ragent (
      set pids_ragent=%%i
   ) else (
      set pids_ragent=!pids_ragent!,%%i
   )
)
set pids_ragent=%pids_ragent: =%

start /D "%V8_PATH%" ragent.exe -agent -regport %V8_SRV_REG_PORT% -port %V8_SRV_AGENT_PORT% -range %V8_SRV_PORT_RANGE% -d "%V8_TEMP%\srvinfo%V8_SRV_REG_PORT%"

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

echo [INFO] Creating temporary infobase "%V8_SRV_ADDR%:%V8_SRV_REG_PORT%\%V8_IB_NAME%"

%RAC_TOOL% ^
localhost:%V8_RAS_PORT% ^
infobase create ^
--cluster=%cluster_uuid% ^
--create-database ^
--name="%V8_IB_NAME%" ^
--dbms="%V8_DB_SRV_DBMS%" ^
--db-server="%V8_DB_SRV_ADDR%" ^
--db-name="%V8_IB_NAME%" ^
--db-user="%V8_DB_SRV_USR%" ^
--db-pwd="%V8_DB_SRV_PWD%" ^
--locale=ru_RU ^
--descr="Temp infobase for 1C files converter tests" ^
--date-offset=2000 ^
--scheduled-jobs-deny=on ^
--license-distribution=allow

echo [INFO] Loading config "%TEST_BINARY%\1cv8.cf" to database "%V8_DB_SRV_ADDR%\%V8_IB_NAME%"

%IBCMD_TOOL% infobase config load --dbms=%V8_DB_SRV_DBMS% --db-server=%V8_DB_SRV_ADDR% --db-name="%V8_IB_NAME%" --db-user="%V8_DB_SRV_USR%" --db-pwd="%V8_DB_SRV_PWD%" --force "%TEST_BINARY%\1cv8.cf"

@ECHO OFF

set TEST_NAME="Conf srerver infobase -> XML (ibcmd) with designer running"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\Configuration.xml
set V8_PATH=C:\Program Files\1cv8\%V8_VERSION%\bin
set V8_CONVERT_TOOL=ibcmd

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

SETLOCAL ENABLEDELAYEDEXPANSION

set "tasks_1c=tasklist /fi "imagename eq 1cv8.exe" /fo "list" | findstr "PID""
for /f "tokens=2 delims==:" %%i in (' "%tasks_1c%" ') do (
   if not defined pids_1c (
      set pids_1c=%%i
   ) else (
      set pids_1c=!pids_1c!,%%i
   )
)
set pids_1c=%pids_1c: =%

start /D "%V8_PATH%" 1cv8.exe DESIGNER /IBConnectionString Srvr="%V8_SRV_ADDR%";Ref="%V8_IB_NAME%"; /DisableStartupDialogs
timeout /T 5

call %SCRIPTS_PATH%\conf2xml.cmd "/S%V8_SRV_ADDR%\%V8_IB_NAME%" "%TEST_OUT_PATH%"

for /f "tokens=2 delims==:" %%i in (' "%tasks_1c%" ') do (
   set cur_1c_pid=%%i
   set cur_1c_pid=!cur_1c_pid: =!
   set cur_1c_pid_isnew=1
   for %%t in (%pids_1c%) do (
       if "!cur_1c_pid!" equ "%%t" set cur_1c_pid_isnew=0
   )
   if "!cur_1c_pid_isnew!" equ "1" taskkill /PID !cur_1c_pid! /T /F
)

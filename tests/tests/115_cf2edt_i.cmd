@ECHO OFF

set TEST_NAME="CF -> EDT (ibcmd)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_CHECK_PATH=%TEST_OUT_PATH%\src\Configuration\Configuration.mdo

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\cf2edt.cmd "%TEST_BINARY%\1cv8.cf" "%TEST_OUT_PATH%" ibcmd

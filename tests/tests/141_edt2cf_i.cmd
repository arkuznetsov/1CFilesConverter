@ECHO OFF

set TEST_NAME="Conf EDT -> CF (ibcmd)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0\1cv8.cf
set TEST_CHECK_PATH=%TEST_OUT_PATH%
set V8_CONVERT_TOOL=ibcmd

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\conf2cf.cmd "%TEST_EDT_CF%" "%TEST_OUT_PATH%"

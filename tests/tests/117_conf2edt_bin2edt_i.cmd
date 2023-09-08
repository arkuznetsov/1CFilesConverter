@ECHO OFF

set TEST_NAME="Conf CF -> EDT (ibcmd)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\src\Configuration\Configuration.mdo
set V8_CONVERT_TOOL=ibcmd

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\conf2edt.cmd "%TEST_BINARY%\1cv8.cf" "%TEST_OUT_PATH%"

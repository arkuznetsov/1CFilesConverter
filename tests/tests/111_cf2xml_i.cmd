@ECHO OFF

set TEST_NAME="Conf CF -> XML (ibcmd)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_CHECK_PATH=%TEST_OUT_PATH%\Configuration.xml

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\conf2xml.cmd "%TEST_BINARY%\1cv8.cf" "%TEST_OUT_PATH%" ibcmd

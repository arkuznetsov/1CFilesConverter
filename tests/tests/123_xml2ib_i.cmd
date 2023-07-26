@ECHO OFF

set TEST_NAME="Conf XML -> infobase (ibcmd)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_CHECK_PATH=%TEST_OUT_PATH%\1cv8.1cd
set V8_CONVERT_TOOL=ibcmd

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\conf2ib.cmd "%TEST_XML_CF%" "%TEST_OUT_PATH%"

@ECHO OFF

set TEST_NAME="Conf server infobase -> XML (ibcmd)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\Configuration.xml
set V8_CONVERT_TOOL=ibcmd

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\conf2xml.cmd "/S%V8_SRV_ADDR%\%V8_IB_NAME%" "%TEST_OUT_PATH%"

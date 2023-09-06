@ECHO OFF

set TEST_NAME="Ext CFE -> XML (ibcmd)"
set TEST_EXT_NAME=Расширение1
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\Configuration.xml
set V8_CONVERT_TOOL=ibcmd

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
set V8_BASE_CONFIG=%TEST_BINARY%\1cv8.cf
call %SCRIPTS_PATH%\ext2xml.cmd "%TEST_BINARY%\%TEST_EXT_NAME%.cfe" "%TEST_OUT_PATH%" "%TEST_EXT_NAME%"

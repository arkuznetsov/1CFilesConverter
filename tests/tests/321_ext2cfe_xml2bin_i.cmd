@ECHO OFF

set TEST_NAME="Ext XML -> CFE (ibcmd)"
set TEST_EXT_NAME=Расширение1
set TEST_OUT_PATH=%OUT_PATH%\%~n0\%TEST_EXT_NAME%.cfe
set TEST_CHECK_PATH=%TEST_OUT_PATH%
set V8_CONVERT_TOOL=ibcmd

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\ext2cfe.cmd "%TEST_XML_EXT%\%TEST_EXT_NAME%" "%TEST_OUT_PATH%" "%TEST_EXT_NAME%" "%TEST_BINARY%\1cv8.cf"
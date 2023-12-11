@ECHO OFF

set TEST_NAME="Ext EDT -> create file infobase (ibcmd)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\DataProcessors\Расш1_Обработка1.xml
set V8_CONVERT_TOOL=ibcmd

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

set TMP_IB_PATH=%V8_TEMP%\%~n0\db

call %SCRIPTS_PATH%\conf2ib.cmd "%TEST_BINARY%\1cv8.cf" "%TMP_IB_PATH%" create

call %SCRIPTS_PATH%\ext2ib.cmd "%TEST_BINARY%\Расширение1.cfe" "%TMP_IB_PATH%" "Расширение1"

call %SCRIPTS_PATH%\ext2xml.cmd "%TMP_IB_PATH%" "%TEST_OUT_PATH%" "Расширение1"

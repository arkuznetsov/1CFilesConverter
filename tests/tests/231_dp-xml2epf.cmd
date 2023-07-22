@ECHO OFF

set TEST_NAME="DP (XML) -> binary"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_CHECK_PATH=%TEST_OUT_PATH%\ВнешняяОбработка2.epf

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\dp-xml2epf.cmd "%TEST_XML_DP%\ВнешняяОбработка2.xml" "%TEST_OUT_PATH%"

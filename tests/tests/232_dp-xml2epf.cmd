@ECHO ON

set TEST_NAME="DP (XML folder) -> binary"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_CHECK_PATH=%TEST_OUT_PATH%\ВнешняяОбработка1.epf

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\dp-xml-dir2epf.cmd "%TEST_XML_DP%" "%TEST_OUT_PATH%"

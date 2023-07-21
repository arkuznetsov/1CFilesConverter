@ECHO OFF

set TEST_NAME="Prepare data processors ^& reports with 1C:Designer XML format..."
set TEST_OUT_PATH=%TEST_XML_DP%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\ВнешняяОбработка1.xml

echo ===
echo Prepare %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

call %SCRIPTS_PATH%\dp-bin-dir2xml.cmd "%TEST_BINARY%" "%TEST_OUT_PATH%" "%TEST_IB%"

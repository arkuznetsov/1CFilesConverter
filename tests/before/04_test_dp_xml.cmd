@ECHO OFF

set TEST_NAME="Prepare data processors & reports with 1C:Designer XML format..."
set TEST_OUT_PATH=%TEST_XML_DP%
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\ВнешняяОбработка1.xml %TEST_OUT_PATH%\ВнешняяОбработка2.xml %TEST_OUT_PATH%\ВнешнийОтчет1.xml %TEST_OUT_PATH%\ВнешнийОтчет2.xml

echo ===
echo Prepare %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

call %SCRIPTS_PATH%\dp2xml.cmd "%TEST_BINARY%" "%TEST_OUT_PATH%" "%TEST_IB%"

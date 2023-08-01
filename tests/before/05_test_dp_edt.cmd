@ECHO OFF

set TEST_NAME="Prepare data processors & reports with 1C:EDT format..."
set TEST_OUT_PATH=%TEST_EDT_DP%
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\src\ExternalDataProcessors\ВнешняяОбработка1\ %TEST_OUT_PATH%\src\ExternalDataProcessors\ВнешняяОбработка2\ %TEST_OUT_PATH%\src\ExternalReports\ВнешнийОтчет1\ %TEST_OUT_PATH%\src\ExternalReports\ВнешнийОтчет2\

echo ===
echo Prepare %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

call %SCRIPTS_PATH%\dp2edt.cmd "%TEST_XML_DP%" "%TEST_OUT_PATH%"

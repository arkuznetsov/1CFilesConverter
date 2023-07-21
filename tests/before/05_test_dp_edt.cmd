@ECHO OFF

set TEST_NAME="Prepare data processors ^& reports with 1C:EDT format..."
set TEST_OUT_PATH=%TEST_EDT_DP%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\src\ExternalDataProcessors\ВнешняяОбработка2\

echo ===
echo Prepare %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

call %SCRIPTS_PATH%\xml2edt.cmd "%TEST_XML_DP%" "%TEST_OUT_PATH%"

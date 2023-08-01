@ECHO OFF

set TEST_NAME="Prepare configuration with 1C:Designer XML format..."
set TEST_OUT_PATH=%TEST_XML_CF%
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\Configuration.xml

echo ===
echo Prepare %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

call %SCRIPTS_PATH%\conf2xml.cmd "%TEST_IB%" "%TEST_OUT_PATH%"

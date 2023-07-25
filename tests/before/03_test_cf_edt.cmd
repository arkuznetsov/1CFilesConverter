@ECHO OFF

set TEST_NAME="Prepare configuration with 1C:EDT format..."
set TEST_OUT_PATH=%TEST_EDT_CF%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\src\Configuration\Configuration.mdo

echo ===
echo Prepare %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

call %SCRIPTS_PATH%\conf2edt.cmd "%TEST_XML_CF%" "%TEST_OUT_PATH%"

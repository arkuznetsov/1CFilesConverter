@ECHO OFF

set TEST_NAME="Prepare configuration extension with 1C:Designer XML format..."
set TEST_EXT_NAME=Расширение1
set TEST_OUT_PATH=%TEST_XML_EXT%\%TEST_EXT_NAME%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\Configuration.xml

echo ===
echo Prepare %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

call %SCRIPTS_PATH%\ext2xml.cmd "%TEST_BINARY%\%TEST_EXT_NAME%.cfe" "%TEST_OUT_PATH%" "%TEST_EXT_NAME%" "%TEST_BINARY%\1cv8.cf"

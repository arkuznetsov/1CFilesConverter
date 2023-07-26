@ECHO OFF

set TEST_NAME="Prepare configuration extension with 1C:Designer XML format..."
set TEST_EXT_NAME=Расширение1
set TEST_OUT_PATH=%TEST_EDT_EXT%\%TEST_EXT_NAME%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\src\Configuration\Configuration.mdo

echo ===
echo Prepare %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

call %SCRIPTS_PATH%\ext2edt.cmd "%TEST_XML_EXT%\%TEST_EXT_NAME%" "%TEST_OUT_PATH%" "%TEST_EXT_NAME%"

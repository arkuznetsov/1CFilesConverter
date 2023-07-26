@ECHO OFF

set TEST_NAME="Ext XML -> EDT"
set TEST_EXT_NAME=Расширение1
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_CHECK_PATH=%TEST_OUT_PATH%\src\Configuration\Configuration.mdo

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\ext2edt.cmd "%TEST_XML_EXT%\%TEST_EXT_NAME%" "%TEST_OUT_PATH%" "%TEST_EXT_NAME%"

@ECHO OFF

set TEST_NAME="Ext CFE -> EDT (designer)"
set TEST_EXT_NAME=Расширение1
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_CHECK_PATH=%TEST_OUT_PATH%\src\Configuration\Configuration.mdo
set V8_CONVERT_TOOL=designer

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\ext2edt.cmd "%TEST_BINARY%\%TEST_EXT_NAME%.cfe" "%TEST_OUT_PATH%" "%TEST_EXT_NAME%" "%TEST_BINARY%\1cv8.cf"

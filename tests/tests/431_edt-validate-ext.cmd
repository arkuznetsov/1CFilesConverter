@ECHO OFF

set TEST_NAME="Validate configuration extension (EDT)"
set TEST_EXT_NAME=Расширение1
set TEST_OUT_PATH=%OUT_PATH%\%~n0\report.txt
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\edt-validate.cmd "%TEST_EDT_EXT%\%TEST_EXT_NAME%" "%TEST_OUT_PATH%" "%TEST_EXT_NAME%"

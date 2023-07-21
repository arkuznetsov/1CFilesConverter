@ECHO OFF

set TEST_NAME="Validate configuration (EDT)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0\report.txt
set TEST_CHECK_PATH=%TEST_OUT_PATH%

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\edt-validate.cmd "%TEST_EDT_CF%" "%TEST_OUT_PATH%"

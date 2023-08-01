@ECHO OFF

set TEST_NAME="Validate data processors & reports"
set TEST_OUT_PATH=%OUT_PATH%\%~n0\report.txt
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\edt-validate.cmd "%TEST_EDT_DP%" "%TEST_OUT_PATH%"

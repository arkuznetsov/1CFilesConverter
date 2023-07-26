@ECHO OFF

set TEST_NAME="Conf EDT -> IB (designer)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_CHECK_PATH=%TEST_OUT_PATH%\1cv8.1cd
set V8_CONVERT_TOOL=designer

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\conf2ib.cmd "%TEST_EDT_CF%" "%TEST_OUT_PATH%"

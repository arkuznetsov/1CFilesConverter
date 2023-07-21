@ECHO OFF

set TEST_NAME="infobase -> CF (designer)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0\1cv8.cf
set TEST_CHECK_PATH=%TEST_OUT_PATH%

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\ib2cf.cmd "%TEST_IB%" "%TEST_OUT_PATH%" designer

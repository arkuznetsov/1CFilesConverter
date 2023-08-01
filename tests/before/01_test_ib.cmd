@ECHO OFF

set TEST_NAME="Prepare test infobase..."
set TEST_OUT_PATH=%TEST_IB%
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\1cv8.1cd

echo ===
echo Prepare %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

call %SCRIPTS_PATH%\conf2ib.cmd "%TEST_BINARY%\1cv8.cf" "%TEST_OUT_PATH%"

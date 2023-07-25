@ECHO OFF

set TEST_NAME="Conf infobase -> EDT (ibcmd)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_CHECK_PATH=%TEST_OUT_PATH%\src\Configuration\Configuration.mdo

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\conf2edt.cmd "%TEST_IB%" "%TEST_OUT_PATH%" ibcmd

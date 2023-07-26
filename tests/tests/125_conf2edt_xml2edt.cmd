@ECHO OFF

set TEST_NAME="Conf XML -> EDT"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_CHECK_PATH=%TEST_OUT_PATH%\src\Configuration\Configuration.mdo

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\conf2edt.cmd "%TEST_XML_CF%" "%TEST_OUT_PATH%"

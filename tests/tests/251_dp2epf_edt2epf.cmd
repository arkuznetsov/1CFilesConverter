@ECHO OFF

set TEST_NAME="DP (EDT project) -> binary"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\ВнешняяОбработка1.epf %TEST_OUT_PATH%\ВнешняяОбработка2.epf %TEST_OUT_PATH%\ВнешнийОтчет1.erf %TEST_OUT_PATH%\ВнешнийОтчет2.erf

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\dp2epf.cmd "%TEST_EDT_DP%" "%TEST_OUT_PATH%" "%TEST_IB%"

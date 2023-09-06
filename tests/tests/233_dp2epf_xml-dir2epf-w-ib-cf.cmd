@ECHO OFF

set TEST_NAME="DP (XML folder) -> binary (using IB from CF)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\ВнешняяОбработка1.epf %TEST_OUT_PATH%\ВнешняяОбработка2.epf %TEST_OUT_PATH%\ВнешнийОтчет1.erf %TEST_OUT_PATH%\ВнешнийОтчет2.erf

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
set V8_BASE_CONFIG=%TEST_BINARY%\1cv8.cf
call %SCRIPTS_PATH%\dp2epf.cmd "%TEST_XML_DP%" "%TEST_OUT_PATH%"

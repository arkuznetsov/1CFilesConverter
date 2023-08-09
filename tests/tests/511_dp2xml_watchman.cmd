@ECHO OFF

set TEST_NAME="Watchman trigger DP (binary folder) -> XML (using temp IB)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%\src\ext\ВнешняяОбработка1.xml %TEST_OUT_PATH%\src\ext\ВнешняяОбработка2.xml %TEST_OUT_PATH%\src\ext\ВнешнийОтчет1.xml %TEST_OUT_PATH%\src\ext\ВнешнийОтчет2.xml

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===

SETLOCAL

set V8_BASE_CONFIG="%FIXTURES_PATH%\bin\1cv8.cf"

md "%TEST_OUT_PATH%\src"
md "%TEST_OUT_PATH%\ext"

call %SCRIPTS_PATH%\..\wmscripts\settrigger.cmd "Test_dp2xml" "%TEST_OUT_PATH%" 1cdpr dp2xml "%TEST_OUT_PATH%\src"

copy /D /Y "%TEST_BINARY%\*.epf" /B "%TEST_OUT_PATH%\ext"
copy /D /Y "%TEST_BINARY%\*.erf" /B "%TEST_OUT_PATH%\ext"

timeout /T 10

watchman trigger-del "%TEST_OUT_PATH%" Test_dp2xml
watchman watch-del "%TEST_OUT_PATH%"

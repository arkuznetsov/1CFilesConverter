@ECHO OFF

set TEST_NAME="DP (binary) -> EDT"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_CHECK_PATH=%TEST_OUT_PATH%\src\ExternalReports\ВнешнийОтчет1\

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\dp-bin2edt.cmd "%FIXTURES_PATH%\bin\ВнешнийОтчет1.erf" "%TEST_OUT_PATH%"

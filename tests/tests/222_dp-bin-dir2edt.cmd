@ECHO OFF

set TEST_NAME="DP (binary folder) -> EDT"
set TEST_OUT_PATH=%OUT_PATH%\%~n0
set TEST_CHECK_PATH=%TEST_OUT_PATH%\src\ExternalDataProcessors\ВнешняяОбработка2\

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\dp-bin-dir2edt.cmd "%FIXTURES_PATH%\bin" "%TEST_OUT_PATH%"

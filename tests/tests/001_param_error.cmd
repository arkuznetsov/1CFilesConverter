@ECHO OFF

set TEST_NAME="Script parameters error"

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\conf2cf.cmd

IF %ERRORLEVEL% equ 0 set TEST_ERROR_MESSAGE=Failed parameter check!
@ECHO OFF

set TEST_NAME="Conf XML -> CF (designer)"
set TEST_OUT_PATH=%OUT_PATH%\%~n0\1cv8.cf
set TEST_OUT_PATH=%TEST_OUT_PATH: =_%
set TEST_CHECK_PATH=%TEST_OUT_PATH%
set V8_CONVERT_TOOL=designer

echo ===
echo Test %TEST_COUNT%. ^(%~n0^) %TEST_NAME%
echo ===
call %SCRIPTS_PATH%\conf2cf.cmd "%TEST_XML_CF%" "%TEST_OUT_PATH%"

rem @ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

chcp 65001

set SCRIPTS_PATH=%~dp0..\scripts
set BEFORE_TEST_PATH=%~dp0before
set TEST_PATH=%~dp0tests
set FIXTURES_PATH=%~dp0fixtures
set OUT_PATH=%~dp0..\out

set V8_VERSION=8.3.20.2290
set V8_TEMP=%OUT_PATH%\tmp

echo Clear output files...
if exist "%OUT_PATH%" (
    rd /S /Q "%OUT_PATH%"
)
md "%OUT_PATH%"
md "%V8_TEMP%"

echo Prepare test data...
md "%OUT_PATH%"\data\ib
md "%OUT_PATH%"\data\edt\cf
md "%OUT_PATH%"\data\edt\ext
md "%OUT_PATH%"\data\xml\cf
md "%OUT_PATH%"\data\xml\ext

set TEST_BINARY=%FIXTURES_PATH%\bin
set TEST_IB="%OUT_PATH%"\data\ib
set TEST_XML_CF="%OUT_PATH%"\data\xml\cf
set TEST_XML_DP="%OUT_PATH%"\data\xml\ext
set TEST_EDT_CF="%OUT_PATH%"\data\edt\cf
set TEST_EDT_DP="%OUT_PATH%"\data\edt\ext

set /a TEST_COUNT=0
set /a TEST_SUCCESS=0
set /a TEST_FAILED=0
set TEST_FAILED_LIST=

echo ======
echo Prepare test data...
echo ======

FOR /f %%f IN ('dir /b /a-d "%~dp0before\*.cmd"') DO (
    set /a TEST_COUNT=!TEST_COUNT!+1
    call %BEFORE_TEST_PATH%\%%~f
    if exist "!TEST_CHECK_PATH!" (
        set /a TEST_SUCCESS=!TEST_SUCCESS!+1
    ) else (
        echo ===
        echo Prepare step FAILED ^(%%~nf^): Path "!TEST_CHECK_PATH!" not found
        echo ===
        set TEST_FAILED_LIST=!TEST_FAILED_LIST! %%~nf
        set /a TEST_FAILED=!TEST_FAILED!+1
    )
    echo.
)

echo ======
echo Run tests...
echo ======

FOR /f %%f IN ('dir /b /a-d "%~dp0tests\*.cmd"') DO (
    set /a TEST_COUNT=!TEST_COUNT!+1
    call %TEST_PATH%\%%~f
    if exist "!TEST_CHECK_PATH!" (
        set /a TEST_SUCCESS=!TEST_SUCCESS!+1
    ) else (
        echo ===
        echo Test FAILED ^(%%~nf^): Path "!TEST_CHECK_PATH!" not found
        echo ===
        set TEST_FAILED_LIST=!TEST_FAILED_LIST! %%~nf
        set /a TEST_FAILED=!TEST_FAILED!+1
    )
    echo.
)

echo ======
echo Test results:
echo ======
echo.

echo     Tests total: %TEST_COUNT%
echo     Tests SUCCESS: %TEST_SUCCESS%
echo     Tests FAILED: %TEST_FAILED%:

FOR %%j IN (!TEST_FAILED_LIST!) DO (
    echo         %%j
)

rd /S /Q "%IB_PATH%"
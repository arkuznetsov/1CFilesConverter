@ECHO OFF
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

IF exist "%OUT_PATH%" rd /S /Q "%OUT_PATH%"
md "%OUT_PATH%"
md "%V8_TEMP%"

echo Prepare working directories...

md "%OUT_PATH%\data\ib"
md "%OUT_PATH%\data\edt\cf"
md "%OUT_PATH%\data\edt\ext"
md "%OUT_PATH%\data\xml\cf"
md "%OUT_PATH%\data\xml\ext"

set TEST_BINARY=%FIXTURES_PATH%\bin
set TEST_IB=%OUT_PATH%\data\ib
set TEST_XML_CF=%OUT_PATH%\data\xml\cf
set TEST_XML_DP=%OUT_PATH%\data\xml\ext
set TEST_XML_EXT=%OUT_PATH%\data\xml\cfe
set TEST_EDT_CF=%OUT_PATH%\data\edt\cf
set TEST_EDT_DP=%OUT_PATH%\data\edt\ext
set TEST_EDT_EXT=%OUT_PATH%\data\edt\cfe

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
    set TEST_ERROR_MESSAGE=
    set TEST_CHECK_PATH_SUCCESS=
    set TEST_CHECK_PATH_FAILED=
    FOR %%i IN (!TEST_CHECK_PATH!) DO (
        IF exist "%%i" (
            set TEST_CHECK_PATH_SUCCESS=!TEST_CHECK_PATH_SUCCESS! %%i
        ) ELSE (
            set TEST_CHECK_PATH_FAILED=!TEST_CHECK_PATH_FAILED! %%i
        )
    )
    IF "!TEST_ERROR_MESSAGE!" neq "" set TEST_CHECK_PATH_FAILED=!TEST_CHECK_PATH_FAILED! !TEST_ERROR_MESSAGE!
    IF "!TEST_CHECK_PATH_FAILED!" equ "" (
        set /a TEST_SUCCESS=!TEST_SUCCESS!+1
    ) ELSE (
        echo ===
        echo Test FAILED ^(%%~nf^):
        FOR %%i IN (!TEST_CHECK_PATH_FAILED!) DO echo     Path "%%i" not found
        FOR %%i IN (!TEST_CHECK_PATH_SUCCESS!) DO echo     Path "%%i" exist
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
    set TEST_ERROR_MESSAGE=
    set TEST_CHECK_PATH_SUCCESS=
    set TEST_CHECK_PATH_FAILED=
    FOR %%i IN (!TEST_CHECK_PATH!) DO (
        IF exist "%%i" (
            set TEST_CHECK_PATH_SUCCESS=!TEST_CHECK_PATH_SUCCESS! %%i
        ) ELSE (
            set TEST_CHECK_PATH_FAILED=!TEST_CHECK_PATH_FAILED! %%i
        )
    )
    IF "!TEST_ERROR_MESSAGE!" neq "" set TEST_CHECK_PATH_FAILED=!TEST_CHECK_PATH_FAILED! !TEST_ERROR_MESSAGE!
    IF "!TEST_CHECK_PATH_FAILED!" equ "" (
        set /a TEST_SUCCESS=!TEST_SUCCESS!+1
    ) ELSE (
        echo ===
        echo Test FAILED ^(%%~nf^):
        FOR %%i IN (!TEST_CHECK_PATH_FAILED!) DO echo     Path "%%i" not found
        FOR %%i IN (!TEST_CHECK_PATH_SUCCESS!) DO echo     Path "%%i" exist
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
echo     Tests FAILED: %TEST_FAILED%

FOR %%j IN (!TEST_FAILED_LIST!) DO (
    echo         %%j
)

IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"

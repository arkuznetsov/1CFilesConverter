@rem ----------------------------------------------------------
@rem This Source Code Form is subject to the terms of the
@rem Mozilla Public License, v.2.0. If a copy of the MPL
@rem was not distributed with this file, You can obtain one
@rem at http://mozilla.org/MPL/2.0/.
@rem ----------------------------------------------------------
@rem Codebase: https://github.com/ArKuznetsov/1CFilesConverter/
@rem ----------------------------------------------------------

@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

chcp 65001

FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%~dp0.." /M "scripts" /C "cmd /c echo @path"`) DO set SCRIPTS_PATH=%%i
set SCRIPTS_PATH=%SCRIPTS_PATH:"=%
set BEFORE_TEST_PATH=%~dp0before
set TEST_PATH=%~dp0tests
set AFTER_TEST_PATH=%~dp0after
set FIXTURES_PATH=%~dp0fixtures
FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%~dp0.." /M "out" /C "cmd /c echo @path"`) DO set OUT_PATH=%%i
set OUT_PATH=%OUT_PATH:"=%

echo [INFO] Clear output files...

IF exist "%OUT_PATH%" rd /S /Q "%OUT_PATH%"
md "%OUT_PATH%"

echo [INFO] Prepare working directories...

md "%OUT_PATH%\data\ib"
md "%OUT_PATH%\data\edt\cf"
md "%OUT_PATH%\data\edt\ext"
md "%OUT_PATH%\data\xml\cf"
md "%OUT_PATH%\data\xml\ext"

IF exist "%~dp0.env" (
    FOR /F "usebackq tokens=*" %%a in ("%~dp0.env") DO (
      FOR /F "tokens=1* delims==" %%b IN ("%%a") DO ( 
        set "%%b=%%c"
      )
    )
)

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290
IF not defined V8_TEMP set V8_TEMP=%OUT_PATH%\tmp

md "%V8_TEMP%"

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

set TESTS_START=%date% %time%

echo ======
echo Prepare test data...
echo ======

FOR /f /F "tokens=*" %%f IN ('dir /b /a-d "%BEFORE_TEST_PATH%\*.cmd"') DO (
    set /a TEST_COUNT=!TEST_COUNT!+1
    set TEST_START=!date! !time!
    call "%BEFORE_TEST_PATH%\%%~f"
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
    echo ===
    echo Start: !TEST_START!
    echo Finish: !date! !time!
    echo ===
    IF "!TEST_CHECK_PATH_FAILED!" equ "" (
        echo [SUCCESS] Test SUCCESS ^(%%~nf^)
        set /a TEST_SUCCESS=!TEST_SUCCESS!+1
    ) ELSE (
        echo [ERROR] Test FAILED ^(%%~nf^):
        FOR %%i IN (!TEST_CHECK_PATH_FAILED!) DO echo     Path "%%i" not found
        FOR %%i IN (!TEST_CHECK_PATH_SUCCESS!) DO echo     Path "%%i" exist
        set TEST_FAILED_LIST=!TEST_FAILED_LIST! !TEST_COUNT!:%%~nf
        set /a TEST_FAILED=!TEST_FAILED!+1
    )
    echo ===
    echo.
)

echo ======
echo Run tests...
echo ======

FOR /F "tokens=*" %%f IN ('dir /b /a-d "%TEST_PATH%\*.cmd"') DO (
    set /a TEST_COUNT=!TEST_COUNT!+1
    set TEST_START=!date! !time!
    call "%TEST_PATH%\%%~f"
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
    echo ===
    echo Start: !TEST_START!
    echo Finish: !date! !time!
    echo ===
    IF "!TEST_CHECK_PATH_FAILED!" equ "" (
        echo [SUCCESS] Test SUCCESS ^(%%~nf^)
        set /a TEST_SUCCESS=!TEST_SUCCESS!+1
    ) ELSE (
        echo [ERROR] Test FAILED ^(%%~nf^):
        FOR %%i IN (!TEST_CHECK_PATH_FAILED!) DO echo     Path "%%i" not found
        FOR %%i IN (!TEST_CHECK_PATH_SUCCESS!) DO echo     Path "%%i" exist
        set TEST_FAILED_LIST=!TEST_FAILED_LIST! !TEST_COUNT!:%%~nf
        set /a TEST_FAILED=!TEST_FAILED!+1
    )
    echo ===
    echo.
)

echo ======
echo Clear test data...
echo ======

FOR /f /F "tokens=*" %%f IN ('dir /b /a-d "%AFTER_TEST_PATH%\*.cmd"') DO (
    set /a TEST_COUNT=!TEST_COUNT!+1
    set TEST_START=!date! !time!
    call "%AFTER_TEST_PATH%\%%~f"
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
    echo ===
    echo Start: !TEST_START!
    echo Finish: !date! !time!
    echo ===
    IF "!TEST_CHECK_PATH_FAILED!" equ "" (
        echo [SUCCESS] Test SUCCESS ^(%%~nf^)
        set /a TEST_SUCCESS=!TEST_SUCCESS!+1
    ) ELSE (
        echo [ERROR] Test FAILED ^(%%~nf^):
        FOR %%i IN (!TEST_CHECK_PATH_FAILED!) DO echo     Path "%%i" not found
        FOR %%i IN (!TEST_CHECK_PATH_SUCCESS!) DO echo     Path "%%i" exist
        set TEST_FAILED_LIST=!TEST_FAILED_LIST! !TEST_COUNT!:%%~nf
        set /a TEST_FAILED=!TEST_FAILED!+1
    )
    echo ===
    echo.
)

IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"

echo ======
echo Test results:
echo ======
echo.

echo     Tests total: !TEST_COUNT!
echo     Tests SUCCESS: !TEST_SUCCESS!
echo     Tests FAILED: !TEST_FAILED!

FOR %%j IN (!TEST_FAILED_LIST!) DO (
    echo         %%j
)
echo ======
echo Start: %TESTS_START%
echo Finish: %date% %time%
echo ======

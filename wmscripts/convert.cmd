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

set CONVERT_VERSION=UNKNOWN
IF exist "%~dp0..\VERSION" FOR /F "usebackq tokens=* delims=" %%i IN ("%~dp0..\VERSION") DO set CONVERT_VERSION=%%i
echo 1C files converter v.%CONVERT_VERSION%
echo ===
echo [INFO] Running conversion of files

set ERROR_CODE=0

set CONVERT_SCRIPT=%1
IF defined CONVERT_SCRIPT set CONVERT_SCRIPT=%CONVERT_SCRIPT:"=%
IF not defined CONVERT_SCRIPT (
    echo [ERROR] Missed parameter 1 - "path to conversion script file (could be 1C converter script name or full path to script file)"
    set ERROR_CODE=1
)
IF not exist "%CONVERT_SCRIPT%" (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%~dp0.." /M "scripts" /C "cmd /c echo @path"`) DO set CONVERT_SCRIPT_PATH=%%i
    set CONVERT_SCRIPT_PATH=!CONVERT_SCRIPT_PATH:"=!
    echo [WARN] Script file "%CONVERT_SCRIPT%" doesn't exist ^(parameter 1^). Trying to find in "!CONVERT_SCRIPT_PATH!" directory.
    set CONVERT_SCRIPT=!CONVERT_SCRIPT_PATH!\%CONVERT_SCRIPT%.cmd
)
IF not exist "%CONVERT_SCRIPT%" (
    echo [ERROR] Script file "%CONVERT_SCRIPT%" doesn't exist ^(parameter 1^).
    set ERROR_CODE=1
)
set CONVERT_SRC_PATH=%2
IF defined CONVERT_SRC_PATH set CONVERT_SRC_PATH=%CONVERT_SRC_PATH:"=%
IF not defined CONVERT_SRC_PATH (
    echo [ERROR] Missed parameter 1 - "path to convertion source"
    set ERROR_CODE=1
) ELSE (
    IF not exist "%CONVERT_SRC_PATH%" (
        echo [ERROR] Path "%CONVERT_SRC_PATH%" doesn't exist ^(parameter 2^).
        set ERROR_CODE=1
    )
)

set CONVERT_DST_PATH=%3
IF defined CONVERT_DST_PATH set CONVERT_DST_PATH=%CONVERT_DST_PATH:"=%
IF not defined CONVERT_DST_PATH (
    echo [ERROR] Missed parameter 3 - "output path to save conversion results"
    set ERROR_CODE=1
)
IF not exist "%CONVERT_DST_PATH%" md "%CONVERT_DST_PATH%"

set V8_DP_CLEAN_DST=0
FOR /F "tokens=*" %%a in ('more') do (
    set CURRENT_FILE=%%a
    set CURRENT_FILE=!CURRENT_FILE:^/=^\!
    set RELATIVE_PATH=!CURRENT_FILE:%%~nxa=!
    IF defined RELATIVE_PATH (
        set RELATIVE_PATH=!RELATIVE_PATH:~0,-1!
        set CONVERT_DST_PATH=%CONVERT_DST_PATH%\!RELATIVE_PATH!
    )
    call "%CONVERT_SCRIPT%" "%CONVERT_SRC_PATH%\!CURRENT_FILE!" "!CONVERT_DST_PATH!"
)

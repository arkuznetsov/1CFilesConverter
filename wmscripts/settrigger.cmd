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

set CONVERT_VERSION=UNKNOWN
IF exist "%~dp0..\VERSION" FOR /F "usebackq tokens=* delims=" %%i IN ("%~dp0..\VERSION") DO set CONVERT_VERSION=%%i
echo 1C files converter v.%CONVERT_VERSION%
echo ===
echo Creating trigger watching 1C files

set ERROR_CODE=0

IF not defined WATCH_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where watchman`) DO (
        set WATCH_TOOL="%%i"
    )
)
IF not defined WATCH_TOOL (
    echo [ERROR] Can't find "watchman" tool. Add path to "watchman.exe" to "PATH" environment variable, or set "WATCH_TOOL" variable with full specified path 
    set ERROR_CODE=1
)

set ARG=%1
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set TRIGGER_NAME=%ARG%
IF not defined TRIGGER_NAME (
    echo [ERROR] Missed parameter 1 - "watchman trigger name"
    set ERROR_CODE=1
)

set ARG=%2
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set WATCH_PATH=%ARG%
IF not defined WATCH_PATH (
    echo [ERROR] Missed parameter 2 - "path to watched root"
    set ERROR_CODE=1
) ELSE (
    IF not exist "%WATCH_PATH%" (
        echo [ERROR] Path "%WATCH_PATH%" doesn't exist ^(parameter 2^).
        set ERROR_CODE=1
    )
)

set ARG=%3
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set WATCH_FILES=%ARG%
IF not defined WATCH_FILES (
    echo [ERROR] Missed parameter 4 - "files extension to watch for"
    set ERROR_CODE=1
)
IF "%WATCH_FILES%" equ "1cdpr" (
    set WATCH_FILES=epf erf
) ELSE IF "%WATCH_FILES%" equ "1cxml" (
    set WATCH_FILES=xml bsl bin mxl png grs geo txt
) ELSE IF "%WATCH_FILES%" equ "1cedt" (
    set WATCH_FILES=mdo bsl bin mxl png grs geo txt
)

set ARG=%4
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set WATCH_SCRIPT=%ARG%
IF not defined WATCH_SCRIPT (
    echo [ERROR] Missed parameter 2 - "path to triggered script file (could be 1C converter script name or full path to script file)"
    set ERROR_CODE=1
)
IF not exist "%WATCH_SCRIPT%" (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`FORFILES /P "%~dp0.." /M "scripts" /C "cmd /c echo @path"`) DO set WATCH_SCRIPT_PATH=%%i
    echo [WARN] Script file "%WATCH_SCRIPT%" doesn't exist ^(parameter 4^). Trying to find in "!WATCH_SCRIPT_PATH!" directory.
    set WATCH_SCRIPT_PATH=!WATCH_SCRIPT_PATH:"=!
    set WATCH_SCRIPT=!WATCH_SCRIPT_PATH!\%WATCH_SCRIPT%.cmd
)
IF not exist "%WATCH_SCRIPT%" (
    echo [ERROR] Script file "%WATCH_SCRIPT%" doesn't exist ^(parameter 4^).
    set ERROR_CODE=1
)

set ARG=%5
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set WATCH_OUT_PATH=%ARG%
IF not defined WATCH_OUT_PATH (
    echo [ERROR] Missed parameter 5 - "output path to save script results"
    set ERROR_CODE=1
)
IF not exist "%WATCH_OUT_PATH%" md "%WATCH_OUT_PATH%"

IF %ERROR_CODE% neq 0 (
    echo ===
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - watchman trigger name
    echo     %%2 - path to watched root
    echo     %%3 - files masks to watch for, devided by spaces or one of extension set name:
    echo           1cdpr - 1C dataprocessors ^& reports binaries
    echo           1cxml - 1C configuration, extension, dataprocessors or reports in 1C:Designer XML format
    echo           1cedt - 1C configuration, extension, dataprocessors or reports in 1C:EDT project
    echo     %%4 - path to triggered script file ^(could be 1C converter script name or full path to script file^)
    echo     %%5 - output path to save script results
    echo.
    exit /b %ERROR_CODE%
)

set WATCH_JSON=["watch", "%WATCH_PATH:\=\\%"]
echo %WATCH_JSON% | %WATCH_TOOL% -j

set TRIGGER_EXPRESSION=["anyof"
FOR %%i IN (%WATCH_FILES%) DO (
   set TRIGGER_EXPRESSION=!TRIGGER_EXPRESSION!,["imatch","*.%%i"]
)
set TRIGGER_EXPRESSION=!TRIGGER_EXPRESSION!]

set TRIGGER_SCRIPT=%~dp0convert.cmd
set TRIGGER_COMMAND=["%TRIGGER_SCRIPT:\=\\%", "%WATCH_SCRIPT:\=\\%", "%WATCH_PATH:\=\\%", "%WATCH_OUT_PATH:\=\\%"]

set TRIGGER_STDIN="NAME_PER_LINE"

IF defined WATCH_LOG set TRIGGER_STDOUT=, "stdout": ">%WATCH_LOG%"

set TRIGGER_JSON=["trigger", "%WATCH_PATH:\=\\%", ^{"name": "%TRIGGER_NAME%", "expression": %TRIGGER_EXPRESSION%, "command": %TRIGGER_COMMAND%, "stdin": %TRIGGER_STDIN%%TRIGGER_STDOUT%^}]
echo %TRIGGER_JSON% | %WATCH_TOOL% -j
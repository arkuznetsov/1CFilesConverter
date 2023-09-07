@rem ----------------------------------------------------------
@rem This Source Code Form is subject to the terms of the
@rem Mozilla Public License, v.2.0. If a copy of the MPL
@rem was not distributed with this file, You can obtain one
@rem at http://mozilla.org/MPL/2.0/.
@rem ----------------------------------------------------------
@rem Codebase: https://github.com/ArKuznetsov/1CFilesConverter/
@rem ----------------------------------------------------------

@ECHO OFF

SETLOCAL

set CONVERT_VERSION=UNKNOWN
IF exist "%~dp0..\VERSION" FOR /F "usebackq tokens=* delims=" %%i IN ("%~dp0..\VERSION") DO set CONVERT_VERSION=%%i
echo 1C files converter v.%CONVERT_VERSION%
echo ===
echo Convert 1C external data processors ^& reports to 1C:Designer XML format

set ERROR_CODE=0

IF exist "%cd%\.env" (
    FOR /F "tokens=*" %%a in (%cd%\.env) DO (
        FOR /F "tokens=1,2 delims==" %%b IN ("%%a") DO (
            IF not defined %%b set "%%b=%%c"
        )
    )
)

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290
IF not defined V8_TEMP set V8_TEMP=%TEMP%\1c

set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
IF "%V8_CONVERT_TOOL%" equ "designer" IF not exist %V8_TOOL% (
    echo Could not find 1C:Designer with path %V8_TOOL%
    exit /b 1
)
IF not defined V8_RING_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
        set V8_RING_TOOL="%%i"
    )
)
IF not defined V8_RING_TOOL (
    echo [ERROR] Can't find "ring" tool. Add path to "ring.bat" to "PATH" environment variable, or set "V8_RING_TOOL" variable with full specified path 
    set ERROR_CODE=1
)

set LOCAL_TEMP=%V8_TEMP%\%~n0
set IB_PATH=%LOCAL_TEMP%\tmp_db
set WS_PATH=%LOCAL_TEMP%\edt_ws

set ARG=%1
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_SRC_PATH=%ARG%
set V8_SRC_FOLDER=%~dp1
set V8_SRC_FOLDER=%V8_SRC_FOLDER:~0,-1%
set ARG=%2
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_DST_PATH=%ARG%

IF not defined V8_SRC_PATH (
    echo [ERROR] Missed parameter 1 - "path to folder containing data processors (*.epf) & reports (*.erf) in binary or EDT project or path to binary data processor (*.epf) or report (*.erf)"
    set ERROR_CODE=1
) ELSE (
    IF not exist "%V8_SRC_PATH%" (
        echo [ERROR] Path "%V8_SRC_PATH%" doesn't exist ^(parameter 1^).
        set ERROR_CODE=1
    )
)
IF not defined V8_DST_PATH (
    echo [ERROR] Missed parameter 2 - "path to folder to save 1C data processors & reports in 1C:Designer XML format"
    set ERROR_CODE=1
)
IF defined V8_BASE_IB (
    set V8_BASE_IB=%V8_BASE_IB:"=%
) ELSE (
    echo [INFO] Environment variable "V8_BASE_IB" is not defined, temporary file infobase will be used.
    set V8_BASE_IB=
)
IF defined V8_BASE_CONFIG (
    set V8_BASE_CONFIG=%V8_BASE_CONFIG:"=%
) ELSE (
    echo [INFO] Environment variable "V8_BASE_CONFIG" is not defined, empty configuration will be used.
    set V8_BASE_CONFIG=
)
IF %ERROR_CODE% neq 0 (
    echo ===
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - path to folder containing data processors ^(*.epf^) ^& reports ^(*.erf^) in binary or EDT project
    echo           or path to binary data processor ^(*.epf^) or report ^(*.erf^)
    echo     %%2 - path to folder to save 1C data processors ^& reports in 1C:Designer XML format
    echo.
    exit /b %ERROR_CODE%
)

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"
md "%LOCAL_TEMP%"
IF not exist "%V8_DST_PATH%" md "%V8_DST_PATH%"

echo [INFO] Set infobase for export data processor/report...

IF "%V8_BASE_IB%" equ "" (
    md "%IB_PATH%"
    echo [INFO] Creating temporary file infobase "%IB_PATH%"...
    set V8_BASE_IB_CONNECTION=File="!IB_PATH!";
    %V8_TOOL% CREATEINFOBASE %V8_BASE_IB_CONNECTION% /DisableStartupDialogs
    goto prepare_ib
)
IF /i "%V8_BASE_IB:~0,2%" equ "/F" (
    set IB_PATH=%V8_BASE_IB:~2%
    echo [INFO] Basic config type: File infobase ^(!IB_PATH!^)
    set V8_BASE_IB_CONNECTION=File="!IB_PATH!";
    goto prepare_ib
)
IF /i "%V8_BASE_IB:~0,2%" equ "/S" (
    set IB_PATH=%V8_BASE_IB:~2%
    FOR /F "tokens=1,2 delims=\" %%a IN ("!IB_PATH!") DO (
        set V8_BASE_IB_SERVER=%%a
        set V8_BASE_IB_NAME=%%b
    )
    set IB_PATH=!V8_BASE_IB_SERVER!\!V8_BASE_IB_NAME!
    echo [INFO] Basic config type: Server infobase ^(!V8_BASE_IB_SERVER!\!V8_BASE_IB_NAME!^)
    set V8_BASE_IB_CONNECTION=Srvr="!V8_BASE_IB_SERVER!";Ref="!V8_BASE_IB_NAME!";
    goto prepare_ib
)
IF exist "%V8_BASE_IB%\1cv8.1cd" (
    set IB_PATH=%V8_BASE_IB%
    echo [INFO] Basic config type: File infobase ^(!V8_SRC_PATH!^)
    set V8_BASE_IB_CONNECTION=File="!IB_PATH!";
    goto prepare_ib
)

:prepare_ib

IF "%V8_BASE_CONFIG%" equ "" goto export

IF not exist "%IB_PATH%" md "%IB_PATH%"
call %~dp0conf2ib.cmd "%V8_BASE_CONFIG%" "%IB_PATH%"
IF ERRORLEVEL 0 goto export

echo [ERROR] Error cheking type of basic configuration "%V8_BASE_CONFIG%"!
echo Infobase, configuration file ^(*.cf^), 1C:Designer XML, 1C:EDT project or no configuration expected.
exit /b 1

:export

echo [INFO] Checking data processord ^& reports source type...

set V8_SRC_IS_EDT=0
IF exist "%V8_SRC_PATH%\DT-INF\" (
    IF exist "%V8_SRC_PATH%\src\ExternalDataProcessors\" set V8_SRC_IS_EDT=1
    IF exist "%V8_SRC_PATH%\src\ExternalReports\" set V8_SRC_IS_EDT=1
)
IF "%V8_SRC_IS_EDT%" equ "1" (
    echo [INFO] Source type: 1C:EDT project
    goto end
)
set V8_SRC_MASK="%V8_SRC_PATH%"
IF /i "%V8_SRC_PATH:~-4%" equ ".epf" (
    echo [INFO] Source type: External data processor binary file ^(epf^)
    goto export_epf
)
IF /i "%V8_SRC_PATH:~-4%" equ ".erf" (
    echo [INFO] Source type: External report binary file ^(erf^)
    goto export_epf
)
FOR /F "delims=" %%f IN ('dir /b /a-d "%V8_SRC_PATH%\*.epf" "%V8_SRC_PATH%\*.erf"') DO (
    echo [INFO] Source type: External data processors ^(epf^) ^& reports ^(erf^) binary files
    set V8_SRC_FOLDER=%V8_SRC_PATH%
    set V8_SRC_MASK="%V8_SRC_PATH%\*.epf" "%V8_SRC_PATH%\*.erf"
    goto export_epf
)

echo [ERROR] Wrong path "%V8_SRC_PATH%"!
echo Folder containing external data processors ^& reports in binary or EDT project, data processor binary ^(*.epf^) or report binary ^(*.erf^) expected.
exit /b 1

:export_epf

echo [INFO] Export data processors ^& reports from folder "%V8_SRC_PATH%" to 1C:Designer XML format "%V8_DST_PATH%" using infobase "%IB_PATH%"...
FOR /F "delims=" %%f IN ('dir /b /a-d %V8_SRC_MASK%') DO (
    echo [INFO] Building %%~nf...
    %V8_TOOL% DESIGNER /IBConnectionString %V8_BASE_IB_CONNECTION% /N"%V8_IB_USER%" /P"%V8_IB_PWD%" /DisableStartupDialogs /DumpExternalDataProcessorOrReportToFiles "%V8_DST_PATH%\%%~nf.xml" "%V8_SRC_FOLDER%\%%~nxf"
)

goto end

:export_xml

echo [INFO] Export dataprocessors ^& reports from 1C:EDT project "%V8_SRC_PATH%" to 1C:Designer XML format "%V8_DST_PATH%"...

md "%WS_PATH%"

call %V8_RING_TOOL% edt workspace export --project "%V8_SRC_PATH%" --configuration-files "%V8_DST_PATH%" --workspace-location "%WS_PATH%"

:end

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"

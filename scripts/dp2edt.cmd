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

IF not defined V8_ENCODING set V8_ENCODING=65001
chcp %V8_ENCODING% > nul

set CONVERT_VERSION=UNKNOWN
IF exist "%~dp0..\VERSION" FOR /F "usebackq tokens=* delims=" %%i IN ("%~dp0..\VERSION") DO set CONVERT_VERSION=%%i
echo 1C files converter v.%CONVERT_VERSION%
echo ======
echo [INFO] Convert 1C external data processors ^& reports to 1C:EDT project

set ERROR_CODE=0

IF exist "%cd%\.env" IF "%V8_SKIP_ENV%" neq "1" (
    FOR /F "usebackq tokens=*" %%a in ("%cd%\.env") DO (
        FOR /F "tokens=1* delims==" %%b IN ("%%a") DO ( 
            IF not defined %%b set "%%b=%%c"
        )
    )
)

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290
IF not defined V8_TEMP set V8_TEMP=%TEMP%\1c

echo [INFO] Using 1C:Enterprise, version %V8_VERSION%
echo [INFO] Using temporary folder "%V8_TEMP%"

IF not defined V8_TOOL set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
IF "%V8_CONVERT_TOOL%" equ "designer" IF not exist %V8_TOOL% (
    echo Could not find 1C:Designer with path %V8_TOOL%
    set ERROR_CODE=1
    goto finally
)

IF defined V8_EDT_VERSION (
    set V8_EDT_VERSION=@%V8_EDT_VERSION:@=%
)

echo [INFO] Start conversion using "designer"

set LOCAL_TEMP=%V8_TEMP%\%~n0
set IB_PATH=%LOCAL_TEMP%\tmp_db
set XML_PATH=%LOCAL_TEMP%\tmp_xml
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
    echo [ERROR] Missed parameter 1 - "path to folder containing data processors (*.epf) & reports (*.erf) in binary or XML format or path to binary data processor (*.epf) or report (*.erf)"
    set ERROR_CODE=1
) ELSE (
    IF not exist "%V8_SRC_PATH%" (
        echo [ERROR] Path "%V8_SRC_PATH%" doesn't exist ^(parameter 1^).
        set ERROR_CODE=1
    )
)
IF not defined V8_DST_PATH (
    echo [ERROR] Missed parameter 2 - "path to folder to save 1C data processors & reports in 1C:EDT format"
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
    echo ======
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - path to folder containing data processors ^(*.epf^) ^& reports ^(*.erf^) in binary or XML format
    echo           or path to binary data processor ^(*.epf^) or report ^(*.erf^)
    echo     %%2 - path to folder to save 1C data processors ^& reports in 1C:EDT format
    echo.
    goto finally
)

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"
md "%LOCAL_TEMP%"
IF exist "%V8_DST_PATH%" IF "%V8_DP_CLEAN_DST%" equ "1" (
    del /f /s /q "%V8_DST_PATH%\*.*" > nul
    rd /S /Q "%V8_DST_PATH%"
)
IF not exist "%V8_DST_PATH%" md "%V8_DST_PATH%"

echo [INFO] Set infobase for export data processor/report...

IF "%V8_BASE_IB%" equ "" (
    md "%IB_PATH%"
    echo [INFO] Creating temporary file infobase "%IB_PATH%"...
    set V8_BASE_IB_CONNECTION=File="%IB_PATH%";
    %V8_TOOL% CREATEINFOBASE !V8_BASE_IB_CONNECTION! /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!"
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
set ERROR_CODE=1
goto finally

:export

echo [INFO] Checking data processord ^& reports source type...

set V8_SRC_MASK="%V8_SRC_PATH%"
IF /i "%V8_SRC_PATH:~-4%" equ ".xml" (
    echo [INFO] Source type: 1C:Designer XML files ^(external data processor or report^)
    set XML_PATH=%V8_SRC_FOLDER%
    goto export_xml
)
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
FOR /F "delims=" %%f IN ('dir /b /a-d "%V8_SRC_PATH%\*.xml"') DO (
    echo [INFO] Source type: 1C:Designer XML files folder ^(external data processors ^& reports^)
    set XML_PATH=%V8_SRC_PATH%
    set V8_SRC_MASK="%V8_SRC_PATH%\*.xml"
    goto export_xml
)

echo [ERROR] Wrong path "%V8_SRC_PATH%"!
echo Folder containing external data processors ^& reports in binary or XML format, data processor binary ^(*.epf^) or report binary ^(*.erf^) expected.
set ERROR_CODE=1
goto finally

:export_epf

echo [INFO] Export data processors ^& reports from folder "%V8_SRC_PATH%" to 1C:Designer XML format "%XML_PATH%" using infobase "%IB_PATH%"...

md "%XML_PATH%"

set V8_DESIGNER_LOG=%LOCAL_TEMP%\v8_designer_output.log

FOR /F "delims=" %%f IN ('dir /b /a-d %V8_SRC_MASK%') DO (
    echo [INFO] Building %%~nf...
    %V8_TOOL% DESIGNER /IBConnectionString %V8_BASE_IB_CONNECTION% /N"%V8_IB_USER%" /P"%V8_IB_PWD%" /DisableStartupDialogs /Out "!V8_DESIGNER_LOG!" /DumpExternalDataProcessorOrReportToFiles "%XML_PATH%" "%V8_SRC_FOLDER%\%%~nxf"
    FOR /F "tokens=* delims=" %%i IN (!V8_DESIGNER_LOG!) DO IF "%%i" neq "" echo [WARN] %%i
    IF not ERRORLEVEL 0 (
        set ERROR_CODE=%ERRORLEVEL%
        goto finally
    )
)

:export_xml

md "%WS_PATH%"

echo [INFO] Export dataprocessors ^& reports from 1C:Designer XML format "%XML_PATH%" to 1C:EDT format "%V8_DST_PATH%"...
IF not defined RING_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
        set RING_TOOL="%%i"
    )
)
IF not defined RING_TOOL (
    echo [ERROR] Can't find "ring" tool. Add path to "ring.bat" to "PATH" environment variable, or set "RING_TOOL" variable with full specified path 
    set ERROR_CODE=1
    goto finally
)
call %RING_TOOL% edt%V8_EDT_VERSION% workspace import --project "%V8_DST_PATH%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%" --version "%V8_VERSION%"
IF not ERRORLEVEL 0 (
    set ERROR_CODE=%ERRORLEVEL%
    goto finally
)

call %RING_TOOL% edt%V8_EDT_VERSION% workspace clean-up-source --workspace-location "%WS_PATH%" --project "%V8_DST_PATH%"
set ERROR_CODE=%ERRORLEVEL%

:finally

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"

exit /b %ERROR_CODE%

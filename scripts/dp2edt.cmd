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
IF exist "..\VERSION" FOR /F "usebackq tokens=* delims=" %%i IN ("..\VERSION") DO set CONVERT_VERSION=%%i
echo 1C files converter v.%CONVERT_VERSION%
echo ===
echo Convert 1C external data processors ^& reports to 1C:EDT project

set ERROR_CODE=0

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
set ARG=%3
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_BASE_CONFIG=%ARG%

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
IF not exist "%V8_BASE_CONFIG%" (
    echo [INFO] Path "%V8_BASE_CONFIG%" doesn't exist ^(parameter 3^), empty infobase will be used.
    set V8_BASE_CONFIG=
)
IF %ERROR_CODE% neq 0 (
    echo ===
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - path to folder containing data processors ^(*.epf^) ^& reports ^(*.erf^) in binary or XML format
    echo           or path to binary data processor ^(*.epf^) or report ^(*.erf^)
    echo     %%2 - path to folder to save 1C data processors ^& reports in 1C:EDT format
    echo     %%3 - ^(optional^) path to 1C configuration ^(binary ^(*.cf^), 1C:Designer XML format or 1C:EDT project^)
    echo           or folder contains 1C infobase used for convertion
    echo.
    exit /b %ERROR_CODE%
)

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"
md "%LOCAL_TEMP%"
IF exist "%V8_DST_PATH%" rd /S /Q "%V8_DST_PATH%"
md %V8_DST_PATH%

echo [INFO] Set infobase for export data processor/report...

set BASE_CONFIG_DESCRIPTION=configuration from "%V8_BASE_CONFIG%"

IF "%V8_BASE_CONFIG%" equ "" (
    md "%IB_PATH%"
    echo [INFO] Creating infobase "%IB_PATH%"...
    set BASE_CONFIG_DESCRIPTION=empty configuration
    %V8_TOOL% CREATEINFOBASE File="%IB_PATH%"; /DisableStartupDialogs
    goto export
)
IF exist "%V8_BASE_CONFIG%\1cv8.1cd" (
    echo [INFO] Basic config source type: Infobase
    set BASE_CONFIG_DESCRIPTION=existed configuration
    set IB_PATH=%V8_BASE_CONFIG%
    goto export
)
md "%IB_PATH%"
call %~dp0conf2ib.cmd "%V8_BASE_CONFIG%" "%IB_PATH%"
IF ERRORLEVEL 0 goto export

echo [ERROR] Error cheking type of basic configuration "%V8_BASE_CONFIG%"!
echo Infobase, configuration file ^(*.cf^), 1C:Designer XML, 1C:EDT project or no configuration expected.
exit /b 1

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
exit /b 1

:export_epf

echo [INFO] Export data processors ^& reports from folder "%V8_SRC_PATH%" to 1C:Designer XML format "%XML_PATH%" using infobase "%IB_PATH%" with %BASE_CONFIG_DESCRIPTION%...

md "%XML_PATH%"

FOR /F "delims=" %%f IN ('dir /b /a-d %V8_SRC_MASK%') DO (
    echo [INFO] Building %%~nf...
    %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /DumpExternalDataProcessorOrReportToFiles "%XML_PATH%" "%V8_SRC_FOLDER%\%%~nxf"
)

:export_xml

md "%WS_PATH%"

echo [INFO] Export dataprocessors ^& reports from 1C:Designer XML format "%XML_PATH%" to 1C:EDT format "%V8_DST_PATH%"...
call %V8_RING_TOOL% edt workspace import --project "%V8_DST_PATH%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%" --version "%V8_VERSION%"

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"

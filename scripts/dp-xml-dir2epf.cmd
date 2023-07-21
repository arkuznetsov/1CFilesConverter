@ECHO OFF

rem Convert (load) all 1C data processors & reports in folder from 1C:Designer XML format to binary format (*.epf, *.erf)
rem %1 - path to folder contains 1C data processors & reports in 1C:Designer XML format
rem %2 - path to folder to save data processors & reports in binary format (*.epf, *.erf)
rem %3 - path to 1C configuration (binary (*.cf), 1C:Designer XML format or 1C:EDT format)
rem      or folder contains 1C infobase used for convertion

if not defined V8_VERSION set V8_VERSION=8.3.20.2290

set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"

set IB_PATH=%TEMP%\1c\tmp_db
set CLEAN_AFTER_EXPORT=0

set DP_SRC_PATH=%1
if defined DP_SRC_PATH set DP_SRC_PATH=%DP_SRC_PATH:"=%
set DP_BIN_PATH=%2
if defined DP_BIN_PATH set DP_BIN_PATH=%DP_BIN_PATH:"=%
set BASE_CONFIG=%3
if defined BASE_CONFIG set BASE_CONFIG=%BASE_CONFIG:"=%

if not defined DP_SRC_PATH (
    echo Missed parameter 1 "path to folder contains 1C data processors & reports in 1C:Designer XML format"
    exit /b 1
)
if not defined DP_BIN_PATH (
    echo Missed parameter 2 "path to folder to save data processors & reports in binary format (*.epf, *.erf)"
    exit /b 1
)
if not exist "%BASE_CONFIG%" (
    echo Path "%BASE_CONFIG%" doesn't exist ^(parameter 3^), empty infobase will be used.
    set BASE_CONFIG=
)

echo Set infobase for import data processor/report...
IF "%BASE_CONFIG%" equ "" (
    echo Creating infobase "%IB_PATH%"...
    set CLEAN_AFTER_EXPORT=1
    set BASE_CONFIG_DESCRIPTION=empty configuration
    %V8_TOOL% CREATEINFOBASE File=%IB_PATH%; /DisableStartupDialogs
) else (
    set BASE_CONFIG_DESCRIPTION=configuration from "%BASE_CONFIG%"
    IF exist "%BASE_CONFIG%\DT-INF\" (
        set CLEAN_AFTER_EXPORT=1
        call %~dp0edt2ib.cmd "%BASE_CONFIG%" "%IB_PATH%"
    ) else (
        IF exist "%BASE_CONFIG%\Configuration.xml" (
            set CLEAN_AFTER_EXPORT=1
            call %~dp0xml2ib.cmd "%BASE_CONFIG%" "%IB_PATH%"
        ) else (
            IF exist "%BASE_CONFIG%\1cv8.1cd" (
                set BASE_CONFIG_DESCRIPTION=existed configuration
                set IB_PATH=%BASE_CONFIG%
            ) else (
                set CLEAN_AFTER_EXPORT=1
                call %~dp0cf2ib.cmd "%BASE_CONFIG%" "%IB_PATH%"
            )
        )
    )
)

echo Clear temporary files...
IF "%CLEAN_AFTER_EXPORT%" equ "1" (
    rd /S /Q "%IB_PATH%"
)
md "%DP_BIN_PATH%"

echo Import dataprocessors ^& reports from folder "%DP_SRC_PATH%" to 1C:Designer format "%DP_BIN_PATH%" using infobase "%IB_PATH%" with %BASE_CONFIG_DESCRIPTION%...
FOR /f %%f IN ('dir /b /a-d "%DP_SRC_PATH%\*.xml"') DO (
    FOR %%i IN (%%~nf) DO (
        echo Building %%~ni...
        %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /LoadExternalDataProcessorOrReportFromFiles "%DP_SRC_PATH%\%%~ni.xml" "%DP_BIN_PATH%"
    )
)

echo Clear temporary files...
IF "%CLEAN_AFTER_EXPORT%" equ "1" (
    rd /S /Q "%IB_PATH%"
)

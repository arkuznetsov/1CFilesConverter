@ECHO OFF

rem Convert (dump) 1C data processor or report from binary format (*.epf, *.erf) to 1C:EDT format
rem %1 - path to 1C data processor or report (*.epf, *.erf)
rem %2 - path to folder to save data processor & report in 1C:EDT format
rem %3 - path to 1C configuration (binary (*.cf), 1C:Designer XML format or 1C:EDT format)
rem      or folder contains 1C infobase used for convertion

if not defined V8_VERSION set V8_VERSION=8.3.20.2290

set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
    set RING_TOOL="%%i"
)

set IB_PATH=%TEMP%\1c\tmp_db
set XML_PATH=%TEMP%\1c\tmp_xml
set WS_PATH=%TEMP%\1c\edt_ws
set CLEAN_AFTER_EXPORT=0

set DP_FILE=%1
if defined DP_FILE set DP_FILE=%DP_FILE:"=%
set DP_PATH=%2
if defined DP_PATH set DP_PATH=%DP_PATH:"=%
set BASE_CONFIG=%3
if defined BASE_CONFIG set BASE_CONFIG=%BASE_CONFIG:"=%

if not defined DP_FILE (
    echo Missed parameter 1 "path to 1C data processor or report (*.epf, *.erf)"
    exit /b 1
)
if not defined DP_PATH (
    echo Missed parameter 2 "path to folder to save data processor & report in 1C:EDT format"
    exit /b 1
)

md "%DP_PATH%"

echo Set infobase for export data processor/report...
IF "%BASE_CONFIG%" equ "" (
    echo Creating infobase "%IB_PATH%"...
    set CLEAN_AFTER_EXPORT=1
    set BASE_CONFIG_DESCRIPTION=empty configuration
    %V8_TOOL% CREATEINFOBASE File=%IB_PATH%; /DisableStartupDialogs
) else (
    set BASE_CONFIG_DESCRIPTION=configuration from "%BASE_CONFIG%"
    IF exist "%BASE_CONFIG%\src\Configuration\Configuration.mdo" (
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
if exist "%XML_PATH%" (
    rd /S /Q "%XML_PATH%"
)
if exist "%WS_PATH%" (
    rd /S /Q "%WS_PATH%"
)
if exist "%DP_SRC_PATH%" (
    rd /S /Q "%DP_SRC_PATH%"
)
md "%TEMP%\1c"
md "%XML_PATH%"
md "%WS_PATH%"
md %DP_SRC_PATH%

echo Export dataprocessor / report "%DP_FILE%" to 1C:Designer XML format "%XML_PATH%" using infobase "%IB_PATH%" with %BASE_CONFIG_DESCRIPTION%...
%V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /DumpExternalDataProcessorOrReportToFiles "%XML_PATH%" "%DP_FILE%"

echo Export dataprocessor / report from 1C:Designer XML format "%XML_PATH%" to 1C:EDT format "%DP_SRC_PATH%"...
call %RING_TOOL% edt workspace import --project "%DP_SRC_PATH%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%" --version "%V8_VERSION%"

echo Clear temporary files...
IF "%CLEAN_AFTER_EXPORT%" equ "1" (
    rd /S /Q "%IB_PATH%"
)
rd /S /Q "%XML_PATH%"
rd /S /Q "%WS_PATH%"

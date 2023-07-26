@ECHO OFF

rem Convert (load) all 1C data processors & reports in folder from 1C:Designer XML format to binary format (*.epf, *.erf)
rem %1 - path to folder contains 1C data processors & reports in 1C:Designer XML format or EDT format
rem      or path to main xml-file of data processor or report
rem %2 - path to folder to save data processors & reports in binary format (*.epf, *.erf)
rem %3 - path to 1C configuration (binary (*.cf), 1C:Designer XML format or 1C:EDT format)
rem      or folder contains 1C infobase used for convertion

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290
IF not defined V8_TEMP set V8_TEMP=%TEMP%\1c

set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
IF not defined V8_RING_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
        set V8_RING_TOOL="%%i"
    )
)

set IB_PATH=%V8_TEMP%\tmp_db
set XML_PATH=%V8_TEMP%\tmp_xml
set WS_PATH=%V8_TEMP%\edt_ws

set DP_SOURCE=%1
IF defined DP_SOURCE set DP_SOURCE=%DP_SOURCE:"=%
set DP_SOURCE_PATH=%~dp1
set DP_DEST_PATH=%2
IF defined DP_DEST_PATH set DP_DEST_PATH=%DP_DEST_PATH:"=%
set BASE_CONFIG=%3
IF defined BASE_CONFIG set BASE_CONFIG=%BASE_CONFIG:"=%

IF not defined DP_SOURCE (
    echo Missed parameter 1 "path to folder contains 1C data processors & reports in 1C:Designer XML or 1C:EDT project format or path to main xml-file of data processor or report"
    exit /b 1
)
IF not defined DP_DEST_PATH (
    echo Missed parameter 2 "path to folder to save data processors & reports in binary format (*.epf, *.erf)"
    exit /b 1
)
IF not exist "%BASE_CONFIG%" (
    echo Path "%BASE_CONFIG%" doesn't exist ^(parameter 3^), empty infobase will be used.
    set BASE_CONFIG=
)

echo Clear temporary files...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"
md "%V8_TEMP%"
IF not exist "%DP_DEST_PATH%" md "%DP_DEST_PATH%"

echo Set infobase for export data processor/report...
set BASE_CONFIG_DESCRIPTION=configuration from "%BASE_CONFIG%"

IF "%BASE_CONFIG%" equ "" (
    md "%IB_PATH%"
    echo Creating infobase "%IB_PATH%"...
    set BASE_CONFIG_DESCRIPTION=empty configuration
    %V8_TOOL% CREATEINFOBASE File=%IB_PATH%; /DisableStartupDialogs
    goto export
)
IF /i "%BASE_CONFIG:~-3%" equ ".cf" (
    echo Basic config source type: Configuration file ^(CF^)
    md "%IB_PATH%"
    call %~dp0conf2ib.cmd "%BASE_CONFIG%" "%IB_PATH%"
    goto export
)
IF exist "%BASE_CONFIG%\DT-INF\" (
    echo Basic config source type: 1C:EDT project
    md "%IB_PATH%"
    call %~dp0conf2ib.cmd "%BASE_CONFIG%" "%IB_PATH%" designer
    goto export
)
IF exist "%BASE_CONFIG%\Configuration.xml" (
    echo Basic config source type: 1C:Designer XML files
    md "%IB_PATH%"
    call %~dp0conf2ib.cmd "%BASE_CONFIG%" "%IB_PATH%" designer
    goto export
)
IF exist "%BASE_CONFIG%\1cv8.1cd" (
    echo Basic config source type: Infobase
    set BASE_CONFIG_DESCRIPTION=existed configuration
    set IB_PATH=%BASE_CONFIG%
    goto export
)

echo Error cheking type of basic configuration "%BASE_CONFIG%"!
echo Infobase, configuration file (*.cf), 1C:Designer XML, 1C:EDT project or no configuration expected.
exit /b 1

:export

echo Checking data processord ^& reports source type...

set DP_SOURCE_IS_EDT=0

IF exist "%DP_SOURCE%\DT-INF\" (
    IF exist "%DP_SOURCE%\src\ExternalDataProcessors\" set DP_SOURCE_IS_EDT=1
    IF exist "%DP_SOURCE%\src\ExternalReports\" set DP_SOURCE_IS_EDT=1
)
IF "%DP_SOURCE_IS_EDT%" equ "1" (
    echo Source type: 1C:EDT project
    echo Export "%EDT_PATH%" to 1C:Designer XML format "%DP_DEST_PATH%"...
    md "%WS_PATH%"
    md "%XML_PATH%"
    goto export_edt
)
FOR /f %%f IN ('dir /b /a-d "%DP_SOURCE%\*.xml"') DO (
    echo Source type: 1C:Designer XML files folder ^(external data processors ^& reports^)
    set XML_PATH=%DP_SOURCE%
    goto export_xml
)
IF /i "%DP_SOURCE:~-4%" equ ".xml" (
    echo Source type: 1C:Designer XML files ^(external data processor or report^)
    set XML_PATH=%DP_SOURCE_PATH%
    goto export_xml
)

echo Wrong path "%DP_SOURCE%"!
echo Folder containing external data processors ^& reports in XML format or 1C:EDT project or path to main xml-file of data processor or report expected.
exit /b 1

:export_edt

echo Export external data processors ^& reports from 1C:EDT format "%DP_SOURCE%" to 1C:Designer XML format "%XML_PATH%"...
call %V8_RING_TOOL% edt workspace export --project "%DP_SOURCE%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%"

:export_xml

IF "%DP_SOURCE_IS_EDT%" equ "1" (
    echo Import external data processors from "%XML_PATH%" to 1C:Designer format "%DP_DEST_PATH%" using infobase "%IB_PATH%" with %BASE_CONFIG_DESCRIPTION%...
    FOR /f %%f IN ('dir /b /a-d "%XML_PATH%\ExternalDataProcessors\*.xml"') DO (
        echo Building %%~nf...
        %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /LoadExternalDataProcessorOrReportFromFiles "%XML_PATH%\ExternalDataProcessors\%%~nxf" "%DP_DEST_PATH%"
    )
    echo Import external reports from "%XML_PATH%" to 1C:Designer format "%DP_DEST_PATH%" using infobase "%IB_PATH%" with %BASE_CONFIG_DESCRIPTION%...
    FOR /f %%f IN ('dir /b /a-d "%XML_PATH%\ExternalReports\*.xml"') DO (
        echo Building %%~nf...
        %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /LoadExternalDataProcessorOrReportFromFiles "%XML_PATH%\ExternalReports\%%~nxf" "%DP_DEST_PATH%"
    )
) ELSE (
    echo Import external datap processors ^& reports from "%XML_PATH%" to 1C:Designer format "%DP_DEST_PATH%" using infobase "%IB_PATH%" with %BASE_CONFIG_DESCRIPTION%...
    FOR /f %%f IN ('dir /b /a-d "%XML_PATH%\*.xml"') DO (
        echo Building %%~nf...
        %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /LoadExternalDataProcessorOrReportFromFiles "%XML_PATH%\%%~nxf" "%DP_DEST_PATH%"
    )
)
echo Clear temporary files...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"

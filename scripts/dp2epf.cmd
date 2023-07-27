@ECHO OFF

echo Convert 1C external data processors ^& reports to binary format ^(*.epf, *.erf^)

set ERROR_CODE=0

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290
IF not defined V8_TEMP set V8_TEMP=%TEMP%\1c

set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
IF not defined V8_RING_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
        set V8_RING_TOOL="%%i"
    )
)

set LOCAL_TEMP=%V8_TEMP%\%~n0
set IB_PATH=%LOCAL_TEMP%\tmp_db
set XML_PATH=%LOCAL_TEMP%\tmp_xml
set WS_PATH=%LOCAL_TEMP%\edt_ws

set DP_SOURCE=%1
IF defined DP_SOURCE set DP_SOURCE=%DP_SOURCE:"=%
set DP_SOURCE_PATH=%~dp1
set DP_DEST_PATH=%2
IF defined DP_DEST_PATH set DP_DEST_PATH=%DP_DEST_PATH:"=%
set BASE_CONFIG=%3
IF defined BASE_CONFIG set BASE_CONFIG=%BASE_CONFIG:"=%

IF not defined DP_SOURCE (
    echo [ERROR] Missed parameter 1 - "path to folder contains 1C data processors & reports in 1C:Designer XML or 1C:EDT project format or path to main xml-file of data processor or report"
    set ERROR_CODE=1
) ELSE (
    IF not exist "%DP_SOURCE%" (
        echo [ERROR] Path "%DP_SOURCE%" doesn't exist ^(parameter 1^).
        set ERROR_CODE=1
    )
)
IF not defined DP_DEST_PATH (
    echo [ERROR] Missed parameter 2 - "path to folder to save data processors & reports in binary format (*.epf, *.erf)"
    set ERROR_CODE=1
)
IF not exist "%BASE_CONFIG%" (
    echo [INFO] Path "%BASE_CONFIG%" doesn't exist ^(parameter 3^), empty infobase will be used.
    set BASE_CONFIG=
)
IF %ERROR_CODE% neq 0 (
    echo ===
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - path to folder contains 1C data processors ^& reports in 1C:Designer XML format or EDT format
    echo           or path to main xml-file of data processor or report
    echo     %%2 - path to folder to save data processors ^& reports in binary format ^(*.epf, *.erf^)"
    echo     %%3 - ^(optional^) path to 1C configuration ^(binary ^(*.cf^), 1C:Designer XML format or 1C:EDT project^)
    echo           or folder contains 1C infobase used for convertion
    echo.
    exit /b %ERROR_CODE%
)

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"
md "%LOCAL_TEMP%"
IF not exist "%DP_DEST_PATH%" md "%DP_DEST_PATH%"

echo [INFO] Set infobase for export data processor/report...

set BASE_CONFIG_DESCRIPTION=configuration from "%BASE_CONFIG%"

IF "%BASE_CONFIG%" equ "" (
    md "%IB_PATH%"
    echo [INFO] Creating infobase "%IB_PATH%"...
    set BASE_CONFIG_DESCRIPTION=empty configuration
    %V8_TOOL% CREATEINFOBASE File=%IB_PATH%; /DisableStartupDialogs
    goto export
)
IF exist "%BASE_CONFIG%\1cv8.1cd" (
    echo [INFO] Basic config source type: Infobase
    set BASE_CONFIG_DESCRIPTION=existed configuration
    set IB_PATH=%BASE_CONFIG%
    goto export
)
md "%IB_PATH%"
call %~dp0conf2ib.cmd "%BASE_CONFIG%" "%IB_PATH%"
IF ERRORLEVEL 0 goto export

echo [ERROR] Error cheking type of basic configuration "%BASE_CONFIG%"!
echo Infobase, configuration file ^(*.cf^), 1C:Designer XML, 1C:EDT project or no configuration expected.
exit /b 1

:export

echo [INFO] Checking data processord ^& reports source type...

set DP_SOURCE_IS_EDT=0

IF exist "%DP_SOURCE%\DT-INF\" (
    IF exist "%DP_SOURCE%\src\ExternalDataProcessors\" set DP_SOURCE_IS_EDT=1
    IF exist "%DP_SOURCE%\src\ExternalReports\" set DP_SOURCE_IS_EDT=1
)
IF "%DP_SOURCE_IS_EDT%" equ "1" (
    echo [INFO] Source type: 1C:EDT project
    goto export_edt
)
FOR /f %%f IN ('dir /b /a-d "%DP_SOURCE%\*.xml"') DO (
    echo [INFO] Source type: 1C:Designer XML files folder ^(external data processors ^& reports^)
    set XML_PATH=%DP_SOURCE%
    goto export_xml
)
IF /i "%DP_SOURCE:~-4%" equ ".xml" (
    echo [INFO] Source type: 1C:Designer XML files ^(external data processor or report^)
    set XML_PATH=%DP_SOURCE_PATH%
    goto export_xml
)

echo [ERROR] Wrong path "%DP_SOURCE%"!
echo Folder containing external data processors ^& reports in XML format or 1C:EDT project or path to main xml-file of data processor or report expected.
exit /b 1

:export_edt

echo [INFO] Export external data processors ^& reports from 1C:EDT format "%DP_SOURCE%" to 1C:Designer XML format "%XML_PATH%"...

md "%XML_PATH%"
md "%WS_PATH%"

call %V8_RING_TOOL% edt workspace export --project "%DP_SOURCE%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%"

:export_xml

IF "%DP_SOURCE_IS_EDT%" equ "1" (
    echo [INFO] Import external data processors from "%XML_PATH%" to 1C:Designer format "%DP_DEST_PATH%" using infobase "%IB_PATH%" with %BASE_CONFIG_DESCRIPTION%...
    FOR /f %%f IN ('dir /b /a-d "%XML_PATH%\ExternalDataProcessors\*.xml"') DO (
        echo [INFO] Building %%~nf...
        %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /LoadExternalDataProcessorOrReportFromFiles "%XML_PATH%\ExternalDataProcessors\%%~nxf" "%DP_DEST_PATH%"
    )
    echo [INFO] Import external reports from "%XML_PATH%" to 1C:Designer format "%DP_DEST_PATH%" using infobase "%IB_PATH%" with %BASE_CONFIG_DESCRIPTION%...
    FOR /f %%f IN ('dir /b /a-d "%XML_PATH%\ExternalReports\*.xml"') DO (
        echo [INFO] Building %%~nf...
        %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /LoadExternalDataProcessorOrReportFromFiles "%XML_PATH%\ExternalReports\%%~nxf" "%DP_DEST_PATH%"
    )
) ELSE (
    echo [INFO] Import external datap processors ^& reports from "%XML_PATH%" to 1C:Designer format "%DP_DEST_PATH%" using infobase "%IB_PATH%" with %BASE_CONFIG_DESCRIPTION%...
    FOR /f %%f IN ('dir /b /a-d "%XML_PATH%\*.xml"') DO (
        echo [INFO] Building %%~nf...
        %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /LoadExternalDataProcessorOrReportFromFiles "%XML_PATH%\%%~nxf" "%DP_DEST_PATH%"
    )
)

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"

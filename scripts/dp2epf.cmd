@ECHO OFF

SETLOCAL

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
    echo [ERROR] Missed parameter 1 - "path to folder contains 1C data processors & reports in 1C:Designer XML or 1C:EDT project format or path to main xml-file of data processor or report"
    set ERROR_CODE=1
) ELSE (
    IF not exist "%V8_SRC_PATH%" (
        echo [ERROR] Path "%V8_SRC_PATH%" doesn't exist ^(parameter 1^).
        set ERROR_CODE=1
    )
)
IF not defined V8_DST_PATH (
    echo [ERROR] Missed parameter 2 - "path to folder to save data processors & reports in binary format (*.epf, *.erf)"
    set ERROR_CODE=1
)
IF not exist "%V8_BASE_CONFIG%" (
    echo [INFO] Path "%V8_BASE_CONFIG%" doesn't exist ^(parameter 3^), empty infobase will be used.
    set V8_BASE_CONFIG=
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
IF not exist "%V8_DST_PATH%" md "%V8_DST_PATH%"

echo [INFO] Set infobase for export data processor/report...

set BASE_CONFIG_DESCRIPTION=configuration from "%V8_BASE_CONFIG%"

IF "%V8_BASE_CONFIG%" equ "" (
    md "%IB_PATH%"
    echo [INFO] Creating infobase "%IB_PATH%"...
    set BASE_CONFIG_DESCRIPTION=empty configuration
    %V8_TOOL% CREATEINFOBASE File=%IB_PATH%; /DisableStartupDialogs
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

set V8_SRC_IS_EDT=0

IF exist "%V8_SRC_PATH%\DT-INF\" (
    IF exist "%V8_SRC_PATH%\src\ExternalDataProcessors\" set V8_SRC_IS_EDT=1
    IF exist "%V8_SRC_PATH%\src\ExternalReports\" set V8_SRC_IS_EDT=1
)
IF "%V8_SRC_IS_EDT%" equ "1" (
    echo [INFO] Source type: 1C:EDT project
    goto export_edt
)
FOR /f %%f IN ('dir /b /a-d "%V8_SRC_PATH%\*.xml"') DO (
    echo [INFO] Source type: 1C:Designer XML files folder ^(external data processors ^& reports^)
    set V8_SRC_MASK="%V8_SRC_PATH%\*.xml"
    set XML_PATH=%V8_SRC_PATH%
    goto export_xml
)
IF /i "%V8_SRC_PATH:~-4%" equ ".xml" (
    echo [INFO] Source type: 1C:Designer XML files ^(external data processor or report^)
    set V8_SRC_MASK="%V8_SRC_PATH%"
    set XML_PATH=%V8_SRC_FOLDER%
    goto export_xml
)

echo [ERROR] Wrong path "%V8_SRC_PATH%"!
echo Folder containing external data processors ^& reports in XML format or 1C:EDT project or path to main xml-file of data processor or report expected.
exit /b 1

:export_edt

echo [INFO] Export external data processors ^& reports from 1C:EDT format "%V8_SRC_PATH%" to 1C:Designer XML format "%XML_PATH%"...

md "%XML_PATH%"
md "%WS_PATH%"

call %V8_RING_TOOL% edt workspace export --project "%V8_SRC_PATH%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%"

:export_xml

IF "%V8_SRC_IS_EDT%" equ "1" (
    echo [INFO] Import external data processors from "%XML_PATH%" to 1C:Designer format "%V8_DST_PATH%" using infobase "%IB_PATH%" with %BASE_CONFIG_DESCRIPTION%...
    FOR /f %%f IN ('dir /b /a-d "%XML_PATH%\ExternalDataProcessors\*.xml"') DO (
        echo [INFO] Building %%~nf...
        %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /LoadExternalDataProcessorOrReportFromFiles "%XML_PATH%\ExternalDataProcessors\%%~nxf" "%V8_DST_PATH%"
    )
    echo [INFO] Import external reports from "%XML_PATH%" to 1C:Designer format "%V8_DST_PATH%" using infobase "%IB_PATH%" with %BASE_CONFIG_DESCRIPTION%...
    FOR /f %%f IN ('dir /b /a-d "%XML_PATH%\ExternalReports\*.xml"') DO (
        echo [INFO] Building %%~nf...
        %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /LoadExternalDataProcessorOrReportFromFiles "%XML_PATH%\ExternalReports\%%~nxf" "%V8_DST_PATH%"
    )
) ELSE (
    echo [INFO] Import external datap processors ^& reports from "%XML_PATH%" to 1C:Designer format "%V8_DST_PATH%" using infobase "%IB_PATH%" with %BASE_CONFIG_DESCRIPTION%...
    FOR /f %%f IN ('dir /b /a-d %V8_SRC_MASK%') DO (
        echo [INFO] Building %%~nf...
        %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /LoadExternalDataProcessorOrReportFromFiles "%XML_PATH%\%%~nxf" "%V8_DST_PATH%"
    )
)

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"

@ECHO OFF

rem Load 1C configuration from files in 1C:EDT format to 1C infobase (file)
rem %1 - path to folder contains 1C configuration files in 1C:EDT format
rem %2 - path to folder contains 1C infobase
rem %3 - convertion tool to use:
rem      ibcmd - ibcmd tool (default)
rem      designer - batch run of 1C:Designer

if not defined V8_VERSION set V8_VERSION=8.3.20.2290
if not defined V8_TEMP set V8_TEMP=%TEMP%\1c

set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
set IBCMD_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\ibcmd.exe"
FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
    set RING_TOOL="%%i"
)

set XML_PATH=%V8_TEMP%\tmp_xml
set WS_PATH=%V8_TEMP%\edt_ws

set CONFIG_PATH=%1
if defined CONFIG_PATH set CONFIG_PATH=%CONFIG_PATH:"=%
set IB_PATH=%2
if defined IB_PATH set IB_PATH=%IB_PATH:"=%
set CONV_TOOL=%3
if defined CONV_TOOL (
    set CONV_TOOL=%CONV_TOOL:"=%
) else set CONV_TOOL=ibcmd

if not defined CONFIG_PATH (
    echo Missed parameter 1 "path to folder contains configuration files in 1C:EDT format"
    exit /b 1
)
if not defined IB_PATH (
    echo Missed parameter 2 "path to folder contains 1C infobase"
    exit /b 1
)

echo Clear temporary files...
if exist "%XML_PATH%" (
    rd /S /Q "%XML_PATH%"
)
if exist "%WS_PATH%" (
    rd /S /Q "%WS_PATH%"
)
md "%V8_TEMP%"
md "%XML_PATH%"
md "%WS_PATH%"

echo Export "%CONFIG_PATH%" to 1C:Designer XML format "%XML_PATH%"...
call %RING_TOOL% edt workspace export --project "%CONFIG_PATH%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%"

echo Clear infobase folder "%IB_PATH%"...
if exist "%IB_PATH%" (
    rd /S /Q "%IB_PATH%"
)

if "%CONV_TOOL%" equ "designer" (
    echo Creating infobase "%IB_PATH%"...
    %V8_TOOL% CREATEINFOBASE File=%IB_PATH%; /DisableStartupDialogs

    echo Loading infobase "%IB_PATH%" configuration from XML-files "%XML_PATH%"...
    %V8_TOOL% DESIGNER /IBConnectionString File=%IB_PATH%; /DisableStartupDialogs /LoadConfigFromFiles %XML_PATH%
) else (
    echo Creating infobase "%IB_PATH%" with configuration from XML-files "%XML_PATH%"...
    %IBCMD_TOOL% infobase create --db-path="%IB_PATH%" --create-database --import="%XML_PATH%"
)

echo Clear temporary files...
if exist "%XML_PATH%" (
    rd /S /Q "%XML_PATH%"
)
if exist "%WS_PATH%" (
    rd /S /Q "%WS_PATH%"
)

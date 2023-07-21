@ECHO OFF

rem Convert (dump) 1C configuration file (*.cf) to 1C:EDT format
rem %1 - path to 1C configuration file (*.cf)
rem %2 - path to folder to save configuration files in 1C:EDT format
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

set IB_PATH=%V8_TEMP%\tmp_db
set XML_PATH=%V8_TEMP%\tmp_xml
set WS_PATH=%V8_TEMP%\edt_ws

set CONFIG_FILE=%1
if defined CONFIG_FILE set CONFIG_FILE=%CONFIG_FILE:"=%
set CONFIG_PATH=%2
if defined CONFIG_PATH set CONFIG_PATH=%CONFIG_PATH:"=%
set CONV_TOOL=%3
if defined CONV_TOOL (
    set CONV_TOOL=%CONV_TOOL:"=%
) else set CONV_TOOL=ibcmd

if not defined CONFIG_FILE (
    echo Missed parameter 1 "path to 1C configuration file"
    exit /b 1
)
if not defined CONFIG_PATH (
    echo Missed parameter 2 "path to folder to save configuration files in 1C:EDT format"
    exit /b 1
)

echo Clear temporary files...
if exist "%IB_PATH%" (
    rd /S /Q "%IB_PATH%"
)
if exist "%XML_PATH%" (
    rd /S /Q "%XML_PATH%"
)
if exist "%WS_PATH%" (
    rd /S /Q "%WS_PATH%"
)
if exist "%CONFIG_PATH%" (
    rd /S /Q "%CONFIG_PATH%"
)
md "%CONFIG_PATH%"

echo Creating infobase "%IB_PATH%" from file "%CONFIG_FILE%"...
if "%CONV_TOOL%" equ "designer" (
    %V8_TOOL% CREATEINFOBASE File="%IB_PATH%"; /DisableStartupDialogs /UseTemplate "%CONFIG_FILE%"
) else (
    %IBCMD_TOOL% infobase create --db-path="%IB_PATH%" --create-database --load="%CONFIG_FILE%"
)

echo Export configuration from infobase "%IB_PATH%" to 1C:Designer XML format "%XML_PATH%"...
if "%CONV_TOOL%" equ "designer" (
    %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /DumpConfigToFiles "%XML_PATH%" -force
) else (
    %IBCMD_TOOL% infobase config export --db-path="%IB_PATH%" "%XML_PATH%" --force
)

echo Export configuration from "%XML_PATH%" to 1C:EDT format "%CONFIG_PATH%"...
call %RING_TOOL% edt workspace import --project "%CONFIG_PATH%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%" --version "%V8_VERSION%"

echo Clear temporary files...
rd /S /Q "%IB_PATH%"
rd /S /Q "%XML_PATH%"
rd /S /Q "%WS_PATH%"

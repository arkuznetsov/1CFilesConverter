@ECHO OFF

rem Convert 1C configuration from 1C:EDT format to 1C:Designer XML format
rem %1 - path to folder contains configuration files in 1C:EDT format
rem %2 - path to folder to save configuration files in 1C:Designer XML format

if not defined V8_TEMP set V8_TEMP=%TEMP%\1c

FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
    set RING_TOOL="%%i"
)

set IB_PATH=%V8_TEMP%\tmp_db
set WS_PATH=%V8_TEMP%\edt_ws

set EDT_PATH=%1
if defined EDT_PATH set EDT_PATH=%EDT_PATH:"=%
set CONFIG_PATH=%2
if defined CONFIG_PATH set CONFIG_PATH=%CONFIG_PATH:"=%

if not defined EDT_PATH (
    echo Missed parameter 1 "path to folder contains configuration files in 1C:EDT format"
    exit /b 1
)
if not defined CONFIG_PATH (
    echo Missed parameter 2 "path to folder to save configuration files in 1C:Designer XML format"
    exit /b 1
)

echo Clear temporary files...
if exist "%IB_PATH%" (
    rd /S /Q "%IB_PATH%"
)
if exist "%WS_PATH%" (
    rd /S /Q "%WS_PATH%"
)
if exist "%CONFIG_PATH%" (
    rd /S /Q "%CONFIG_PATH%"
)
md "%CONFIG_PATH%"

echo Export "%EDT_PATH%" to 1C:Designer XML format "%CONFIG_PATH%"...
call %RING_TOOL% edt workspace export --project "%EDT_PATH%" --configuration-files "%CONFIG_PATH%" --workspace-location "%WS_PATH%"

echo Clear temporary files...
if exist "%IB_PATH%" (
    rd /S /Q "%IB_PATH%"
)
if exist "%WS_PATH%" (
    rd /S /Q "%WS_PATH%"
)

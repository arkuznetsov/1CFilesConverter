@ECHO OFF

rem Convert 1C configuration from 1C:Designer XML format to 1C:EDT format
rem %1 - path to folder contains configuration files in 1C:Designer XML format
rem %2 - path to folder to save configuration files in 1C:EDT format

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290
IF not defined V8_TEMP set V8_TEMP=%TEMP%\1c

set IB_PATH=%V8_TEMP%\tmp_db
set WS_PATH=%V8_TEMP%\edt_ws

set CONFIG_PATH=%1
IF defined CONFIG_PATH set CONFIG_PATH=%CONFIG_PATH:"=%
set EDT_PATH=%2
IF defined EDT_PATH set EDT_PATH=%EDT_PATH:"=%

IF not defined CONFIG_PATH (
    echo Missed parameter 1 "path to folder contains configuration files in 1C:Designer XML format"
    exit /b 1
)
IF not defined EDT_PATH (
    echo Missed parameter 2 "path to folder to save configuration files in 1C:EDT format"
    exit /b 1
)

echo Clear temporary files...
IF exist "%IB_PATH%" rd /S /Q "%IB_PATH%"
IF exist "%WS_PATH%" rd /S /Q "%WS_PATH%"
IF exist "%EDT_PATH%" rd /S /Q "%EDT_PATH%"
md "%EDT_PATH%"

echo Export "%CONFIG_PATH%" to 1C:EDT format "%EDT_PATH%"...
call %RING_TOOL% edt workspace import --project "%EDT_PATH%" --configuration-files "%CONFIG_PATH%" --workspace-location "%WS_PATH%" --version "%V8_VERSION%"

echo Clear temporary files...
IF exist "%IB_PATH%" rd /S /Q "%IB_PATH%"
IF exist "%WS_PATH%" rd /S /Q "%WS_PATH%"

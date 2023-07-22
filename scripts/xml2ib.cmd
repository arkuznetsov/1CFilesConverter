@ECHO OFF

rem Load 1C configuration from files in 1C:Designer XML format to 1C infobase (file)
rem %1 - path to folder contains 1C configuration files in 1C:Designer XML format
rem %2 - path to folder contains 1C infobase
rem %3 - convertion tool to use:
rem      ibcmd - ibcmd tool (default)
rem      designer - batch run of 1C:Designer

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290

set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
set IBCMD_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\ibcmd.exe"

set CONFIG_PATH=%1
IF defined CONFIG_PATH set CONFIG_PATH=%CONFIG_PATH:"=%
set IB_PATH=%2
IF defined IB_PATH set IB_PATH=%IB_PATH:"=%
set CONV_TOOL=%3
IF defined CONV_TOOL (
    set CONV_TOOL=%CONV_TOOL:"=%
) ELSE set CONV_TOOL=ibcmd

IF not defined CONFIG_PATH (
    echo Missed parameter 1 "path to folder contains configuration files in 1C:Designer XML format"
    exit /b 1
)
IF not defined IB_PATH (
    echo Missed parameter 2 "path to folder contains 1C infobase"
    exit /b 1
)

echo Clear infobase folder "%IB_PATH%"...
IF exist "%IB_PATH%" rd /S /Q "%IB_PATH%"

IF "%CONV_TOOL%" equ "designer" (
    echo Creating infobase "%IB_PATH%"...
    %V8_TOOL% CREATEINFOBASE File=%IB_PATH%; /DisableStartupDialogs

    echo Loading infobase "%IB_PATH%" configuration from XML-files "%CONFIG_PATH%"...
    %V8_TOOL% DESIGNER /IBConnectionString File=%IB_PATH%; /DisableStartupDialogs /LoadConfigFromFiles %CONFIG_PATH%
) ELSE (
    echo Creating infobase "%IB_PATH%" from XML files "%CONFIG_PATH%"...
    %IBCMD_TOOL% infobase create --db-path="%IB_PATH%" --create-database --import="%CONFIG_PATH%"
)

@ECHO OFF

rem Save 1C configuration from 1C infobase (file) to 1C configuration file (*.cf)
rem %1 - path to folder contains 1C infobase
rem %2 - path to 1C configuration file (*.cf)
rem %3 - convertion tool to use:
rem      ibcmd - ibcmd tool (default)
rem      designer - batch run of 1C:Designer

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290

set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
set IBCMD_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\ibcmd.exe"

set IB_PATH=%1
IF defined IB_PATH set IB_PATH=%IB_PATH:"=%
set CONFIG_FILE=%2
IF defined CONFIG_FILE (
    set CONFIG_FILE=%CONFIG_FILE:"=%
    set CONFIG_FILE_PATH=%~dp2
)
set CONV_TOOL=%3
IF defined CONV_TOOL (
    set CONV_TOOL=%CONV_TOOL:"=%
) ELSE set CONV_TOOL=ibcmd

IF not defined IB_PATH (
    echo Missed parameter 1 "path to folder contains 1C infobase"
    exit /b 1
)
IF not defined CONFIG_FILE (
    echo Missed parameter 2 "path to 1C configuration file (*.cf)"
    exit /b 1
)

md "%CONFIG_FILE_PATH%"

echo Export infobase "%IB_PATH%" configuration to "%CONFIG_FILE%"...
IF "%CONV_TOOL%" equ "designer" (
    %V8_TOOL% DESIGNER /IBConnectionString File=%IB_PATH%; /DisableStartupDialogs /DumpCfg %CONFIG_FILE%
) ELSE (
    %IBCMD_TOOL% infobase config save --db-path="%IB_PATH%" "%CONFIG_FILE%"
)

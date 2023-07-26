@ECHO OFF

rem Convert (load) 1C configuration from 1C:EDT format to 1C configuration file (*.cf)
rem %1 - path to 1C configuration source (infobase, 1C:Designer XML files or 1C:EDT project)
rem %2 - path to 1C configuration file (*.cf)
rem %3 - convertion tool to use:
rem      ibcmd - ibcmd tool (default)
rem      designer - batch run of 1C:Designer

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290
IF not defined V8_TEMP set V8_TEMP=%TEMP%\1c

set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
set IBCMD_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\ibcmd.exe"
IF not defined V8_RING_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
        set V8_RING_TOOL="%%i"
    )
)

set IB_PATH=%V8_TEMP%\tmp_db
set XML_PATH=%V8_TEMP%\tmp_xml
set WS_PATH=%V8_TEMP%\edt_ws

set CONFIG_SOURCE=%1
IF defined CONFIG_SOURCE set CONFIG_SOURCE=%CONFIG_SOURCE:"=%
set CONFIG_FILE=%2
IF defined CONFIG_FILE (
    set CONFIG_FILE=%CONFIG_FILE:"=%
    set CONFIG_FILE_PATH=%~dp2
)
set CONV_TOOL=%3
IF defined CONV_TOOL (
    set CONV_TOOL=%CONV_TOOL:"=%
) ELSE set CONV_TOOL=ibcmd

IF not defined CONFIG_SOURCE (
    echo Missed parameter 1 "path to 1C configuration source (infobase, 1C:Designer XML files or 1C:EDT project)"
    exit /b 1
)
IF not defined CONFIG_FILE (
    echo Missed parameter 2 "path to 1C configuration file (*.cf)"
    exit /b 1
)

echo Clear temporary files...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"
md "%V8_TEMP%"
md "%IB_PATH%"
md "%XML_PATH%"
md "%WS_PATH%"
IF not exist "%CONFIG_FILE_PATH%" md "%CONFIG_FILE_PATH%"

echo Checking configuration source type...

IF exist "%CONFIG_SOURCE%\DT-INF\" (
    echo Source type: 1C:EDT project
    goto export_edt
)
IF exist "%CONFIG_SOURCE%\Configuration.xml" (
    echo Source type: 1C:Designer XML files
    set XML_PATH=%CONFIG_SOURCE%
    goto export_xml
)
IF exist "%CONFIG_SOURCE%\1cv8.1cd" (
    echo Source type: Infobase
    set IB_PATH=%CONFIG_SOURCE%
    goto export_ib
)

echo Error cheking type of configuration "%CONFIG_SOURCE%"!
echo Infobase, 1C:Designer XML files or 1C:EDT project expected.
exit /b 1

:export_edt

echo Export "%CONFIG_SOURCE%" to 1C:Designer XML format "%XML_PATH%"...
call %V8_RING_TOOL% edt workspace export --project "%CONFIG_SOURCE%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%"

:export_xml

IF "%CONV_TOOL%" equ "designer" (
    echo Creating infobase "%IB_PATH%"...
    %V8_TOOL% CREATEINFOBASE File=%IB_PATH%; /DisableStartupDialogs

    echo Loading infobase "%IB_PATH%" configuration from XML-files "%XML_PATH%"...
    %V8_TOOL% DESIGNER /IBConnectionString File=%IB_PATH%; /DisableStartupDialogs /LoadConfigFromFiles %XML_PATH%
) ELSE (
    echo Creating infobase "%IB_PATH%" with configuration from XML-files "%XML_PATH%"...
    %IBCMD_TOOL% infobase create --db-path="%IB_PATH%" --create-database --import="%XML_PATH%"
)

:export_ib

echo Export infobase "%IB_PATH%" configuration to "%CONFIG_FILE%"...
IF "%CONV_TOOL%" equ "designer" (
    %V8_TOOL% DESIGNER /IBConnectionString File=%IB_PATH%; /DisableStartupDialogs /DumpCfg %CONFIG_FILE%
) ELSE (
    %IBCMD_TOOL% infobase config save --db-path="%IB_PATH%" "%CONFIG_FILE%"
)

echo Clear temporary files...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"

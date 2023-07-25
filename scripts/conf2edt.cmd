@ECHO OFF

rem Convert (dump) 1C configuration file (*.cf) to 1C:EDT format
rem %1 - path to 1C configuration source (1C configuration file (*.cf), infobase or 1C:Designer XML files)
rem %2 - path to folder to save configuration files in 1C:EDT format
rem %3 - convertion tool to use:
rem      ibcmd - ibcmd tool (default)
rem      designer - batch run of 1C:Designer

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290
IF not defined V8_TEMP set V8_TEMP=%TEMP%\1c

set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
set IBCMD_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\ibcmd.exe"
FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
    set RING_TOOL="%%i"
)

set IB_PATH=%V8_TEMP%\tmp_db
set XML_PATH=%V8_TEMP%\tmp_xml
set WS_PATH=%V8_TEMP%\edt_ws

set CONFIG_SOURCE=%1
IF defined CONFIG_SOURCE set CONFIG_SOURCE=%CONFIG_SOURCE:"=%
set CONFIG_PATH=%2
IF defined CONFIG_PATH set CONFIG_PATH=%CONFIG_PATH:"=%
set CONV_TOOL=%3
IF defined CONV_TOOL (
    set CONV_TOOL=%CONV_TOOL:"=%
) ELSE set CONV_TOOL=ibcmd

IF not defined CONFIG_SOURCE (
    echo Missed parameter 1 "path to 1C configuration source (1C configuration file (*.cf), infobase or 1C:Designer XML files)"
    exit /b 1
)
IF not defined CONFIG_PATH (
    echo Missed parameter 2 "path to folder to save configuration files in 1C:EDT format"
    exit /b 1
)

echo Clear temporary files...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"
md "%V8_TEMP%"
md "%IB_PATH%"
md "%XML_PATH%"
md "%WS_PATH%"
IF exist "%CONFIG_PATH%" rd /S /Q "%CONFIG_PATH%"
md "%CONFIG_PATH%"

echo Checking configuration source type...

IF /i "%CONFIG_SOURCE:~-3%" equ ".cf" (
    echo Source type: Configuration file ^(CF^)
    goto export_cf
)
IF exist "%CONFIG_SOURCE%\1cv8.1cd" (
    echo Source type: Infobase
    set IB_PATH=%CONFIG_SOURCE%
    goto export_ib
)
IF exist "%CONFIG_SOURCE%\Configuration.xml" (
    echo Source type: 1C:Designer XML files
    set XML_PATH=%CONFIG_SOURCE%
    goto export_xml
)

echo Error cheking type of configuration "%CONFIG_SOURCE%"!
echo Infobase, configuration file (*.cf) or 1C:Designer XML files expected.
exit /b 1

:export_cf

echo Creating infobase "%IB_PATH%" from file "%CONFIG_FILE%"...
IF "%CONV_TOOL%" equ "designer" (
    %V8_TOOL% CREATEINFOBASE File="%IB_PATH%"; /DisableStartupDialogs /UseTemplate "%CONFIG_FILE%"
) ELSE (
    %IBCMD_TOOL% infobase create --db-path="%IB_PATH%" --create-database --load="%CONFIG_FILE%"
)

:export_ib

echo Export configuration from infobase "%IB_PATH%" to 1C:Designer XML format "%XML_PATH%"...
IF "%CONV_TOOL%" equ "designer" (
    %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /DumpConfigToFiles "%XML_PATH%" -force
) ELSE (
    %IBCMD_TOOL% infobase config export --db-path="%IB_PATH%" "%XML_PATH%" --force
)

:export_xml

echo Export configuration from "%XML_PATH%" to 1C:EDT format "%CONFIG_PATH%"...
call %RING_TOOL% edt workspace import --project "%CONFIG_PATH%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%" --version "%V8_VERSION%"

echo Clear temporary files...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"

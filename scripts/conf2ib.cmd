@ECHO OFF

rem Load 1C configuration file (*.cf) to 1C infobase (file)
rem %1 - path to 1C configuration source (1C configuration file (*.cf), 1C:Designer XML files or 1C:EDT project)
rem %2 - path to folder contains 1C infobase
rem %3 - convertion tool to use:
rem      ibcmd - ibcmd tool (default)
rem      designer - batch run of 1C:Designer

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290

IF not "%V8_CONVERT_TOOL%" equ "designer" IF not "%V8_CONVERT_TOOL%" equ "ibcmd" set V8_CONVERT_TOOL=designer
set V8_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\1cv8.exe"
set IBCMD_TOOL="C:\Program Files\1cv8\%V8_VERSION%\bin\ibcmd.exe"
IF not defined V8_RING_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
        set V8_RING_TOOL="%%i"
    )
)

set XML_PATH=%V8_TEMP%\tmp_xml
set WS_PATH=%V8_TEMP%\edt_ws

set CONFIG_SOURCE=%1
IF defined CONFIG_SOURCE set CONFIG_SOURCE=%CONFIG_SOURCE:"=%
set IB_PATH=%2
IF defined IB_PATH set IB_PATH=%IB_PATH:"=%

IF not defined CONFIG_SOURCE (
    echo Missed parameter 1 "path to 1C configuration source (1C configuration file (*.cf), 1C:Designer XML files or 1C:EDT project)"
    exit /b 1
)
IF not defined IB_PATH (
    echo Missed parameter 2 "path to folder contains 1C infobase"
    exit /b 1
)

echo Clear infobase folder "%IB_PATH%"...
IF exist "%IB_PATH%" rd /S /Q "%IB_PATH%"
md "%IB_PATH%"

echo Checking configuration source type...

IF /i "%CONFIG_SOURCE:~-3%" equ ".cf" (
    echo Source type: Configuration file ^(CF^)
    md "%IB_PATH%"
    echo Creating infobase "%IB_PATH%" from file "%CONFIG_SOURCE%"...
    IF "%V8_CONVERT_TOOL%" equ "designer" (
        %V8_TOOL% CREATEINFOBASE File="%IB_PATH%"; /DisableStartupDialogs /UseTemplate "%CONFIG_SOURCE%"
    ) ELSE (
        %IBCMD_TOOL% infobase create --db-path="%IB_PATH%" --create-database --load="%CONFIG_SOURCE%"
    )
    goto end
)
IF exist "%CONFIG_SOURCE%\DT-INF\" (
    echo Source type: 1C:EDT project
    echo Export "%CONFIG_SOURCE%" to 1C:Designer XML format "%XML_PATH%"...
    call %V8_RING_TOOL% edt workspace export --project "%CONFIG_SOURCE%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%"
    goto export
)
IF exist "%CONFIG_SOURCE%\Configuration.xml" (
    echo Source type: 1C:Designer XML files
    set XML_PATH=%CONFIG_SOURCE%
    goto export
)

echo Error cheking type of configuration "%CONFIG_SOURCE%"!
echo Configuration file (*.cf), 1C:Designer XML files or 1C:EDT project expected.
exit /b 1

:export

IF "%V8_CONVERT_TOOL%" equ "designer" (
    echo Creating infobase "%IB_PATH%"...
    %V8_TOOL% CREATEINFOBASE File=%IB_PATH%; /DisableStartupDialogs

    echo Loading infobase "%IB_PATH%" configuration from XML-files "%XML_PATH%"...
    %V8_TOOL% DESIGNER /IBConnectionString File=%IB_PATH%; /DisableStartupDialogs /LoadConfigFromFiles %XML_PATH%
) ELSE (
    echo Creating infobase "%IB_PATH%" from XML files "%XML_PATH%"...
    %IBCMD_TOOL% infobase create --db-path="%IB_PATH%" --create-database --import="%XML_PATH%"
)

:end

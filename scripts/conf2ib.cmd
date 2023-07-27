@ECHO OFF

echo Load 1C configuration to 1C infobase

set ERROR_CODE=0

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290
IF not defined V8_TEMP set V8_TEMP=%TEMP%\1c

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
    echo [ERROR] Missed parameter 1 - "path to 1C configuration source (1C configuration file (*.cf), 1C:Designer XML files or 1C:EDT project)"
    set ERROR_CODE=1
)
IF not defined IB_PATH (
    echo [ERROR] Missed parameter 2 - "path to folder contains 1C infobase"
    set ERROR_CODE=1
)
IF %ERROR_CODE% neq 0 (
    echo ===
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - path to 1C configuration source ^(1C configuration file ^(*.cf^), 1C:Designer XML files or 1C:EDT project^)
    echo     %%2 - path to folder contains 1C infobase
    echo.
    exit /b %ERROR_CODE%
)

echo Clear infobase folder "%IB_PATH%"...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"
md "%V8_TEMP%"
IF exist "%IB_PATH%" rd /S /Q "%IB_PATH%"
md "%IB_PATH%"

echo Checking configuration source type...

IF /i "%CONFIG_SOURCE:~-3%" equ ".cf" (
    echo Source type: Configuration file ^(CF^)
    goto export_cf
)
IF exist "%CONFIG_SOURCE%\DT-INF\" (
    echo Source type: 1C:EDT project
    goto export_edt
)
IF exist "%CONFIG_SOURCE%\Configuration.xml" (
    echo Source type: 1C:Designer XML files
    set XML_PATH=%CONFIG_SOURCE%
    goto export_xml
)

echo Error cheking type of configuration "%CONFIG_SOURCE%"!
echo Configuration file ^(*.cf^), 1C:Designer XML files or 1C:EDT project expected.
exit /b 1

:export_edt

echo Export "%CONFIG_SOURCE%" to 1C:Designer XML format "%XML_PATH%"...
call %V8_RING_TOOL% edt workspace export --project "%CONFIG_SOURCE%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%"

:export_xml

IF "%V8_CONVERT_TOOL%" equ "designer" (
    echo Creating infobase "%IB_PATH%"...
    %V8_TOOL% CREATEINFOBASE File=%IB_PATH%; /DisableStartupDialogs

    echo Loading infobase "%IB_PATH%" configuration from XML-files "%XML_PATH%"...
    %V8_TOOL% DESIGNER /IBConnectionString File=%IB_PATH%; /DisableStartupDialogs /LoadConfigFromFiles %XML_PATH%
) ELSE (
    echo Creating infobase "%IB_PATH%" from XML files "%XML_PATH%"...
    %IBCMD_TOOL% infobase create --db-path="%IB_PATH%" --create-database --import="%XML_PATH%"
)

goto end

:export_cf

echo Creating infobase "%IB_PATH%" from file "%CONFIG_SOURCE%"...
IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% CREATEINFOBASE File="%IB_PATH%"; /DisableStartupDialogs /UseTemplate "%CONFIG_SOURCE%"
) ELSE (
    %IBCMD_TOOL% infobase create --db-path="%IB_PATH%" --create-database --load="%CONFIG_SOURCE%"
)

:end

@ECHO OFF

echo Convert 1C configuration to 1C configuration file ^(*.cf^)

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

set LOCAL_TEMP=%V8_TEMP%\%~n0
set IB_PATH=%LOCAL_TEMP%\tmp_db
set XML_PATH=%LOCAL_TEMP%\tmp_xml
set WS_PATH=%LOCAL_TEMP%\edt_ws

set CONFIG_SOURCE=%1
IF defined CONFIG_SOURCE set CONFIG_SOURCE=%CONFIG_SOURCE:"=%
set CONFIG_FILE=%2
IF defined CONFIG_FILE (
    set CONFIG_FILE=%CONFIG_FILE:"=%
    set CONFIG_FILE_PATH=%~dp2
)

IF not defined CONFIG_SOURCE (
    echo [ERROR] Missed parameter 1 - "path to 1C configuration source (infobase, 1C:Designer XML files or 1C:EDT project)"
    set ERROR_CODE=1
)
IF not defined CONFIG_FILE (
    echo [ERROR] Missed parameter 2 - "path to 1C configuration file (*.cf)"
    set ERROR_CODE=1
)

IF %ERROR_CODE% neq 0 (
    echo ===
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - path to 1C configuration source ^(infobase, 1C:Designer XML files or 1C:EDT project^)
    echo     %%2 - path to 1C configuration file ^(*.cf^)
    echo.
    exit /b %ERROR_CODE%
)

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"
md "%LOCAL_TEMP%"
IF not exist "%CONFIG_FILE_PATH%" md "%CONFIG_FILE_PATH%"

echo [INFO] Checking configuration source type...

IF exist "%CONFIG_SOURCE%\DT-INF\" (
    echo [INFO] Source type: 1C:EDT project
    goto export_edt
)
IF exist "%CONFIG_SOURCE%\Configuration.xml" (
    echo [INFO] Source type: 1C:Designer XML files
    set XML_PATH=%CONFIG_SOURCE%
    goto export_xml
)
IF exist "%CONFIG_SOURCE%\1cv8.1cd" (
    echo [INFO] Source type: Infobase
    set IB_PATH=%CONFIG_SOURCE%
    goto export_ib
)

echo [ERROR] Error cheking type of configuration "%CONFIG_SOURCE%"!
echo Infobase, 1C:Designer XML files or 1C:EDT project expected.
exit /b 1

:export_edt

IF not exist "%XML_PATH%" md "%XML_PATH%"
md "%WS_PATH%"

echo [INFO] Export "%CONFIG_SOURCE%" to 1C:Designer XML format "%XML_PATH%"...
call %V8_RING_TOOL% edt workspace export --project "%CONFIG_SOURCE%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%"

:export_xml

IF not exist "%IB_PATH%" md "%IB_PATH%"

IF "%V8_CONVERT_TOOL%" equ "designer" (
    echo [INFO] Creating infobase "%IB_PATH%"...
    %V8_TOOL% CREATEINFOBASE File=%IB_PATH%; /DisableStartupDialogs

    echo [INFO] Loading infobase "%IB_PATH%" configuration from XML-files "%XML_PATH%"...
    %V8_TOOL% DESIGNER /IBConnectionString File=%IB_PATH%; /DisableStartupDialogs /LoadConfigFromFiles %XML_PATH%
) ELSE (
    echo [INFO] Creating infobase "%IB_PATH%" with configuration from XML-files "%XML_PATH%"...
    %IBCMD_TOOL% infobase create --db-path="%IB_PATH%" --create-database --import="%XML_PATH%"
)

:export_ib

echo [INFO] Export infobase "%IB_PATH%" configuration to "%CONFIG_FILE%"...
IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% DESIGNER /IBConnectionString File=%IB_PATH%; /DisableStartupDialogs /DumpCfg %CONFIG_FILE%
) ELSE (
    %IBCMD_TOOL% infobase config save --db-path="%IB_PATH%" "%CONFIG_FILE%"
)

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"

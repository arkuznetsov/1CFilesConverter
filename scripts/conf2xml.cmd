@ECHO OFF

SETLOCAL

echo Convert 1C configuration to 1C:Designer XML format

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
set WS_PATH=%LOCAL_TEMP%\edt_ws

IF "%1" neq "" set V8_SRC_PATH=%1
IF defined V8_SRC_PATH set V8_SRC_PATH=%V8_SRC_PATH:"=%
IF "%2" neq "" set V8_DST_PATH=%2
IF defined V8_DST_PATH set V8_DST_PATH=%V8_DST_PATH:"=%

IF not defined V8_SRC_PATH (
    echo [ERROR] Missed parameter 1 - "path to 1C configuration source (1C configuration file (*.cf), infobase or 1C:EDT project)"
    set ERROR_CODE=1
)
IF not defined V8_DST_PATH (
    echo [ERROR] Missed parameter 2 - "path to folder to save configuration files in 1C:Designer XML format"
    set ERROR_CODE=1
)
IF %ERROR_CODE% neq 0 (
    echo ===
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - path to 1C configuration source ^(1C configuration file ^(*.cf^), infobase or 1C:EDT project^)
    echo     %%2 - path to folder to save configuration files in 1C:Designer XML format
    echo.
    exit /b %ERROR_CODE%
)

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"
md "%LOCAL_TEMP%"
IF exist "%V8_DST_PATH%" rd /S /Q "%V8_DST_PATH%"
md "%V8_DST_PATH%"

echo [INFO] Checking configuration source type...

IF /i "%V8_SRC_PATH:~-3%" equ ".cf" (
    echo [INFO] Source type: Configuration file ^(CF^)
    goto export_cf
)
IF exist "%V8_SRC_PATH%\1cv8.1cd" (
    echo [INFO] Source type: Infobase
    set IB_PATH=%V8_SRC_PATH%
    goto export_ib
)
IF exist "%V8_SRC_PATH%\DT-INF\" (
    echo [INFO] Source type: 1C:EDT project
    goto export_edt
)

echo [ERROR] Error cheking type of configuration "%V8_SRC_PATH%"!
echo Infobase, configuration file ^(*.cf^) or 1C:EDT project expected.
exit /b 1

:export_cf

echo [INFO] Creating infobase "%IB_PATH%" from file "%V8_SRC_PATH%"...

md "%IB_PATH%"

IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% CREATEINFOBASE File="%IB_PATH%"; /DisableStartupDialogs /UseTemplate "%V8_SRC_PATH%"
) ELSE (
    %IBCMD_TOOL% infobase create --db-path="%IB_PATH%" --create-database --load="%V8_SRC_PATH%"
)

:export_ib

echo [INFO] Export configuration from infobase "%IB_PATH%" to 1C:Designer XML format "%V8_DST_PATH%"...
IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /DumpConfigToFiles "%V8_DST_PATH%" -force
) ELSE (
    %IBCMD_TOOL% infobase config export --db-path="%IB_PATH%" "%V8_DST_PATH%" --force
)

goto end

:export_edt

echo [INFO] Export "%V8_SRC_PATH%" to 1C:Designer XML format "%V8_DST_PATH%"...

md "%WS_PATH%"

call %V8_RING_TOOL% edt workspace export --project "%V8_SRC_PATH%" --configuration-files "%V8_DST_PATH%" --workspace-location "%WS_PATH%"

:end

echo [INFO] Clear temporary files...
IF exist "%LOCAL_TEMP%" rd /S /Q "%LOCAL_TEMP%"

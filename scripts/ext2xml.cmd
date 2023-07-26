@ECHO OFF

rem Convert (dump) all 1C data processors & reports (*.epf, *.erf) in folder to 1C:Designer XML format
rem %1 - path to folder contains 1C extension binary file (*.cfe) or EDT project
rem %2 - path to folder to save configuration extension files in 1C:Designer XML format
rem %3 - configuration extension name
rem %4 - path to 1C configuration (binary (*.cf), 1C:Designer XML format or 1C:EDT format)
rem      or folder contains 1C infobase used for convertion

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

set IB_PATH=%V8_TEMP%\tmp_db
set WS_PATH=%V8_TEMP%\edt_ws

set EXT_SOURCE=%1
IF defined EXT_SOURCE set EXT_SOURCE=%EXT_SOURCE:"=%
set EXT_DEST_PATH=%2
IF defined EXT_DEST_PATH set EXT_DEST_PATH=%EXT_DEST_PATH:"=%
set EXT_NAME=%3
set BASE_CONFIG=%4
IF defined BASE_CONFIG set BASE_CONFIG=%BASE_CONFIG:"=%

IF not defined EXT_SOURCE (
    echo Missed parameter 1 "path to folder contains 1C extension binary file (*.cfe) or EDT project"
    exit /b 1
)
IF not defined EXT_DEST_PATH (
    echo Missed parameter 2 "path to folder to save configuration extension files in 1C:Designer XML format"
    exit /b 1
)
IF not defined EXT_NAME (
    echo Missed parameter 3 "configuration extension name"
    exit /b 1
)
IF not exist "%BASE_CONFIG%" (
    echo Path "%BASE_CONFIG%" doesn't exist ^(parameter 4^), empty infobase will be used.
    set BASE_CONFIG=
)

echo Clear temporary files...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"
md "%V8_TEMP%"
IF not exist "%EXT_DEST_PATH%" md "%EXT_DEST_PATH%"

echo Set infobase for export data processor/report...
set BASE_CONFIG_DESCRIPTION=configuration from "%BASE_CONFIG%"

IF "%BASE_CONFIG%" equ "" (
    md "%IB_PATH%"
    echo Creating infobase "%IB_PATH%"...
    set BASE_CONFIG_DESCRIPTION=empty configuration
    %V8_TOOL% CREATEINFOBASE File=%IB_PATH%; /DisableStartupDialogs
    goto export
)
IF /i "%BASE_CONFIG:~-3%" equ ".cf" (
    echo Basic config source type: Configuration file ^(CF^)
    md "%IB_PATH%"
    call %~dp0conf2ib.cmd "%BASE_CONFIG%" "%IB_PATH%"
    goto export
)
IF exist "%BASE_CONFIG%\DT-INF\" (
    echo Basic config source type: 1C:EDT project
    md "%IB_PATH%"
    call %~dp0conf2ib.cmd "%BASE_CONFIG%" "%IB_PATH%" designer
    goto export
)
IF exist "%BASE_CONFIG%\Configuration.xml" (
    echo Basic config source type: 1C:Designer XML files
    md "%IB_PATH%"
    call %~dp0conf2ib.cmd "%BASE_CONFIG%" "%IB_PATH%" designer
    goto export
)
IF exist "%BASE_CONFIG%\1cv8.1cd" (
    echo Basic config source type: Infobase
    set BASE_CONFIG_DESCRIPTION=existed configuration
    set IB_PATH=%BASE_CONFIG%
    goto export
)

echo Error cheking type of basic configuration "%BASE_CONFIG%"!
echo Infobase, configuration file (*.cf), 1C:Designer XML, 1C:EDT project or no configuration expected.
exit /b 1

:export

echo Checking 1C extension source type...

IF /i "%EXT_SOURCE:~-4%" equ ".cfe" (
    echo Source type: Configuration extension file ^(CFE^)
    goto export_cfe
)
IF exist "%EXT_SOURCE%\DT-INF\" (
    IF exist "%EXT_SOURCE%\src\Configuration\Configuration.mdo" (
        FOR /f %%t IN ('findstr /r /i "<objectBelonging>" "%EXT_SOURCE%\src\Configuration\Configuration.mdo"') DO (
            echo Source type: 1C:EDT project
            goto export_edt
        )
    )
)

echo Wrong path "%EXT_SOURCE%"!
echo Configuration extension binary (*.cfe) or folder containing configuration extension 1C:EDT project expected.
exit /b 1

:export_cfe

echo Loading configuration extension from file "%EXT_SOURCE%" to infobase "%IB_PATH%"...

IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% DESIGNER /IBConnectionString File=%IB_PATH%; /DisableStartupDialogs /LoadCfg %EXT_SOURCE% -Extension %EXT_NAME%
) ELSE (
    %IBCMD_TOOL% infobase config load --db-path="%IB_PATH%" --extension=%EXT_NAME% "%EXT_SOURCE%"
)

echo Export configuration from infobase "%IB_PATH%" to 1C:Designer XML format "%EXT_DEST_PATH%"...

IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% DESIGNER /IBConnectionString File="%IB_PATH%"; /DisableStartupDialogs /DumpConfigToFiles "%EXT_DEST_PATH%" -Extension %EXT_NAME% -force
) ELSE (
    %IBCMD_TOOL% infobase config export --db-path="%IB_PATH%" --extension=%EXT_NAME% --force "%EXT_DEST_PATH%"
)

goto end

:export_edt

echo Export configuration extension from 1C:EDT format "%EXT_SOURCE%" to 1C:Designer XML format "%XML_PATH%"...
md "%WS_PATH%"
call %V8_RING_TOOL% edt workspace export --project "%EXT_SOURCE%" --configuration-files "%EXT_DEST_PATH%" --workspace-location "%WS_PATH%"

:end

echo Clear temporary files...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"

@ECHO OFF

echo Convert 1C configuration extension to binary format ^(*.cfe^)

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

set IB_PATH=%V8_TEMP%\tmp_db
set XML_PATH=%V8_TEMP%\tmp_xml
set WS_PATH=%V8_TEMP%\edt_ws

set EXT_SOURCE=%1
IF defined EXT_SOURCE set EXT_SOURCE=%EXT_SOURCE:"=%
set EXT_FILE=%2
IF defined EXT_FILE (
    set EXT_FILE=%EXT_FILE:"=%
    set EXT_FILE_PATH=%~dp2
)
set EXT_NAME=%3
IF defined EXT_NAME set EXT_NAME=%EXT_NAME:"=%
set BASE_CONFIG=%4
IF defined BASE_CONFIG set BASE_CONFIG=%BASE_CONFIG:"=%

IF not defined EXT_SOURCE (
    echo [ERROR] Missed parameter 1 - "path to folder contains 1C extension in 1C:Designer XML format or EDT project"
    set ERROR_CODE=1
) ELSE (
    IF not exist "%EXT_SOURCE%" (
        echo [ERROR] Path "%EXT_SOURCE%" doesn't exist ^(parameter 1^).
        set ERROR_CODE=1
    )
)
IF not defined EXT_FILE (
    echo [ERROR] Missed parameter 2 - "path to 1C configuration extension file (*.cfe)"
     set ERROR_CODE=1
)
IF not defined EXT_NAME (
    echo [ERROR] Missed parameter 3 - "configuration extension name"
    set ERROR_CODE=1
)
IF not exist "%BASE_CONFIG%" (
    echo [INFO] Path "%BASE_CONFIG%" doesn't exist ^(parameter 4^), empty infobase will be used.
    set BASE_CONFIG=
)
IF %ERROR_CODE% neq 0 (
    echo ===
    echo [ERROR] Input parameters error. Expected:
    echo     %%1 - path to folder contains 1C extension in 1C:Designer XML format or EDT project
    echo     %%2 - path to 1C configuration extension file ^(*.cfe^)
    echo     %%3 - configuration extension name
    echo     %%4 - ^(optional^) path to 1C configuration ^(binary ^(*.cf^), 1C:Designer XML format or 1C:EDT project^)
    echo           or folder contains 1C infobase used for convertion
    echo.
    exit /b %ERROR_CODE%
)

echo Clear temporary files...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"
md "%V8_TEMP%"
IF not exist "%EXT_FILE_PATH%" md "%EXT_FILE_PATH%"

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
echo Infobase, configuration file ^(*.cf^), 1C:Designer XML, 1C:EDT project or no configuration expected.
exit /b 1

:export

echo Checking 1C extension source type...

IF exist "%EXT_SOURCE%\DT-INF\" (
    IF exist "%EXT_SOURCE%\src\Configuration\Configuration.mdo" (
        FOR /f %%t IN ('findstr /r /i "<objectBelonging>" "%EXT_SOURCE%\src\Configuration\Configuration.mdo"') DO (
            echo Source type: 1C:EDT project
            md "%XML_PATH%"
            md "%WS_PATH%"
            goto export_edt
        )
    )
)
IF exist "%EXT_SOURCE%\Configuration.xml" (
    FOR /f %%t IN ('findstr /r /i "<objectBelonging>" "%EXT_SOURCE%\Configuration.xml"') DO (
        echo Source type: 1C:Designer XML files
        set XML_PATH=%EXT_SOURCE%
        goto export_xml
    )
)

echo Wrong path "%EXT_SOURCE%"!
echo Folder containing configuration extension in 1C:Designer XML format or 1C:EDT project expected.
exit /b 1

:export_edt

echo Export configuration extension from 1C:EDT format "%EXT_SOURCE%" to 1C:Designer XML format "%XML_PATH%"...
call %V8_RING_TOOL% edt workspace export --project "%EXT_SOURCE%" --configuration-files "%XML_PATH%" --workspace-location "%WS_PATH%"

:export_xml

echo Loading configuration extension from XML-files "%XML_PATH%" to infobase "%IB_PATH%"...
IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% DESIGNER /IBConnectionString File=%IB_PATH%; /DisableStartupDialogs /LoadConfigFromFiles %XML_PATH% -Extension %EXT_NAME%
) ELSE (
    %IBCMD_TOOL% infobase config import --db-path="%IB_PATH%" --extension=%EXT_NAME% "%XML_PATH%"
)

:export_ib

echo Export configuration extension from infobase "%IB_PATH%" configuration to "%EXT_FILE%"...
IF "%V8_CONVERT_TOOL%" equ "designer" (
    %V8_TOOL% DESIGNER /IBConnectionString File=%IB_PATH%; /DisableStartupDialogs /DumpCfg %EXT_FILE% -Extension %EXT_NAME%
) ELSE (
    %IBCMD_TOOL% infobase config save --db-path="%IB_PATH%" --extension=%EXT_NAME% "%EXT_FILE%"
)

echo Clear temporary files...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"

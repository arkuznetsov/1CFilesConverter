@ECHO OFF

rem Validate 1C configuration using 1C:EDT (ring tool)
rem %1 - path to 1C configuration, extension, data processors or reports (binary (*.cf, *.cfe, *.epf, *.erf), 1C:Designer XML format or 1C:EDT format)
rem %2 - path to validation report file

IF not defined V8_VERSION set V8_VERSION=8.3.20.2290
IF not defined V8_TEMP set V8_TEMP=%TEMP%\1c

IF not defined V8_RING_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
        set V8_RING_TOOL="%%i"
    )
)

IF "%VALIDATE_PATH%" equ "" (
    set VALIDATE_PATH=%V8_TEMP%\tmp_edt
)
set WS_PATH=%V8_TEMP%\edt_ws

set CONFIG_PATH=%1
IF defined CONFIG_PATH set CONFIG_PATH=%CONFIG_PATH:"=%
set REPORT_FILE=%2
IF defined REPORT_FILE (
    set REPORT_FILE=%REPORT_FILE:"=%
    set REPORT_FILE_PATH=%~dp2
)
set EXT_NAME=%3
IF defined EXT_NAME set EXT_NAME=%EXT_NAME:"=%

IF not defined CONFIG_PATH (
    echo Missed parameter 1 "path to 1C configuration, extension, data processors or reports (binary (*.cf, *.cfe, *.epf, *.erf), 1C:Designer XML format or 1C:EDT format)"
    exit /b 1
)
IF not defined REPORT_FILE (
    echo Missed parameter 2 "path to validation report file"
    exit /b 1
)

echo Clear temporary files...
IF exist "%V8_TEMP%" rd /S /Q "%V8_TEMP%"
md "%V8_TEMP%"
md "%WS_PATH%"
IF not exist "%REPORT_FILE_PATH%" md "%REPORT_FILE_PATH%"

echo Prepare project for validation...

IF exist "%CONFIG_PATH%\DT-INF\" (
    set VALIDATE_PATH=%CONFIG_PATH%
    goto validate
)
md "%VALIDATE_PATH%"
IF /i "%CONFIG_PATH:~-3%" equ ".cf" (
    call %~dp0conf2edt.cmd "%CONFIG_PATH%" "%VALIDATE_PATH%"
    goto validate
)
IF /i "%CONFIG_PATH:~-4%" equ ".cfe" (
    call %~dp0ext2edt.cmd "%CONFIG_PATH%" "%VALIDATE_PATH%" "%EXT_NAME%"
    goto validate
)
IF exist "%CONFIG_PATH%\Configuration.xml" (
    FOR /f %%t IN ('findstr /r /i "<objectBelonging>" "%CONFIG_PATH%\Configuration.xml"') DO (
        call %~dp0ext2edt.cmd "%CONFIG_PATH%" "%VALIDATE_PATH%"
        goto validate
    )
    call %~dp0conf2edt.cmd "%CONFIG_PATH%" "%VALIDATE_PATH%"
    goto validate
)
IF exist "%CONFIG_PATH%\1cv8.1cd" (
    call %~dp0conf2edt.cmd "%CONFIG_PATH%" "%VALIDATE_PATH%"
    goto validate
)
FOR /f %%f IN ('dir /b /a-d "%CONFIG_PATH%\*.epf" "%CONFIG_PATH%\*.erf" "%CONFIG_PATH%\*.xml" "%CONFIG_PATH%\ExternalDataProcessors\*.xml" "%CONFIG_PATH%\ExternalReports\*.xml"') DO (
    call %~dp0dp2edt.cmd "%CONFIG_PATH%" "%VALIDATE_PATH%"
    goto validate
)

echo Error cheking type of configuration "%BASE_CONFIG%"!
echo Infobase, configuration file ^(*.cf^), configuration extension file ^(*.cfe^), folder contains external data processors ^& reports in binary or XML format, 1C:Designer XML or 1C:EDT project expected.
exit /b 1

:validate

echo Run validation in "%VALIDATE_PATH%"...
call %V8_RING_TOOL% edt workspace validate --project-list "%VALIDATE_PATH%" --workspace-location "%WS_PATH%" --file "%REPORT_FILE%" 

echo Clear temporary files...
IF exist "%WS_PATH%" rd /S /Q "%WS_PATH%"

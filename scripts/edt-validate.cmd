@ECHO OFF

rem Validate 1C configuration using 1C:EDT (ring tool)
rem %1 - path to 1C configuration (binary (*.cf), 1C:Designer XML format or 1C:EDT format)
rem %2 - path to validation report file

if not defined V8_VERSION set V8_VERSION=8.3.20.2290

FOR /F "usebackq tokens=1 delims=" %%i IN (`where ring`) DO (
    set RING_TOOL="%%i"
)

IF "%VALIDATE_PATH%" equ "" (
    set VALIDATE_PATH=%TEMP%\1c\tmp_edt
)
set WS_PATH=%TEMP%\1c\edt_ws
set CLEAN_AFTER_VALIDATION=0

set CONFIG_PATH=%1
if defined CONFIG_PATH set CONFIG_PATH=%CONFIG_PATH:"=%
set REPORT_FILE=%2
if defined REPORT_FILE (
    set REPORT_FILE=%REPORT_FILE:"=%
    set REPORT_FILE_PATH=%~dp2
)

if not defined CONFIG_PATH (
    echo Missed parameter 1 "path to 1C configuration (binary (*.cf), 1C:Designer XML format or 1C:EDT format)"
    exit /b 1
)
if not defined REPORT_FILE (
    echo Missed parameter 2 "path to validation report file"
    exit /b 1
)

echo Clear temporary files...
if exist "%WS_PATH%" (
    rd /S /Q "%WS_PATH%"
)
del "%REPORT_FILE%"
md "%REPORT_FILE_PATH%"

echo Prepare project for validation...
IF exist "%CONFIG_PATH%\DT-INF\" (
    set VALIDATE_PATH=%CONFIG_PATH%
) else (
    set CLEAN_AFTER_VALIDATION=1
    IF exist "%CONFIG_PATH%\Configuration.xml" (
        call %~dp0xml2edt.cmd "%CONFIG_PATH%" "%VALIDATE_PATH%"
    ) else (
        call %~dp0cf2edt.cmd "%CONFIG_PATH%" "%VALIDATE_PATH%"
    )
)

echo Run validation in "%VALIDATE_PATH%"...
call %RING_TOOL% edt workspace validate --project-list "%VALIDATE_PATH%" --workspace-location "%WS_PATH%" --file "%REPORT_FILE%" 

echo Clear temporary files...
rd /S /Q "%WS_PATH%"
IF "%CLEAN_AFTER_VALIDATION%" equ "1" (
    rd /S /Q "%VALIDATE_PATH%"
)

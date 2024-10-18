@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

echo START: %date% %time%

set ERROR_CODE=0
set ERROR_MESSAGE=

set ARG=%1
IF defined ARG set ARG=%ARG:"=%
IF "%ARG%" neq "" set V8_UPDATE_SETTING=%ARG%

IF defined V8_UPDATE_SETTING IF exist "%V8_UPDATE_SETTING%" (
    FOR /F "usebackq tokens=*" %%a in ("%V8_UPDATE_SETTING%") DO (
        FOR /F "tokens=1,2 delims==" %%b IN ("%%a") DO (
            set "%%b=%%c"
        )
    )
)

IF not defined V8_UPDATE_SETTING IF exist "%cd%\.env" IF "%V8_SKIP_ENV%" neq "1" (
    FOR /F "usebackq tokens=*" %%a in ("%cd%\.env") DO (
        FOR /F "tokens=1,2 delims==" %%b IN ("%%a") DO (
            IF not defined %%b set "%%b=%%c"
        )
    )
)

IF not defined V8_ENCODING set V8_ENCODING=65001
chcp %V8_ENCODING% > nul

IF not defined V8_VERSION set V8_VERSION=8.3.23.1997
IF not defined V8_RAS_ADDR set V8_RAS_ADDR=localhost
IF not defined V8_RAS_PORT set V8_RAS_PORT=1545
IF not defined V8_IB_SRV set V8_IB_SRV=localhost

IF not defined NOTIFICATION_ON_SUCCESS set NOTIFICATION_ON_SUCCESS=1
IF not defined NOTIFICATION_ON_ERROR set NOTIFICATION_ON_ERROR=1

IF defined V8_LOG_FILE_NAME (
    set V8_LOG_APPENDER=%~dp0%V8_LOG_FILE_NAME%
    echo "START: %date% %time%" > log.txt
)

IF not defined VRUNNER_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where vrunner`) DO (
        set VRUNNER_TOOL="%%i"
    )
)
IF not defined VRUNNER_TOOL (
    echo [ERROR] Не найдена утилита "vanessa-runner". Добавьте путь к командному файлу "vrunner.bat" в переменную среды "PATH", или укажите полный путь к утилите в переменной среды "VRUNNER_TOOL"!
    set ERROR_CODE=1
    goto finally
)

IF not defined V8_IB_NAME (
    echo [ERROR] Не указано имя информационной базы для обновления конфигурации базы данных!
    set ERROR_CODE=1
    goto finally
)

IF defined V8_IB_USER (
    set V8_IB_CREDENTIALS=--db-user "%V8_IB_USER%"
    IF defined V8_IB_PWD (
        set V8_IB_CREDENTIALS=!V8_IB_CREDENTIALS! --db-pwd "%V8_IB_PWD%"
    )
)

set LOCK_START_DATE=%date%
set LOCK_START_YEAR=%LOCK_START_DATE:~6,4%
set LOCK_START_MONTH=%LOCK_START_DATE:~3,2%
set LOCK_START_DAY=%LOCK_START_DATE:~0,2%
set LOCK_START_TIME=%time%
set LOCK_START_HOUR=%LOCK_START_TIME:~0,2%
set LOCK_START_MIN=%LOCK_START_TIME:~3,2%
set LOCK_START_SEC=%LOCK_START_TIME:~6,2%
set V8_LOCK_START=%LOCK_START_YEAR%-%LOCK_START_MONTH%-%LOCK_START_DAY%T%LOCK_START_HOUR%:%LOCK_START_MIN%:00

IF defined V8_LOCK_MESSAGE (
    set V8_LOCK_MESSAGE=%V8_LOCK_MESSAGE% ^(начало: %V8_LOCK_START%)
) ELSE (
    set V8_LOCK_MESSAGE=Выполняется обновление конфигурации базы данных ^(начало: %V8_LOCK_START%)
)
IF not defined V8_LOCK_CODE set V8_LOCK_CODE=lock_code_01

echo [INFO] Начало обновления информационной базы "%V8_IB_SRV%\%V8_IB_NAME%"
IF defined V8_UPDATE_SETTING echo [INFO]    - Файл настроек: %V8_UPDATE_SETTING%
echo [INFO]    - Версия 1С:Предприятие: %V8_VERSION%
echo [INFO]    - Адрес службы администрирования (RAS): %V8_RAS_ADDR%:%V8_RAS_PORT%
echo [INFO]    - Сервер 1С:Предприятие: %V8_IB_SRV%
echo [INFO]    - Имя информационной базы: %V8_IB_NAME%
IF defined V8_IB_USER echo [INFO]    - Пользователь информационной базы: %V8_IB_USER%

echo.
echo [INFO] Описание информационной базы
call %VRUNNER_TOOL% dbinfo --v8version "%V8_VERSION%" --ras "%V8_RAS_ADDR%:%V8_RAS_PORT%" --try 3 --db "%V8_IB_NAME%" --ibconnection "/S%V8_IB_SRV%\%V8_IB_NAME%" %V8_IB_CREDENTIALS%
IF "%ERRORLEVEL%" neq "0" (
    set ERROR_CODE=%ERRORLEVEL%
    set ERROR_MESSAGE=Ошибка получения описания информационной базы
    goto finally
)

echo.
echo [INFO] Блокировка регламентных заданий
call %VRUNNER_TOOL% scheduledjobs lock --v8version "%V8_VERSION%" --ras "%V8_RAS_ADDR%:%V8_RAS_PORT%" --try 3 --db "%V8_IB_NAME%" --ibconnection "/S%V8_IB_SRV%\%V8_IB_NAME%" %V8_IB_CREDENTIALS%
IF "%ERRORLEVEL%" neq "0" (
    set ERROR_CODE=%ERRORLEVEL%
    set ERROR_MESSAGE=Ошибка блокировки регламентных заданий
    goto finally
)

echo.
echo [INFO] Завершение сеансов и блокировка новых сеансов
call %VRUNNER_TOOL% session kill --v8version "%V8_VERSION%" --ras "%V8_RAS_ADDR%:%V8_RAS_PORT%" --try 3 --db "%V8_IB_NAME%" --ibconnection "/S%V8_IB_SRV%\%V8_IB_NAME%" %V8_IB_CREDENTIALS% --uccode "%V8_LOCK_CODE%" --lockmessage "%V8_LOCK_MESSAGE%" --lockstart "%V8_LOCK_START%" --lockendclear
IF "%ERRORLEVEL%" neq "0" (
    set ERROR_CODE=%ERRORLEVEL%
    set ERROR_MESSAGE=Ошибка завершения и блокировки сеансов
    goto finally
)

echo.
echo [INFO] Обновление основной конфигурации базы данных
call %VRUNNER_TOOL% updatedb --v8version "%V8_VERSION%" --ibconnection "/S%V8_IB_SRV%\%V8_IB_NAME%" %V8_IB_CREDENTIALS% --uccode "%V8_LOCK_CODE%"
IF "%ERRORLEVEL%" neq "0" (
    set ERROR_CODE=%ERRORLEVEL%
    set ERROR_MESSAGE=Ошибка обновления основной конфигурации базы данных
    goto finally
)

IF defined V8_EXTENSIONS (
    FOR %%j IN (%V8_EXTENSIONS%) DO echo [INFO] В параметрах найдено расширение: %%j
) ELSE (
    set EXT_LIST_FILE=%~dp0v8_ext_list.txt
    %V8_TOOL% DESIGNER /IBConnectionString !V8_IB_CONNECTION! /N"%V8_IB_USER%" /P"%V8_IB_PWD%" /DisableStartupDialogs  /DisableStartupMessages /Out "!EXT_LIST_FILE!" /DumpDBCfgList -AllExtensions
    FOR /F "tokens=* delims=" %%i IN (!EXT_LIST_FILE!) DO (
        set EXT_NAME=%%i
        set EXT_NAME=!EXT_NAME: =!
        set EXT_NAME=!EXT_NAME:"=!
        IF /i "!EXT_NAME!" equ "%%i" (
            echo [INFO] В информационной базе найдено расширение: !EXT_NAME!
            IF defined V8_EXTENSIONS (
                set V8_EXTENSIONS=!V8_EXTENSIONS! !EXT_NAME!
            ) ELSE (
                set V8_EXTENSIONS=!EXT_NAME!
            )
        )
    )
    del /f /s /q "!EXT_LIST_FILE!" > nul
)

FOR %%i IN (%V8_EXTENSIONS%) DO (
    echo.
    echo [INFO] Обновление конфигурации расширения "%%i" базы данных
    call %VRUNNER_TOOL% designer --v8version "%V8_VERSION%" --ibconnection "/S%V8_IB_SRV%\%V8_IB_NAME%" %V8_IB_CREDENTIALS% --uccode "%V8_LOCK_CODE%" --additional "/UpdateDBCfg -Extension "%%i""
    IF "%ERRORLEVEL%" neq "0" (
        set ERROR_CODE=%ERRORLEVEL%
        set ERROR_MESSAGE=Ошибка обновления конфигурации расширения "%%i" базы данных
        goto finally
    )
)

echo.
echo [INFO] Разрешение подключения новых сеансов
call %VRUNNER_TOOL% session unlock --v8version "%V8_VERSION%" --ras "%V8_RAS_ADDR%:%V8_RAS_PORT%" --try 3 --db "%V8_IB_NAME%" --ibconnection "/S%V8_IB_SRV%\%V8_IB_NAME%" %V8_IB_CREDENTIALS% --uccode "%V8_LOCK_CODE%"
echo errorlevel 5: %ERRORLEVEL% 
IF "%ERRORLEVEL%" neq "0" (
    set ERROR_CODE=%ERRORLEVEL%
    set ERROR_MESSAGE=Ошибка разрешения подключения новых сеансов
    goto finally
)

echo.
echo [INFO] Разрешение выполнения регламентных заданий
call %VRUNNER_TOOL% scheduledjobs unlock --v8version "%V8_VERSION%" --ras "%V8_RAS_ADDR%:%V8_RAS_PORT%" --try 3 --db "%V8_IB_NAME%" --ibconnection "/S%V8_IB_SRV%\%V8_IB_NAME%" %V8_IB_CREDENTIALS%
IF "%ERRORLEVEL%" neq "0" (
    set ERROR_CODE=%ERRORLEVEL%
    set ERROR_MESSAGE=Ошибка разрешения выполнения регламентных заданий
    goto finally
)

:finally

set NOTIFICATION_IB_PATH=%V8_IB_SRV%\%V8_IB_NAME%
set NOTIFICATION_IB_PATH=%NOTIFICATION_IB_PATH:_=\_%
echo.
IF "%ERROR_CODE%" equ "0" (
    IF "%NOTIFICATION_ON_SUCCESS%" equ "1" set NOTIFICATION_TEXT=\[INFO]: Обновление конфигурации базы данных информационной базы ""%NOTIFICATION_IB_PATH%"" завершено.
    echo [INFO] Обновление конфигурации базы данных информационной базы "%V8_IB_SRV%\%V8_IB_NAME%" завершено.
) ELSE (
    IF "%NOTIFICATION_ON_ERROR%" equ "1" set NOTIFICATION_TEXT=\[ERROR]: Ошибка при обновлении конфигурации базы данных информационной базы "%NOTIFICATION_IB_PATH%" ^(код возврата: "%ERROR_CODE%"^): %ERROR_MESSAGE%
    echo [ERROR] Ошибка при обновлении конфигурации базы данных информационной базы "%V8_IB_SRV%\%V8_IB_NAME%" ^(код возврата: %ERROR_CODE%^).
    echo [ERROR]    - %ERROR_MESSAGE%
)

IF not defined TELEGRAM_TOKEN (
    echo [WARN] Не указан токен ^(TELEGRAM_TOKEN^) для оповещения в Telegram, оповещение не будет отправлено.
    goto end
)

IF not defined TELEGRAM_CHAT_ID (
    echo [WARN] Не указан идентификатор получателя ^(TELEGRAM_CHAT_ID^) для оповещения в Telegram, оповещение не будет отправлено.
    goto end
)

IF not defined OINT_TOOL (
    FOR /F "usebackq tokens=1 delims=" %%i IN (`where oint`) DO (
        set OINT_TOOL="%%i"
    )
)
IF defined OINT_TOOL (
    IF defined NOTIFICATION_TEXT call %OINT_TOOL% telegram ОтправитьТекстовоеСообщение --token %TELEGRAM_TOKEN% --chat "%TELEGRAM_CHAT_ID%" --text "%NOTIFICATION_TEXT%"
) ELSE (
    echo [ERROR] Не найдена утилита "oint" для отправки оповещения. Добавьте путь утилите "oint" в переменную среды "PATH", или укажите полный путь к утилите в переменной среды "OINT_TOOL"!
)

:end

echo.
echo FINISH: %date% %time%
echo.

exit /b %ERROR_CODE%

@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

echo [INFO] Проверка кодировок > encoding.log


IF not defined V8_ENCODING set V8_ENCODING=65001
chcp %V8_ENCODING% > nul

set V8_ENCODING=65001 1251 866
set V8_UPDATE_SETTING=1251.env 866.env utf8.env koi8.env 8859.env

FOR %%k IN (%V8_ENCODING%) DO (
    echo [INFO] Чтение настроек с кодировкой: %%k >> encoding.log
    chcp %%k > nul
    FOR %%i IN (%V8_UPDATE_SETTING%) DO (
        echo [INFO]     Чтение настроек: %%i >> encoding.log
        IF exist "%%i" (
            FOR /F "usebackq tokens=*" %%a in ("%%i") DO (
                FOR /F "tokens=1,2 delims==" %%b IN ("%%a") DO (
                    set "%%b=%%c"
                )
            )
        )
    
        FOR %%j IN (!V8_EXTENSIONS!) DO echo [INFO]         В параметрах найдено расширение: %%j >> encoding.log
    )
)
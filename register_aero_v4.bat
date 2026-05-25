@echo off
chcp 65001 >nul
title Aero Language V4 - Регистрация

echo.
echo ╔══════════════════════════════════════════════════╗
echo ║     AERO LANGUAGE V4 - ФАЙЛОВАЯ АССОЦИАЦИЯ       ║
echo ╚══════════════════════════════════════════════════╝
echo.
pause

:: Шаг 1: Проверка интерпретатора
echo.
echo [ШАГ 1] Проверка интерпретатора...
echo.

set "AERO_PATH=%~dp0"
set "INTERPRETER=%AERO_PATH%AeroInterpreter_V4.exe"

if exist "%INTERPRETER%" (
    echo [✓] Интерпретатор найден:
    echo     %INTERPRETER%
) else (
    echo [✗] Интерпретатор НЕ найден!
    echo.
    echo     Сначала скомпилируйте:
    echo     gcc AeroInterpreter_V4.c -o AeroInterpreter_V4.exe -mwindows
    echo.
    pause
    exit /b 1
)
echo.
pause

:: Шаг 2: Создание REG файла
echo.
echo [ШАГ 2] Создание записей реестра...
echo.

echo Windows Registry Editor Version 5.00 > "%TEMP%\aero_v4.reg"
echo. >> "%TEMP%\aero_v4.reg"

echo [HKEY_CLASSES_ROOT\.aer] >> "%TEMP%\aero_v4.reg"
echo @="AeroLangV4.File" >> "%TEMP%\aero_v4.reg"
echo. >> "%TEMP%\aero_v4.reg"

echo [HKEY_CLASSES_ROOT\AeroLangV4.File] >> "%TEMP%\aero_v4.reg"
echo @="Aero Language V4 Script" >> "%TEMP%\aero_v4.reg"
echo. >> "%TEMP%\aero_v4.reg"

echo [HKEY_CLASSES_ROOT\AeroLangV4.File\DefaultIcon] >> "%TEMP%\aero_v4.reg"
echo @="\"%INTERPRETER:\=\\%\",0" >> "%TEMP%\aero_v4.reg"
echo. >> "%TEMP%\aero_v4.reg"

echo [HKEY_CLASSES_ROOT\AeroLangV4.File\shell] >> "%TEMP%\aero_v4.reg"
echo @="run" >> "%TEMP%\aero_v4.reg"
echo. >> "%TEMP%\aero_v4.reg"

echo [HKEY_CLASSES_ROOT\AeroLangV4.File\shell\run] >> "%TEMP%\aero_v4.reg"
echo @="Запустить Aero V4" >> "%TEMP%\aero_v4.reg"
echo. >> "%TEMP%\aero_v4.reg"

echo [HKEY_CLASSES_ROOT\AeroLangV4.File\shell\run\command] >> "%TEMP%\aero_v4.reg"
echo @="\"%INTERPRETER:\=\\%\" \"%%1\"" >> "%TEMP%\aero_v4.reg"
echo. >> "%TEMP%\aero_v4.reg"

echo [HKEY_CLASSES_ROOT\AeroLangV4.File\shell\open] >> "%TEMP%\aero_v4.reg"
echo. >> "%TEMP%\aero_v4.reg"

echo [HKEY_CLASSES_ROOT\AeroLangV4.File\shell\open\command] >> "%TEMP%\aero_v4.reg"
echo @="\"%INTERPRETER:\=\\%\" \"%%1\"" >> "%TEMP%\aero_v4.reg"
echo. >> "%TEMP%\aero_v4.reg"

echo [HKEY_CLASSES_ROOT\AeroLangV4.File\shell\edit] >> "%TEMP%\aero_v4.reg"
echo @="Редактировать" >> "%TEMP%\aero_v4.reg"
echo. >> "%TEMP%\aero_v4.reg"

echo [HKEY_CLASSES_ROOT\AeroLangV4.File\shell\edit\command] >> "%TEMP%\aero_v4.reg"
echo @="notepad.exe \"%%1\"" >> "%TEMP%\aero_v4.reg"
echo. >> "%TEMP%\aero_v4.reg"

echo [✓] REG файл создан
echo.
pause

:: Шаг 3: Применение реестра
echo.
echo [ШАГ 3] Применение настроек реестра...
echo.

regedit /s "%TEMP%\aero_v4.reg"

if %ERRORLEVEL% EQU 0 (
    echo [✓] Реестр успешно обновлен
) else (
    echo [✗] Ошибка обновления реестра!
    echo     Запустите от имени АДМИНИСТРАТОРА!
    echo.
    pause
    exit /b 1
)
echo.
pause

:: Шаг 4: Удаление временных файлов
echo.
echo [ШАГ 4] Очистка временных файлов...
echo.

del "%TEMP%\aero_v4.reg" >nul 2>&1

echo [✓] Временные файлы удалены
echo.
pause

:: Шаг 5: Создание тестового файла
echo.
echo [ШАГ 5] Создание тестового файла...
echo.

(
echo {Aero}{progname}Test V4{|}{progcode}
echo {echo}"Hello from Aero V4!"{|}
echo {echo}"This is a real Windows window!"{|}
echo {int}#answer = 42{|}
echo {echo}"The answer is: " #answer{|}
echo {pause}{|}
echo {|}
) > "%AERO_PATH%test_v4.aer"

echo [✓] Тестовый файл создан: test_v4.aer
echo.
pause

:: Шаг 6: Обновление иконок
echo.
echo [ШАГ 6] Обновление иконок в проводнике...
echo.

ie4uinit.exe -show >nul 2>&1
echo [•] Остановка explorer...
taskkill /IM explorer.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul
echo [•] Запуск explorer...
start explorer.exe
timeout /t 1 /nobreak >nul

echo [✓] Иконки обновлены
echo.
pause

:: Финал
echo.
echo ╔══════════════════════════════════════════════════╗
echo ║             АССОЦИАЦИЯ ЗАВЕРШЕНА!                ║
echo ╠══════════════════════════════════════════════════╣
echo ║                                                  ║
echo ║  .aer файлы связаны с:                           ║
echo ║  AeroInterpreter_V4.exe                         ║
echo ║                                                  ║
echo ║  ДЕЙСТВИЯ:                                       ║
echo ║  • Двойной клик - запуск программы в окне       ║
echo ║  • ПКМ -> Запустить - запуск в окне             ║
echo ║  • ПКМ -> Редактировать - открыть в блокноте    ║
echo ║                                                  ║
echo ║  Тестовый файл: test_v4.aer                      ║
echo ║                                                  ║
echo ╚══════════════════════════════════════════════════╝
echo.
echo Теперь можете кликнуть на любой .aer файл!
echo.
pause
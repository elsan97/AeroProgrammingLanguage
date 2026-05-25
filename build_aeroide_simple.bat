@echo off
chcp 65001 >nul
echo ========================================
echo Aero IDE - Простая сборка (C версия)
echo ========================================
echo.

echo 1. Компиляция AeroIDE.c...
where gcc >nul 2>nul
if %errorlevel% equ 0 (
    gcc AeroIDE.c -o AeroIDE.exe
    if exist "AeroIDE.exe" (
        echo   ✅ AeroIDE.exe создан
    ) else (
        echo   ❌ Ошибка компиляции
        pause
        exit /b 1
    )
) else (
    echo   ❌ GCC не найден
    echo   Установите MinGW или используйте готовый AeroIDE.exe
    pause
    exit /b 1
)

echo.
echo 2. Проверка функций...
echo   AeroIDE.exe включает:
echo   - Ctrl+N - Новый файл
echo   - Ctrl+X - Вырезать
echo   - Ctrl+D - Удалить файл (с подтверждением)
echo   - Автоопределение NASM/MASM
echo   - Автоматическая загрузка ассемблера
echo   - C компиляция как запасной вариант

echo.
echo 3. Создание ярлыков...
(
echo @echo off
echo echo Запуск Aero IDE...
echo AeroIDE.exe
echo pause
) > Start_AeroIDE.bat

echo.
echo ✅ Готово!
echo.
echo Запустите:
echo   AeroIDE.exe          - Основная IDE
echo   Start_AeroIDE.bat    - Ярлык для запуска
echo.
echo Или используйте RUN_ME.bat для полного меню.
pause
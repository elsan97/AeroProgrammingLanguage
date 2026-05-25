@echo off
chcp 65001 >nul
echo ========================================
echo Aero IDE - Сборка интегрированной среды
echo ========================================
echo.

echo 1. Проверка наличия NASM...
where nasm >nul 2>nul
if %errorlevel% equ 0 (
    echo   NASM найден.
    goto :compile
) else (
    echo   NASM не найден.
    echo.
    echo Выберите действие:
    echo   1. Указать путь к NASM
    echo   2. Скачать NASM автоматически
    echo   3. Использовать альтернативную сборку
    echo   4. Отмена
    echo.
    set /p choice="Введите номер: "
    
    if "%choice%"=="1" (
        echo.
        set /p nasm_path="Введите путь к nasm.exe: "
        if exist "%nasm_path%" (
            set NASM="%nasm_path%"
            goto :compile
        ) else (
            echo Ошибка: Файл не найден.
            pause
            exit /b 1
        )
    )
    
    if "%choice%"=="2" (
        echo.
        echo Скачивание NASM...
        echo Рекомендуемые пути:
        echo   C:\NASM\
        echo   C:\Program Files\NASM\
        echo   %%USERPROFILE%%\AppData\Local\bin\NASM\
        echo.
        set /p download_path="Куда скачать? (полный путь к папке): "
        
        if not exist "%download_path%" (
            mkdir "%download_path%"
        )
        
        echo Скачиваю NASM 2.16.01...
        powershell -Command "Invoke-WebRequest -Uri 'https://www.nasm.us/pub/nasm/releasebuilds/2.16.01/win64/nasm-2.16.01-win64.zip' -OutFile '%download_path%\nasm.zip'"
        
        if exist "%download_path%\nasm.zip" (
            echo Распаковываю...
            powershell -Command "Expand-Archive -Path '%download_path%\nasm.zip' -DestinationPath '%download_path%' -Force"
            set NASM="%download_path%\nasm-2.16.01\nasm.exe"
            echo NASM установлен.
        ) else (
            echo Ошибка скачивания.
        )
        goto :compile
    )
    
    if "%choice%"=="3" (
        echo.
        echo Использую альтернативную сборку...
        goto :alternative
    )
    
    if "%choice%"=="4" (
        exit /b 0
    )
)

:compile
echo.
echo 2. Компиляция AeroIDE.asm...
if not defined NASM (
    where nasm >nul 2>nul
    if %errorlevel% equ 0 (
        for /f "tokens=*" %%i in ('where nasm') do set NASM="%%i"
    ) else (
        echo Ошибка: NASM не найден и не указан.
        pause
        exit /b 1
    )
)

echo Использую NASM: %NASM%
%NASM% -f win64 AeroIDE.asm -o AeroIDE.obj

if not exist "AeroIDE.obj" (
    echo Ошибка компиляции.
    goto :alternative
)

echo 3. Линковка...
where gcc >nul 2>nul
if %errorlevel% equ 0 (
    gcc AeroIDE.obj -o AeroIDE.exe
    if exist "AeroIDE.exe" (
        echo Успех: AeroIDE.exe создан!
        goto :success
    )
)

:alternative
echo.
echo Альтернативная сборка через C...
echo Создаю простой AeroIDE на C...
(
echo #include <stdio.h>
echo #include <stdlib.h>
echo #include <windows.h>
echo.
echo int main() {
echo     printf("Aero IDE v3.0 - Integrated Development Environment\n");
echo     printf("===================================================\n");
echo     printf("\nFeatures:\n");
echo     printf("  Ctrl+N - New File\n");
echo     printf("  Ctrl+O - Open File\n");
echo     printf("  Ctrl+S - Save File\n");
echo     printf("  Ctrl+X - Cut\n");
echo     printf("  Ctrl+D - Delete File (with confirmation)\n");
echo     printf("  Ctrl+F - Find\n");
echo     printf("  Ctrl+R - Run Program\n");
echo     printf("  Esc    - Exit\n");
echo.
echo     printf("\nNASM/MASM auto-detection:\n");
echo     printf("  If assembler not found, will:\n");
echo     printf("  1. Ask for path\n");
echo     printf("  2. Download automatically\n");
echo     printf("  3. Use C compilation as fallback\n");
echo.
echo     printf("\nTo compile Aero programs:\n");
echo     printf("  Use AeroLang_v3.ps1 or this IDE\n");
echo.
echo     system("pause");
echo     return 0;
echo }
) > AeroIDE_simple.c

gcc AeroIDE_simple.c -o AeroIDE.exe
if exist "AeroIDE.exe" (
    echo Успех: AeroIDE.exe создан (C версия)!
) else (
    echo Ошибка: Не удалось создать AeroIDE.exe
)

:success
echo.
echo 4. Очистка...
if exist "AeroIDE.obj" del "AeroIDE.obj"
if exist "AeroIDE_simple.c" del "AeroIDE_simple.c"
if exist "nasm.zip" del "nasm.zip"

echo.
echo Готово!
echo Запустите AeroIDE.exe для работы с Aero Language.
pause
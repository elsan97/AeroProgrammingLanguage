# Aero Language Compiler v4.0
# С проверкой ассемблера и автоматической загрузкой

param(
    [string]$InputFile,
    [switch]$C,
    [string]$Output
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AERO LANGUAGE COMPILER v4.0" -ForegroundColor Yellow
Write-Host "Auto-Assembler Detection Edition" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Проверка входного файла
if (-not $InputFile) {
    Write-Host "Использование: .\AeroLang_v4.ps1 <файл.aer> [опции]" -ForegroundColor Red
    Write-Host "Опции:" -ForegroundColor Gray
    Write-Host "  -C          : Использовать C компиляцию" -ForegroundColor Gray
    Write-Host "  -Output имя : Имя выходного файла" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Примеры:" -ForegroundColor Gray
    Write-Host "  .\AeroLang_v4.ps1 example_aero_base.aer" -ForegroundColor Gray
    exit 1
}

# Проверка расширения файла
if (-not $InputFile.EndsWith(".aer") -and -not $InputFile.EndsWith(".AER")) {
    Write-Host "Ошибка: Файл должен иметь расширение .aer" -ForegroundColor Red
    exit 1
}

# Проверка существования файла
if (-not (Test-Path $InputFile)) {
    Write-Host "Ошибка: Файл не найден: $InputFile" -ForegroundColor Red
    exit 1
}

# Функция проверки наличия ассемблера
function Check-Assembler {
    Write-Host "`nПроверка наличия ассемблера..." -ForegroundColor Gray
    
    # Проверка NASM
    $nasm = Get-Command nasm -ErrorAction SilentlyContinue
    if ($nasm) {
        Write-Host "  ✅ NASM найден: $($nasm.Source)" -ForegroundColor Green
        return @{ Type = "NASM"; Path = $nasm.Source }
    }
    
    # Проверка MASM
    $masm = Get-Command ml -ErrorAction SilentlyContinue
    if ($masm) {
        Write-Host "  ✅ MASM найден: $($masm.Source)" -ForegroundColor Green
        return @{ Type = "MASM"; Path = $masm.Source }
    }
    
    # Проверка стандартных путей NASM
    $commonPaths = @(
        "C:\NASM\nasm.exe",
        "C:\Program Files\NASM\nasm.exe",
        "$env:USERPROFILE\AppData\Local\bin\NASM\nasm.exe",
        "$env:ProgramFiles\NASM\nasm.exe"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            Write-Host "  ✅ NASM найден по пути: $path" -ForegroundColor Green
            return @{ Type = "NASM"; Path = $path }
        }
    }
    
    Write-Host "  ⚠️  Ассемблер не найден" -ForegroundColor Yellow
    return $null
}

# Функция предложения загрузки ассемблера
function Offer-Assembler-Download {
    Write-Host "`nАссемблер не найден. Выберите действие:" -ForegroundColor Yellow
    Write-Host "  1. Указать путь к ассемблеру" -ForegroundColor Gray
    Write-Host "  2. Скачать NASM автоматически" -ForegroundColor Gray
    Write-Host "  3. Использовать C компиляцию" -ForegroundColor Gray
    Write-Host "  4. Отмена" -ForegroundColor Gray
    
    $choice = Read-Host "`nВведите номер (1-4)"
    
    switch ($choice) {
        "1" {
            $path = Read-Host "Введите полный путь к nasm.exe или ml.exe"
            if (Test-Path $path) {
                Write-Host "  ✅ Ассемблер найден: $path" -ForegroundColor Green
                return @{ Type = if ($path -like "*nasm*") { "NASM" } else { "MASM" }; Path = $path }
            } else {
                Write-Host "  ❌ Файл не найден" -ForegroundColor Red
                return Offer-Assembler-Download
            }
        }
        
        "2" {
            Write-Host "`nСкачивание NASM..." -ForegroundColor Gray
            $downloadPath = Read-Host "Куда скачать? (путь к папке, например C:\NASM\)"
            
            if (-not (Test-Path $downloadPath)) {
                New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null
            }
            
            $zipPath = Join-Path $downloadPath "nasm.zip"
            $nasmUrl = "https://www.nasm.us/pub/nasm/releasebuilds/2.16.01/win64/nasm-2.16.01-win64.zip"
            
            try {
                Write-Host "  Скачиваю NASM 2.16.01..." -ForegroundColor Gray
                Invoke-WebRequest -Uri $nasmUrl -OutFile $zipPath
                
                if (Test-Path $zipPath) {
                    Write-Host "  Распаковываю..." -ForegroundColor Gray
                    Expand-Archive -Path $zipPath -DestinationPath $downloadPath -Force
                    
                    $nasmExe = Join-Path $downloadPath "nasm-2.16.01\nasm.exe"
                    if (Test-Path $nasmExe) {
                        Write-Host "  ✅ NASM успешно установлен: $nasmExe" -ForegroundColor Green
                        Remove-Item $zipPath -Force
                        return @{ Type = "NASM"; Path = $nasmExe }
                    }
                }
            } catch {
                Write-Host "  ❌ Ошибка скачивания: $_" -ForegroundColor Red
            }
            
            return Offer-Assembler-Download
        }
        
        "3" {
            Write-Host "  Использую C компиляцию..." -ForegroundColor Gray
            return @{ Type = "C"; Path = $null }
        }
        
        "4" {
            Write-Host "  Отмена компиляции" -ForegroundColor Red
            exit 0
        }
        
        default {
            Write-Host "  Неверный выбор" -ForegroundColor Red
            return Offer-Assembler-Download
        }
    }
}

# Основная логика компиляции
$source = Get-Content -Raw -Path $InputFile
$fileSize = $source.Length

Write-Host "Компиляция: $InputFile ($fileSize байт)" -ForegroundColor Yellow

# Проверяем ассемблер
$assembler = Check-Assembler

if (-not $assembler -and -not $C) {
    $assembler = Offer-Assembler-Download
}

if ($C) {
    $assembler = @{ Type = "C"; Path = $null }
    Write-Host "`nИспользую C компиляцию (принудительно)" -ForegroundColor Gray
}

# Парсинг Aero кода
Write-Host "`nПарсинг Aero кода..." -ForegroundColor Gray

$commands = @()
$variables = @{}
$outputCode = ""
$includes = @("#include <stdio.h>", "#include <stdlib.h>", "#include <string.h>")

$lines = $source -split "`r?`n"
$lineNum = 0

foreach ($line in $lines) {
    $lineNum++
    $line = $line.Trim()
    if ($line -eq "") { continue }
    
    # Парсинг: {command}parameters{|}
    if ($line -match '^\s*\{([^}]+)\}([^{]*)\{\|\}\s*$') {
        $command = $matches[1].Trim()
        $params = $matches[2].Trim()
        
        Write-Host "  Строка $lineNum : {$command}$params{|}" -ForegroundColor DarkGray
        $commands += @{ Command = $command; Params = $params; Line = $lineNum }
        
        # Обработка команд
        switch -Wildcard ($command) {
            "Aero*" {
                $outputCode += "    printf(`"========================================\n`");`n"
                $outputCode += "    printf(`"AERO LANGUAGE PROGRAM\n`");`n"
                $outputCode += "    printf(`"========================================\n\n`");`n"
            }
            
            "echo*" {
                if ($params -match '^"([^"]+)"$') {
                    $text = $matches[1]
                    $outputCode += "    printf(`"$text\n`");`n"
                } elseif ($params -match '^#(\w+)$') {
                    $varName = $matches[1]
                    $outputCode += "    printf(`"%s\n`", $varName);`n"
                } elseif ($params -match '^"([^"]+)"\s+#(\w+)$') {
                    $text = $matches[1]
                    $varName = $matches[2]
                    if ($variables[$varName] -eq "int") {
                        $outputCode += "    printf(`"$text%d\n`", $varName);`n"
                    } else {
                        $outputCode += "    printf(`"$text%s\n`", $varName);`n"
                    }
                }
            }
            
            "str*" {
                if ($params -match '^#(\w+)\s*=\s*"([^"]+)"$') {
                    $varName = $matches[1]
                    $value = $matches[2]
                    $variables[$varName] = "str"
                    $outputCode += "    char $varName[256] = `"$value`";`n"
                }
            }
            
            "int*" {
                if ($params -match '^#(\w+)\s*=\s*(\d+)$') {
                    $varName = $matches[1]
                    $value = $matches[2]
                    $variables[$varName] = "int"
                    $outputCode += "    int $varName = $value;`n"
                }
            }
            
            default {
                $outputCode += "    // Команда: {$command}$params{|}`n"
                $outputCode += "    printf(`"Executing: {$command}$params{|}\n`");`n"
            }
        }
    } else {
        Write-Host "  Строка $lineNum : НЕВЕРНЫЙ СИНТАКСИС: $line" -ForegroundColor Red
    }
}

Write-Host "`nНайдено команд: $($commands.Count)" -ForegroundColor Green
Write-Host "Переменных: $($variables.Count)" -ForegroundColor Green

# Создание C файла
$outputFile = [System.IO.Path]::GetFileNameWithoutExtension($InputFile) + "_compiled.c"
if ($Output) {
    $outputFile = $Output
    if (-not $outputFile.EndsWith(".c")) {
        $outputFile += ".c"
    }
}

$cCode = @"
/* Aero Language - Скомпилированная программа */
/* Исходник: $InputFile */
/* Команд: $($commands.Count) */
/* Переменных: $($variables.Count) */
/* Компилятор: $($assembler.Type) */

$(($includes | ForEach-Object { "$_" }) -join "`n")

int main() {
    // Объявления переменных
$outputCode
    printf("\n========================================\n");
    printf("ПРОГРАММА ВЫПОЛНЕНА\n");
    printf("========================================\n");
    
    return 0;
}
"@

$cCode | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "`nC код создан: $outputFile" -ForegroundColor Green

# Компиляция в зависимости от выбранного метода
$exeFile = [System.IO.Path]::GetFileNameWithoutExtension($outputFile) + ".exe"

if ($assembler.Type -eq "C" -or $assembler.Type -eq "NASM" -or $assembler.Type -eq "MASM") {
    # Используем GCC для компиляции C кода
    $gccPath = Get-Command gcc -ErrorAction SilentlyContinue
    
    if ($gccPath) {
        Write-Host "`nНайден GCC: $($gccPath.Source)" -ForegroundColor Green
        
        try {
            & gcc $outputFile -o $exeFile 2>&1 | Out-Null
            if (Test-Path $exeFile) {
                Write-Host "✅ Исполняемый файл создан: $exeFile" -ForegroundColor Green
                Write-Host "   Запустите: .\$exeFile" -ForegroundColor Gray
            } else {
                Write-Host "⚠️  Ошибка компиляции GCC (но C файл сохранён)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "⚠️  Ошибка компиляции GCC (но C файл сохранён)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`nGCC не найден. C файл сохранён, но не скомпилирован." -ForegroundColor Yellow
        Write-Host "Для компиляции вручную: gcc $outputFile -o $exeFile" -ForegroundColor Gray
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "КОМПИЛЯЦИЯ ЗАВЕРШЕНА!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Итог:" -ForegroundColor Yellow
Write-Host "  Команд распаршено: $($commands.Count)" -ForegroundColor Gray
Write-Host "  Переменных: $($variables.Count)" -ForegroundColor Gray
Write-Host "  C файл: $outputFile" -ForegroundColor Gray
Write-Host "  Метод компиляции: $($assembler.Type)" -ForegroundColor Gray
if (Test-Path $exeFile) {
    Write-Host "  Исполняемый файл: $exeFile" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Следующие шаги:" -ForegroundColor Yellow
Write-Host "  1. Запустите программу: .\$exeFile" -ForegroundColor Gray
Write-Host "  2. Прочитайте AERO_FULL_REFERENCE.md для всех команд" -ForegroundColor Gray
Write-Host "  3. Используйте AeroIDE.exe для удобной разработки" -ForegroundColor Gray
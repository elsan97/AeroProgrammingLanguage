@echo off
chcp 65001 >nul
echo ========================================
echo Aero Language - Complete Build
echo ========================================
echo.

echo Step 1: Checking GCC...
where gcc >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: GCC not found!
    echo Install MinGW or add gcc to PATH
    pause
    exit /b 1
)

echo Step 2: Compiling AeroInterpreter.exe...
echo   This is the REAL interpreter that executes .aer files
gcc AeroInterpreter.c -o AeroInterpreter.exe
if exist "AeroInterpreter.exe" (
    echo   ✅ AeroInterpreter.exe created
) else (
    echo   ❌ Failed to compile AeroInterpreter.exe
    pause
    exit /b 1
)

echo.
echo Step 3: Compiling AeroLauncher.exe...
echo   This is the file association handler
gcc AeroLauncher.c -o AeroLauncher.exe
if exist "AeroLauncher.exe" (
    echo   ✅ AeroLauncher.exe created
) else (
    echo   ❌ Failed to compile AeroLauncher.exe
    pause
    exit /b 1
)

echo.
echo Step 4: Testing interpreter...
echo   Creating test file...
echo {Aero}Test Program{|} > test_interpreter.aer
echo {str}#message = "Hello from Interpreter!"{|} >> test_interpreter.aer
echo {echo}#message{|} >> test_interpreter.aer
echo {int}#number = 42{|} >> test_interpreter.aer
echo {echo}"The answer is: " #number{|} >> test_interpreter.aer

echo   Running test...
AeroInterpreter.exe test_interpreter.aer

echo.
echo Step 5: How to use:
echo.
echo OPTION A - Direct execution (recommended):
echo   1. Run as administrator: register_aero_assoc.bat
echo   2. Now double-click any .aer file to execute it!
echo.
echo OPTION B - Manual execution:
echo   AeroInterpreter.exe file.aer
echo   or
echo   AeroLauncher.exe file.aer
echo.
echo OPTION C - IDE mode:
echo   Just run AeroInterpreter.exe (without arguments)
echo.
echo ========================================
echo BUILD COMPLETE!
echo ========================================
echo.
echo Files created:
echo   ✅ AeroInterpreter.exe - Real interpreter with command database
echo   ✅ AeroLauncher.exe    - File association handler
echo   ✅ register_aero_assoc.bat - Setup file associations
echo.
echo Commands currently implemented in interpreter:
echo   {Aero}    - Program start
echo   {echo}    - Print text/variables
echo   {str}     - String variables
echo   {int}     - Integer variables
echo   {input}   - User input
echo.
echo To add more commands: edit AeroInterpreter.c
echo.
pause
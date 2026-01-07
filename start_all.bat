@echo off
title SmartFinance - Launcher
color 0A

echo ====================================
echo    SmartFinance App Launcher
echo ====================================
echo.

echo Checking prerequisites...
echo.

REM Check MySQL
echo [1/3] Checking MySQL...
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -psiow@@2468 -e "SELECT 1;" >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] MySQL is not running!
    echo     Starting MySQL service...
    net start MySQL80 >nul 2>&1
    timeout /t 3 /nobreak >nul

    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -psiow@@2468 -e "SELECT 1;" >nul 2>&1
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to start MySQL. Please start it manually.
        pause
        exit /b 1
    )
)
echo [OK] MySQL is running

REM Check Python
echo [2/3] Checking Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH
    pause
    exit /b 1
)
echo [OK] Python is available

REM Check Flutter
echo [3/3] Checking Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    pause
    exit /b 1
)
echo [OK] Flutter is available

echo.
echo ====================================
echo All prerequisites are ready!
echo ====================================
echo.
echo Starting SmartFinance...
echo.
echo [INFO] Backend will open in new window
echo [INFO] Frontend will open in new window
echo.

REM Start Backend in new window
start "SmartFinance Backend" cmd /k "cd /d %~dp0 && start_backend.bat"

REM Wait 3 seconds for backend to start
echo Waiting for backend to start...
timeout /t 3 /nobreak >nul

REM Start Frontend in new window
start "SmartFinance Frontend" cmd /k "cd /d %~dp0 && start_flutter.bat"

echo.
echo ====================================
echo SmartFinance is starting!
echo ====================================
echo.
echo Backend: http://127.0.0.1:5000
echo Frontend: Opening in Chrome...
echo.
echo Press any key to close this launcher window...
echo (Backend and Frontend will keep running)
pause >nul

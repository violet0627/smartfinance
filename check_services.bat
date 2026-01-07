@echo off
title SmartFinance - Service Checker
color 0B

echo ====================================
echo   SmartFinance Service Checker
echo ====================================
echo.

REM Check MySQL Service
echo [1/3] MySQL Service Status:
sc query MySQL80 | find "RUNNING" >nul
if %errorlevel% equ 0 (
    echo     [OK] MySQL service is RUNNING
) else (
    echo     [X] MySQL service is NOT RUNNING
    echo     Run: net start MySQL80
)

REM Test MySQL Connection
echo.
echo [2/3] MySQL Connection Test:
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -psiow@@2468 -e "SELECT VERSION();" 2>nul
if %errorlevel% equ 0 (
    echo     [OK] Can connect to MySQL
) else (
    echo     [X] Cannot connect to MySQL
)

REM Check Flask Backend
echo.
echo [3/3] Flask Backend Status:
curl -s http://127.0.0.1:5000/api/auth/user/1 >nul 2>&1
if %errorlevel% equ 0 (
    echo     [OK] Flask backend is RUNNING on port 5000
) else (
    echo     [X] Flask backend is NOT RUNNING
    echo     Run: start_backend.bat
)

echo.
echo ====================================
echo Check complete!
echo ====================================
echo.

REM Show active ports
echo Active services on common ports:
netstat -ano | findstr ":5000 :3306" 2>nul
if %errorlevel% neq 0 (
    echo     No services found on ports 5000 or 3306
)

echo.
pause

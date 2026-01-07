@echo off
title SmartFinance - Stop All Services
color 0C

echo ====================================
echo   SmartFinance - Stopping Services
echo ====================================
echo.

echo Stopping Flask backend...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":5000" ^| findstr "LISTENING"') do (
    echo Killing process %%a
    taskkill /F /PID %%a >nul 2>&1
)

echo Stopping Flutter...
taskkill /F /IM dart.exe >nul 2>&1
taskkill /F /IM flutter.exe >nul 2>&1

echo.
echo [INFO] Backend and Frontend stopped
echo [INFO] MySQL service is still running (as a system service)
echo.
echo If you want to stop MySQL too, run:
echo   net stop MySQL80
echo.
pause

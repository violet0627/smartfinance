@echo off
echo ========================================
echo  SmartFinance Application Launcher
echo ========================================
echo.
echo This will start:
echo 1. MySQL Database (port 3306)
echo 2. Python Flask Backend (port 5000)
echo 3. Android Emulator with App
echo.
echo IMPORTANT: Make sure MySQL is already running!
echo.
pause

echo.
echo [1/3] Starting Backend Server...
echo.
start "SmartFinance Backend" cmd /k "cd backend && python run.py"

timeout /t 3 /nobreak >nul

echo.
echo [2/3] Backend started! Now starting Android App...
echo.
echo Opening new terminal for Flutter...
start "SmartFinance Flutter" cmd /k "flutter run"

echo.
echo ========================================
echo  All services starting!
echo ========================================
echo.
echo Backend API: http://localhost:5000
echo.
echo Close this window when you're done testing.
echo.
pause

@echo off
echo ========================================
echo   SmartFinance - Starting Demo Setup
echo ========================================
echo.

echo [1/3] Starting Backend Server...
cd backend
start cmd /k "python run.py"
timeout /t 3

echo.
echo [2/3] Backend started on http://192.168.1.38:5000
echo.
echo [3/3] Ready for demo!
echo.
echo ========================================
echo   DEMO CHECKLIST:
echo ========================================
echo   [ ] Backend is running (this window)
echo   [ ] Phone connected to SAME WiFi
echo   [ ] App installed on phone
echo   [ ] Ready to demo!
echo ========================================
echo.
echo Press any key when done demoing to stop backend...
pause
echo.
echo Stopping backend...
taskkill /f /im python.exe
echo Done!
pause

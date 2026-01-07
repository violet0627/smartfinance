@echo off
echo ====================================
echo  SmartFinance Backend Server
echo ====================================
echo.

echo Checking MySQL connection...
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -psiow@@2468 -e "SELECT 'MySQL is running!' AS Status;" 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] MySQL is not running or connection failed!
    echo Please start MySQL service first.
    pause
    exit /b 1
)

echo [OK] MySQL is running
echo.

echo Starting Flask backend server...
cd backend
python run.py

pause

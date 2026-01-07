# SmartFinance - Startup Guide

## Quick Start (Recommended)

### Option 1: Start Everything Automatically
1. Double-click `start_all.bat`
2. Wait for both windows to open (Backend and Frontend)
3. Your app will open in Chrome automatically

### Option 2: Start Manually
1. **Backend**: Double-click `start_backend.bat`
2. **Frontend**: Double-click `start_flutter.bat`

## Batch Scripts Explained

### `start_all.bat` - Launch Everything
- ✅ Checks if MySQL is running (starts it if needed)
- ✅ Checks Python and Flutter
- ✅ Opens Backend in new window
- ✅ Opens Frontend in new window
- **Use this for daily development!**

### `start_backend.bat` - Backend Only
- Starts Flask server on http://127.0.0.1:5000
- Checks MySQL connection first
- Keep this window open while developing

### `start_flutter.bat` - Frontend Only
- Starts Flutter app on Chrome
- For frontend development

### `check_services.bat` - Status Checker
- Shows which services are running
- Checks MySQL service status
- Tests MySQL connection
- Checks if Flask is responding
- **Run this if something isn't working!**

### `stop_all.bat` - Stop Everything
- Stops Flask backend
- Stops Flutter app
- Leaves MySQL running (system service)

## Troubleshooting

### MySQL Won't Start
```bash
# Check if service exists
sc query MySQL80

# Start manually
net start MySQL80

# If still fails, open Services:
# Windows + R → services.msc → Find MySQL80 → Start
```

### Backend Won't Start
```bash
# Check if port 5000 is in use
netstat -ano | findstr :5000

# Kill the process if needed
taskkill /F /PID [process_id]
```

### Flutter Won't Start
```bash
# Check Flutter doctor
flutter doctor

# Clear Flutter cache
flutter clean
flutter pub get
```

## Development Workflow

1. **Start Development**:
   ```
   Double-click: start_all.bat
   ```

2. **Check Status**:
   ```
   Double-click: check_services.bat
   ```

3. **Stop Development**:
   ```
   Double-click: stop_all.bat
   OR press Ctrl+C in each window
   ```

## What Runs Where

| Component | Location | Port | Auto-Start? |
|-----------|----------|------|-------------|
| MySQL | System Service | 3306 | ✅ Yes |
| Flask Backend | Terminal | 5000 | ❌ Manual |
| Flutter App | Chrome | 53887+ | ❌ Manual |

## Tips

- **MySQL** usually auto-starts with Windows
- **Backend and Frontend** need to be started manually each time
- Keep the terminal windows open while developing
- Use `check_services.bat` to verify everything is running

## Common Ports

- **3306**: MySQL Database
- **5000**: Flask Backend API
- **53887+**: Flutter Debug Service (changes each run)

## Need Help?

1. Run `check_services.bat` to see what's wrong
2. Check the error messages in the terminal windows
3. Make sure all prerequisites are installed (Python, Flutter, MySQL)

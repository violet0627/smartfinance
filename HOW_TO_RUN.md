# 🚀 How to Run SmartFinance Application

**Complete Step-by-Step Guide**
**Last Updated:** January 9, 2026

---

## 📋 Prerequisites (Install These First)

Before running the app, ensure you have these installed:

1. **MySQL Server 8.0** (Database)
   - Download: https://dev.mysql.com/downloads/installer/
   - Must be running on port 3306
   - Username: `root`
   - Password: `siow@@2468` (as configured in `.env`)

2. **Python 3.14.2** (Backend)
   - Download: https://www.python.org/downloads/
   - Check: `python --version`

3. **Flutter 3.32.8** (Mobile App)
   - Download: https://flutter.dev/docs/get-started/install
   - Check: `flutter --version`

4. **Android Studio** (For Emulator)
   - Download: https://developer.android.com/studio
   - Install Android SDK and create an emulator

---

## 🏗️ System Architecture

SmartFinance has **3 components** that work together:

```
┌─────────────────────────────────────────────────────┐
│  📱 Flutter Mobile App (Android)                     │
│  - User Interface                                    │
│  - Runs on Android Emulator or Physical Device      │
└──────────────────┬──────────────────────────────────┘
                   │ HTTP Requests
                   │ (http://10.0.2.2:5000/api)
                   ▼
┌─────────────────────────────────────────────────────┐
│  🐍 Python Flask Backend (API Server)               │
│  - REST API Endpoints                                │
│  - Business Logic                                    │
│  - Running on: http://localhost:5000                 │
└──────────────────┬──────────────────────────────────┘
                   │ SQL Queries
                   │ (mysql+pymysql)
                   ▼
┌─────────────────────────────────────────────────────┐
│  🗄️ MySQL Database                                   │
│  - Stores all data (users, transactions, etc.)      │
│  - Running on: localhost:3306                        │
│  - Database name: smartfinance                       │
└─────────────────────────────────────────────────────┘
```

---

## 🎯 Quick Start (Easiest Method)

### Step 1: Start MySQL
1. Open **Services** (Windows key + R, type `services.msc`)
2. Find **MySQL80** service
3. Right-click → **Start** (if not already running)
4. OR: Open **MySQL Workbench** and connect to localhost

### Step 2: Run the Startup Script
1. Navigate to project folder: `C:\Users\Elaina\Desktop\smartfinance2`
2. Double-click **`START_APP.bat`**
3. Wait for backend to start (3 seconds)
4. Two terminals will open:
   - **Terminal 1**: Backend server (Flask)
   - **Terminal 2**: Flutter app

### Step 3: Wait for App to Install
- First time: Takes 2-3 minutes to build and install
- Subsequent runs: Takes 30-60 seconds
- Watch Terminal 2 for progress

### Step 4: Use the App!
- App will automatically open on your Android emulator
- You can now register/login and use all features

---

## 📝 Manual Start (Detailed Method)

If you prefer to start each component manually:

### Step 1: Start MySQL Database

**Option A - Using MySQL Workbench:**
1. Open **MySQL Workbench**
2. Click on **Local instance MySQL80**
3. Enter password: `siow@@2468`
4. Connection successful = MySQL is running ✅

**Option B - Using Command Line:**
```bash
# Check if MySQL is running
mysql -u root -p
# Enter password: siow@@2468

# Should see:
# mysql>
```

**Option C - Using Services:**
1. Press **Windows + R**
2. Type `services.msc` and press Enter
3. Find **MySQL80** in the list
4. Right-click → **Start** (if stopped)
5. Status should show **Running**

### Step 2: Start Backend Server

1. Open **Command Prompt** or **Terminal**
2. Navigate to backend folder:
   ```bash
   cd C:\Users\Elaina\Desktop\smartfinance2\backend
   ```
3. Start Flask server:
   ```bash
   python run.py
   ```
4. You should see:
   ```
   * Running on http://127.0.0.1:5000
   * Running on http://192.168.1.38:5000
   ```
5. ✅ Backend is ready when you see "Running on..."

**Keep this terminal open!** Closing it will stop the backend.

### Step 3: Start Android Emulator

1. Open **Android Studio**
2. Click **Device Manager** (phone icon on right sidebar)
3. Find your emulator (e.g., "Medium Phone API 36")
4. Click the **▶️ Play** button
5. Wait 30-60 seconds for emulator to fully boot
6. Emulator is ready when you see the home screen

### Step 4: Run Flutter App

1. Open a **NEW** Command Prompt/Terminal (don't close the backend one!)
2. Navigate to project root:
   ```bash
   cd C:\Users\Elaina\Desktop\smartfinance2
   ```
3. Make sure emulator is detected:
   ```bash
   flutter devices
   ```
   Should show something like:
   ```
   emulator-5554 (mobile) • emulator-5554 • android-x86 • Android 13 (API 36)
   ```
4. Run the app:
   ```bash
   flutter run
   ```
5. First time: Takes 2-3 minutes to build APK
6. Subsequent runs: Takes 30-60 seconds
7. App will auto-install and open on emulator

**Keep this terminal open too!** It shows app logs and errors.

---

## 🔍 How to Verify Everything is Working

### Check 1: MySQL Running
```bash
mysql -u root -p
# Enter password: siow@@2468
# If you get mysql> prompt, MySQL is running ✅
```

### Check 2: Backend Running
Open browser and go to:
- http://localhost:5000

You should see: "Cannot GET /" (this is normal! It means server is running)

Try API endpoint:
- http://localhost:5000/api/auth/check

Should return JSON response (not an error page)

### Check 3: Emulator Running
- Android emulator window should be open
- You should see Android home screen
- Status bar at top should show time

### Check 4: App Installed
- Look for **SmartFinance** app icon on emulator
- App should auto-open after flutter run
- You should see the splash screen → Login screen

---

## 🔗 How They Connect

### Frontend ➡️ Backend Connection
- **In Emulator:** Flutter app uses `http://10.0.2.2:5000/api`
  - `10.0.2.2` is the emulator's way to access host machine's `localhost`
  - Port `5000` is where Flask backend is running

- **Important:** Don't use `localhost` or `127.0.0.1` in the Flutter app when running on emulator - it will try to connect to the emulator itself, not your computer!

### Backend ➡️ Database Connection
- **Connection String:** `mysql+pymysql://root:siow%40%402468@localhost:3306/smartfinance`
  - Username: `root`
  - Password: `siow@@2468` (URL-encoded as `siow%40%402468`)
  - Host: `localhost` (same machine)
  - Port: `3306` (MySQL default)
  - Database: `smartfinance`

---

## 🛑 How to Stop the App

1. **Stop Flutter App:**
   - Press `q` in the Flutter terminal
   - Or: Close the terminal window

2. **Stop Backend:**
   - Press `Ctrl + C` in the Backend terminal
   - Or: Close the terminal window

3. **Stop Emulator:**
   - Click X button on emulator window
   - Or: In Android Studio, click **Stop** in Device Manager

4. **Stop MySQL (Optional):**
   - Usually keep it running
   - To stop: Services → MySQL80 → Right-click → Stop

---

## ⚠️ Common Issues and Solutions

### Issue 1: "Connection Timeout" when logging in
**Cause:** Backend server is not running
**Solution:**
1. Check if backend terminal is open
2. Look for "Running on http://127.0.0.1:5000"
3. If not, restart backend: `cd backend && python run.py`

### Issue 2: "Can't connect to MySQL server"
**Cause:** MySQL is not running
**Solution:**
1. Open Services (services.msc)
2. Find MySQL80 and start it
3. Or open MySQL Workbench and connect

### Issue 3: "INSTALL_FAILED_INSUFFICIENT_STORAGE"
**Cause:** Emulator storage is full
**Solution:**
1. In emulator, Settings → Storage
2. Clear cache or uninstall unused apps
3. Or: Create a new emulator with more storage

### Issue 4: "No devices found" when running flutter
**Cause:** Emulator is not running
**Solution:**
1. Open Android Studio
2. Start emulator from Device Manager
3. Wait until fully booted
4. Run `flutter devices` to confirm

### Issue 5: Backend shows errors about email sending
**Cause:** Gmail SMTP requires app password (not your regular password)
**Solution:**
- This is **normal** and **doesn't affect the app**
- Registration still works, just email verification won't be sent
- You can use the app without email verification

### Issue 6: App is in light mode, but I set dark mode
**Cause:** New dark mode feature just added
**Solution:**
1. Go to Settings in the app
2. Tap on "Theme" under Display section
3. Select Dark mode
4. Theme will change immediately

---

## 📱 Using the App

### First Time Setup:
1. App opens to Splash Screen → Login Screen
2. Tap **"Sign Up"** to create account
3. Fill in:
   - Email
   - Full Name
   - Password (min 6 characters)
4. Tap **Register**
5. Login with your credentials

### Main Features:
- **Dashboard:** Overview of finances
- **Transactions:** Add income/expenses
- **Budgets:** Create and track budgets
- **Investments:** Manage investment portfolio
- **Goals:** Set financial goals
- **Reports:** View analytics and charts
- **Gamification:** Earn XP, achievements, streaks
- **Settings:** Theme, notifications, profile

### New Features (Just Added!):
- **Dark Mode:** Settings → Display → Theme
- **Security Sessions:** Track active login sessions
- **Activity Log:** See security events
- **Recurring Transactions:** Automate regular payments (backend ready, UI pending)

---

## 🎨 Changing Between Light and Dark Mode

1. Open app
2. Go to **Settings** (profile icon in bottom nav)
3. Find **"Display"** section
4. Tap **"Theme"**
5. Choose:
   - **Light** - Classic bright theme
   - **Dark** - Eye-friendly dark theme
   - **System Default** - Follows device setting
6. Theme changes instantly!

---

## 🔧 Project Structure

```
smartfinance2/
├── backend/               # Python Flask API
│   ├── app/
│   │   ├── models/       # Database models
│   │   ├── routes/       # API endpoints
│   │   └── __init__.py   # App factory
│   ├── config.py         # Database configuration
│   ├── requirements.txt  # Python dependencies
│   └── run.py           # Server entry point
│
├── lib/                  # Flutter mobile app
│   ├── screens/         # UI screens
│   ├── services/        # API services
│   ├── utils/           # Utilities (themes, colors)
│   └── providers/       # State management
│
├── database/            # SQL migration files
│   └── migrations/      # Database schema updates
│
└── START_APP.bat        # Easy startup script ✨
```

---

## 📊 Database Information

**Database Name:** `smartfinance`
**Tables:** 15 tables total
- Users, Transactions, Budgets, Investments
- Goals, Achievements, UserAchievements
- SecurityLogs, UserSessions
- RecurringTransactions
- And more...

**Location:** `localhost:3306`
**Access:** MySQL Workbench or command line

---

## 💡 Development Tips

### Hot Reload (Flutter):
- Save any `.dart` file
- Press `r` in Flutter terminal to hot reload
- Press `R` for full restart
- Changes appear instantly on emulator

### Backend Changes:
- Flask auto-reloads when you save `.py` files
- Watch backend terminal for restart messages
- No need to manually restart

### Database Changes:
- Use MySQL Workbench to view/edit data
- Run migrations in `backend/migrations/` folder
- Or let SQLAlchemy auto-create tables on first run

---

## 🆘 Getting Help

If you encounter issues:

1. **Check all 3 components are running:**
   - MySQL: `mysql -u root -p`
   - Backend: Look for "Running on http://127.0.0.1:5000"
   - Emulator: Android home screen visible

2. **Check terminal outputs:**
   - Backend terminal shows API requests/errors
   - Flutter terminal shows app logs/errors

3. **Check connection:**
   - Backend can connect to MySQL
   - Flutter can connect to backend (10.0.2.2:5000)

4. **Common fixes:**
   - Restart backend server
   - Restart emulator
   - Run `flutter clean` then `flutter run`

---

## ✅ Success Checklist

Before using the app, verify:
- ✅ MySQL service is running
- ✅ Backend terminal shows "Running on http://127.0.0.1:5000"
- ✅ Android emulator is fully booted
- ✅ Flutter terminal shows "Syncing files to device"
- ✅ SmartFinance app opens on emulator
- ✅ You can see login screen

All checked? You're ready to use SmartFinance! 🎉

---

**Quick Start:** Just double-click `START_APP.bat` and wait!

**Manual Start:**
1. Start MySQL (services.msc → MySQL80 → Start)
2. Run backend: `cd backend && python run.py`
3. Start emulator (Android Studio → Device Manager)
4. Run app: `flutter run`

**Need Help?** Read the "Common Issues" section above.

---

**Last Updated:** January 9, 2026
**Version:** 2.1.0
**Status:** Production Ready ✅

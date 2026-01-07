# How to Check If Services Are Running

## Method 1: Use the Check Script (Easiest)

1. Double-click `check_services.bat`
2. Read the output:
   ```
   [OK] = Service is running ✅
   [X]  = Service is NOT running ❌
   ```

## Method 2: Manual Checks

### Check MySQL Service

**Option A: Using Services Manager**
1. Press `Windows + R`
2. Type: `services.msc`
3. Press Enter
4. Find "MySQL80" in the list
5. Status should say "Running"

**Option B: Using Command Prompt**
```bash
# Open Command Prompt and run:
sc query MySQL80
```
Look for: `STATE: 4 RUNNING`

**Option C: Test Connection**
```bash
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -psiow@@2468 -e "SELECT 'MySQL is working!' AS Status;"
```
Should show: `MySQL is working!`

---

### Check Flask Backend

**Option A: Open in Browser**
1. Open Chrome
2. Go to: `http://127.0.0.1:5000/api/auth/user/1`
3. If you see JSON response = Backend is running ✅
4. If you see error page = Backend is NOT running ❌

**Option B: Using Command Prompt**
```bash
# Check if port 5000 is in use
netstat -ano | findstr :5000
```
If you see output with "LISTENING" = Backend is running ✅

**Option C: Using PowerShell**
```powershell
curl http://127.0.0.1:5000/api/auth/user/1
```

---

### Check Flutter App

**Visual Check:**
- Is Chrome open with your app?
- Can you see the SmartFinance interface?
- If yes = Running ✅

**Command Check:**
```bash
# Check if Dart/Flutter processes are running
tasklist | findstr dart
tasklist | findstr flutter
```

---

## Quick Status Dashboard

| What to Check | How to Check | Expected Result |
|---------------|--------------|-----------------|
| **MySQL Service** | Services.msc | Status: Running |
| **MySQL Connection** | Run check_services.bat | [OK] Can connect to MySQL |
| **Flask Backend** | Open http://127.0.0.1:5000 | JSON response |
| **Flask Port** | netstat -ano \| findstr :5000 | Shows LISTENING |
| **Flutter App** | Look at Chrome | App is visible |

---

## Common Issues & Solutions

### MySQL Not Running
```bash
# Start MySQL service
net start MySQL80

# If that fails, use Services Manager:
# Windows + R → services.msc → MySQL80 → Start
```

### Flask Backend Not Running
```bash
# Start it manually
cd C:\Users\Elaina\Desktop\smartfinance2
start_backend.bat

# Or check what's using port 5000:
netstat -ano | findstr :5000
# Kill the process if needed:
taskkill /F /PID [number]
```

### Flutter Not Running
```bash
# Just restart it
cd C:\Users\Elaina\Desktop\smartfinance2
flutter run -d chrome
```

---

## Step-by-Step Visual Guide

### 1. Check Everything at Once
```
1. Navigate to: C:\Users\Elaina\Desktop\smartfinance2
2. Double-click: check_services.bat
3. Read the output
```

### 2. If MySQL Shows [X]
```
1. Press Windows + R
2. Type: services.msc
3. Find: MySQL80
4. Right-click → Start
```

### 3. If Flask Shows [X]
```
1. Navigate to project folder
2. Double-click: start_backend.bat
3. Keep the window open
```

### 4. If Everything Shows [OK]
```
✅ You're good to go!
✅ Run: start_flutter.bat
✅ Start coding!
```

---

## Pro Tips

1. **Before coding each day**:
   - Run `check_services.bat`
   - Fix anything showing [X]
   - Then run `start_all.bat`

2. **If something breaks**:
   - Run `stop_all.bat`
   - Wait 5 seconds
   - Run `start_all.bat`

3. **MySQL auto-starts**:
   - Usually starts with Windows
   - Rarely needs manual start
   - If it won't start, restart your computer

4. **Backend needs manual start**:
   - Every time you restart your computer
   - Every time you close the terminal
   - Use `start_backend.bat` for convenience

---

## Quick Commands Reference

```bash
# Check MySQL
sc query MySQL80

# Start MySQL
net start MySQL80

# Check Backend
netstat -ano | findstr :5000

# Check all services
check_services.bat

# Start everything
start_all.bat

# Stop everything
stop_all.bat
```

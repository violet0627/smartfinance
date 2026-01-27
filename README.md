# SmartFinance - Complete Personal Finance Management App

A comprehensive financial management application built with Flutter (frontend) and Python Flask (backend).

## ✅ ALL MAIN FEATURES: 100% COMPLETE

See [FEATURES_STATUS.md](FEATURES_STATUS.md) for detailed feature list.

---

## 📋 Features

### Core Features (All Implemented ✅)
1. **User Authentication** - Registration, login, JWT tokens
2. **Email Verification** - Automated email verification system
3. **Password Reset** - Secure password recovery
4. **Transaction Management** - Track income/expenses
5. **Budget Management** - Monthly budgets with alerts
6. **Investment Portfolio** - Track stocks, crypto, bonds, real estate
7. **Financial Goals** - Savings goals with progress tracking
8. **Analytics & Reports** - Charts, trends, spending analysis
9. **Gamification** - XP, levels, achievements, streaks
10. **Settings & Preferences** - Profile, notifications, display settings
11. **Security Features** - Email verification, 2FA, password security

### Security Features ✅
- Email verification system
- Two-Factor Authentication (TOTP)
- Password strength requirements
- JWT-based authentication
- Secure password hashing (bcrypt)
- Security settings dashboard

---

## 🚀 How to Run the Application

**IMPORTANT:** This is a **full-stack application** that requires 3 components to run:

1. **MySQL Database** (stores all data)
2. **Python Flask Backend** (API server)
3. **Flutter Frontend** (mobile/web app)

### Quick Start (Easiest Method)

#### Option 1: Use Batch Scripts (Windows)

1. **Start Everything:**
   ```
   Double-click: start_all.bat
   ```
   This will:
   - Check if MySQL is running
   - Start the Flask backend
   - Start the Flutter app
   - Open app in Chrome

2. **Check Status:**
   ```
   Double-click: check_services.bat
   ```

3. **Stop Everything:**
   ```
   Double-click: stop_all.bat
   OR press Ctrl+C in each terminal
   ```

#### Option 2: Manual Setup (All Platforms)

Follow the detailed instructions below.

---

## 📦 Prerequisites

Before running the application, install these:

### 1. MySQL Database
- **Download:** https://dev.mysql.com/downloads/installer/
- **Version:** MySQL 8.0+
- **Installation:** Install MySQL Community Server
- **Important:** Remember your root password!

### 2. Python
- **Download:** https://www.python.org/downloads/
- **Version:** Python 3.8+
- **Installation:** Make sure to check "Add Python to PATH"

### 3. Flutter
- **Download:** https://docs.flutter.dev/get-started/install
- **Version:** Flutter 3.0+
- **Installation:** Follow Flutter installation guide for your OS

### 4. Code Editor (Optional but Recommended)
- **VS Code:** https://code.visualstudio.com/
- **Extensions:** Flutter, Dart, Python

---

## 🔧 Installation & Setup

### Step 1: Database Setup

1. **Start MySQL Service:**

   **Windows:**
   ```bash
   # Open Command Prompt as Administrator
   net start MySQL80
   ```

   **macOS/Linux:**
   ```bash
   sudo systemctl start mysql
   # OR
   sudo service mysql start
   ```

2. **Create Database:**
   ```bash
   # Login to MySQL
   mysql -u root -p
   # Enter your MySQL password

   # Create database
   CREATE DATABASE smartfinance;

   # Create user (optional, for security)
   CREATE USER 'smartfinance_user'@'localhost' IDENTIFIED BY 'your_password';
   GRANT ALL PRIVILEGES ON smartfinance.* TO 'smartfinance_user'@'localhost';
   FLUSH PRIVILEGES;

   # Exit MySQL
   EXIT;
   ```

3. **Import Database Schema:**
   ```bash
   # Navigate to project directory
   cd C:\Users\Elaina\Desktop\smartfinance2\backend

   # Import schema
   mysql -u root -p smartfinance < database/schema.sql
   ```

4. **Run Migrations:**
   ```bash
   # Import email verification tables
   mysql -u root -p smartfinance < migrations/email_verification.sql

   # Import 2FA tables
   mysql -u root -p smartfinance < migrations/add_two_factor_auth.sql
   ```

### Step 2: Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd C:\Users\Elaina\Desktop\smartfinance2\backend
   ```

2. **Create virtual environment (recommended):**
   ```bash
   # Windows
   python -m venv venv
   venv\Scripts\activate

   # macOS/Linux
   python3 -m venv venv
   source venv/bin/activate
   ```

3. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment variables:**

   Create a `.env` file in the `backend` folder:
   ```env
   # Database Configuration
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=your_mysql_password
   DB_NAME=smartfinance

   # JWT Secret (generate a random string)
   JWT_SECRET=your_super_secret_jwt_key_here_12345

   # Email Configuration (for email verification)
   MAIL_SERVER=smtp.gmail.com
   MAIL_PORT=587
   MAIL_USE_TLS=True
   MAIL_USERNAME=your-email@gmail.com
   MAIL_PASSWORD=your-app-password
   MAIL_DEFAULT_SENDER=noreply@smartfinance.com

   # Frontend URL (for email links)
   FRONTEND_URL=http://localhost:3000
   ```

   **Note:** For Gmail, you need to generate an App Password:
   - Go to Google Account Settings
   - Security → 2-Step Verification → App passwords
   - Generate password for "Mail"
   - Use that password in MAIL_PASSWORD

5. **Start the Flask backend:**
   ```bash
   python run.py
   ```

   You should see:
   ```
   * Running on http://127.0.0.1:5000
   ```

   **Keep this terminal window open!**

### Step 3: Frontend Setup

1. **Open a NEW terminal** and navigate to project root:
   ```bash
   cd C:\Users\Elaina\Desktop\smartfinance2
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Update API URL (if needed):**

   Open `lib/services/api_service.dart` and verify the baseUrl:
   ```dart
   static const String baseUrl = 'http://127.0.0.1:5000/api';
   ```

4. **Run the Flutter app:**

   **For Web (Chrome):**
   ```bash
   flutter run -d chrome
   ```

   **For Mobile Emulator:**
   ```bash
   # First, start an emulator
   # Then run:
   flutter run
   ```

   **For Windows Desktop:**
   ```bash
   flutter run -d windows
   ```

---

## 🎯 Usage Guide

### First Time Setup

1. **Start all three components:**
   - MySQL database (service should be running)
   - Flask backend (`python run.py`)
   - Flutter app (`flutter run -d chrome`)

2. **Register a new account:**
   - Open the app
   - Click "Sign Up"
   - Fill in your details
   - Create account

3. **Verify your email:**
   - Check your email inbox
   - Copy the verification token
   - Paste in verification screen
   - OR click "Skip for now" (can verify later)

4. **Start using the app:**
   - Add your first transaction
   - Create a budget
   - Set financial goals
   - Track investments
   - Explore analytics

### Daily Usage

1. **Start the app:**
   ```bash
   # Method 1: Use batch script (Windows)
   Double-click: start_all.bat

   # Method 2: Manual
   # Terminal 1: Start backend
   cd backend
   python run.py

   # Terminal 2: Start frontend
   flutter run -d chrome
   ```

2. **Login with your credentials**

3. **Use the app:**
   - Dashboard shows your financial summary
   - Add transactions as they occur
   - Check budget progress
   - Update investment values
   - Track goal progress
   - View analytics and reports

---

## 📁 Project Structure

```
smartfinance2/
├── backend/                    # Python Flask Backend
│   ├── app/
│   │   ├── models/            # Database models
│   │   ├── routes/            # API endpoints
│   │   ├── utils/             # Helper functions
│   │   └── __init__.py        # App initialization
│   ├── database/              # Database schema
│   ├── migrations/            # Database migrations
│   ├── requirements.txt       # Python dependencies
│   ├── config.py             # Configuration
│   └── run.py                # Application entry point
│
├── lib/                       # Flutter Frontend
│   ├── models/               # Data models
│   ├── screens/              # UI screens
│   │   ├── auth/            # Login, register, verify
│   │   ├── dashboard/       # Main dashboard
│   │   ├── transactions/    # Transaction management
│   │   ├── budgets/         # Budget management
│   │   ├── investments/     # Portfolio management
│   │   ├── goals/           # Financial goals
│   │   ├── analytics/       # Charts & analytics
│   │   ├── reports/         # Reports generation
│   │   ├── gamification/    # Achievements, levels
│   │   └── settings/        # Settings & security
│   ├── services/            # API service layer
│   ├── utils/               # Helper functions
│   ├── widgets/             # Reusable UI components
│   └── main.dart            # Application entry point
│
├── start_all.bat             # Start everything (Windows)
├── start_backend.bat         # Start backend only
├── start_flutter.bat         # Start frontend only
├── check_services.bat        # Check status
├── stop_all.bat             # Stop everything
│
├── README.md                 # This file
├── FEATURES_STATUS.md        # Detailed feature list
├── README_STARTUP.md         # Quick startup guide
├── EMAIL_VERIFICATION_GUIDE.md
├── SECURITY_FEATURES_GUIDE.md
└── TWO_FACTOR_AUTH_IMPLEMENTATION.md
```

---

## 🔒 Security Features

### Email Verification
- Automatic verification email on registration
- 24-hour token expiry
- Resend verification functionality
- Status tracking throughout the app

### Two-Factor Authentication (2FA)
- TOTP-based authentication
- QR code setup with authenticator apps
- 8 backup recovery codes
- Compatible with: Google Authenticator, Microsoft Authenticator, Authy, 1Password, etc.

### Password Security
- Minimum 8 characters
- Must include: uppercase, lowercase, symbol
- Bcrypt hashing
- Secure password reset

See [SECURITY_FEATURES_GUIDE.md](SECURITY_FEATURES_GUIDE.md) for details.

---

## 🛠️ Troubleshooting

### MySQL Won't Start
```bash
# Windows
net start MySQL80

# Check service status
sc query MySQL80

# If still fails, open Services app and start manually
```

### Backend Won't Start
```bash
# Check if port 5000 is in use
netstat -ano | findstr :5000

# Install missing dependencies
pip install -r requirements.txt

# Check database connection
mysql -u root -p smartfinance
```

### Frontend Won't Start
```bash
# Check Flutter installation
flutter doctor

# Clear cache
flutter clean
flutter pub get

# Run again
flutter run -d chrome
```

### Database Connection Error
- Verify MySQL is running: `sc query MySQL80`
- Check `.env` file has correct credentials
- Test connection: `mysql -u root -p smartfinance`

### Email Verification Not Working
- Check `.env` file has correct SMTP settings
- For Gmail, use App Password (not regular password)
- Check spam folder
- In development, verification token is shown in backend console

---

## 📊 Tech Stack

### Backend
- **Language:** Python 3.x
- **Framework:** Flask 3.0
- **Database:** MySQL 8.0
- **ORM:** SQLAlchemy
- **Authentication:** JWT (PyJWT)
- **Email:** Flask-Mail
- **Security:** bcrypt, PyOTP, QRCode

### Frontend
- **Framework:** Flutter 3.x
- **Language:** Dart
- **UI:** Material Design
- **State Management:** StatefulWidget
- **HTTP Client:** http package
- **Storage:** shared_preferences
- **Notifications:** flutter_local_notifications

---

## 📖 Documentation

- [FEATURES_STATUS.md](FEATURES_STATUS.md) - Complete feature list
- [README_STARTUP.md](README_STARTUP.md) - Quick start guide
- [EMAIL_VERIFICATION_GUIDE.md](EMAIL_VERIFICATION_GUIDE.md) - Email verification details
- [SECURITY_FEATURES_GUIDE.md](SECURITY_FEATURES_GUIDE.md) - Security features
- [TWO_FACTOR_AUTH_IMPLEMENTATION.md](TWO_FACTOR_AUTH_IMPLEMENTATION.md) - 2FA guide

---

## 🎓 Learning Resources

### Flutter
- https://docs.flutter.dev/
- https://pub.dev/ (Flutter packages)

### Python Flask
- https://flask.palletsprojects.com/
- https://flask-sqlalchemy.palletsprojects.com/

### MySQL
- https://dev.mysql.com/doc/

---

## 📝 License

This project is for educational and personal use.

---

## 👨‍💻 Development

### Prerequisites for Development
- MySQL 8.0+
- Python 3.8+
- Flutter 3.0+
- VS Code (recommended)

### Development Workflow
1. Start MySQL service
2. Start Flask backend: `python run.py`
3. Start Flutter app: `flutter run -d chrome`
4. Make changes and hot reload (press 'r' in Flutter terminal)

### Running Tests
```bash
# Backend tests
cd backend
python -m pytest

# Frontend tests
flutter test
```

---

## 🤝 Contributing

This is a complete educational project. Feel free to fork and modify for your own use.

---

## 📞 Support

For issues or questions:
1. Check [FEATURES_STATUS.md](FEATURES_STATUS.md)
2. Review troubleshooting section above
3. Check documentation files

---

**Last Updated:** January 8, 2026
**Version:** 2.0.0
**Status:** Production Ready ✅

---

## Quick Reference Card

| Task | Command |
|------|---------|
| **Start MySQL** | `net start MySQL80` (Windows) |
| **Start Backend** | `cd backend && python run.py` |
| **Start Frontend** | `flutter run -d chrome` |
| **Install Backend Deps** | `pip install -r requirements.txt` |
| **Install Frontend Deps** | `flutter pub get` |
| **Check Services** | `check_services.bat` (Windows) |
| **Stop All** | Press Ctrl+C in each terminal |
| **Database Access** | `mysql -u root -p smartfinance` |
| **View Backend API** | http://127.0.0.1:5000 |
| **View Frontend** | Automatic (Chrome) |

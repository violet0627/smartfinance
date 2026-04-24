# SmartFinance

A gamified personal finance management mobile application built with Flutter and Python Flask, targeting Malaysian young adults.

## Features

- **Authentication** — Registration, login, email verification, password reset
- **Two-Factor Authentication** — TOTP-based 2FA with backup codes
- **Transaction Management** — Income and expense tracking with category filtering
- **Budget Management** — Monthly budgets with real-time spending alerts
- **Investment Portfolio** — Track stocks, cryptocurrency, ETFs, bonds, and more
- **Financial Goals** — Savings goals with progress tracking
- **Gamification** — XP points, levels, achievement badges, habit streaks, leaderboard
- **Financial Insights** — Health score with personalised insight cards
- **Analytics & Reports** — Spending trends, category breakdown, CSV/PDF export
- **Recurring Transactions** — Scheduled income and expense rules
- **Security Settings** — Session management, activity log, account deletion

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x (Dart) |
| Backend | Python Flask |
| Database | MySQL 8.0 |
| ORM | SQLAlchemy |
| Auth | PyJWT, bcrypt, PyOTP |
| Email | Flask-Mail |

## Prerequisites

- Python 3.8+
- Flutter 3.0+
- MySQL 8.0+

## Setup

### 1. Database

```bash
mysql -u root -p
CREATE DATABASE smartfinance;
EXIT;

mysql -u root -p smartfinance < database/schema.sql
mysql -u root -p smartfinance < backend/migrations/email_verification.sql
mysql -u root -p smartfinance < backend/migrations/add_two_factor_auth.sql
mysql -u root -p smartfinance < backend/migrations/add_security_features.sql
mysql -u root -p smartfinance < backend/migrations/add_recurring_transactions.sql
```

### 2. Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate       # Windows
# source venv/bin/activate  # macOS/Linux

pip install -r requirements.txt
```

Copy `.env.example` to `.env` and fill in your values:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=smartfinance
JWT_SECRET_KEY=your_secret_key
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_app_password
```

Start the server:

```bash
python run.py
```

### 3. Frontend

```bash
flutter pub get
flutter run
```

## Project Structure

```
smartfinance2/
├── backend/
│   ├── app/
│   │   ├── models/         # SQLAlchemy models
│   │   ├── routes/         # Flask Blueprint endpoints
│   │   └── utils/          # JWT, email, 2FA utilities
│   ├── migrations/         # SQL migration scripts
│   ├── config.py
│   ├── run.py
│   └── requirements.txt
├── lib/
│   ├── models/             # Dart data models
│   ├── screens/            # UI screens
│   ├── services/           # API service layer
│   ├── utils/              # Colours, categories, themes
│   ├── widgets/            # Reusable UI components
│   └── main.dart
├── database/
│   └── schema.sql
├── test/                   # Flutter unit and widget tests
├── integration_test/       # Integration tests
├── pubspec.yaml
└── android/
```

## Running Tests

```bash
# Flutter tests
flutter test

# Backend
cd backend
python -m pytest
```

# SmartFinance - Complete Testing & Presentation Guide

## Part 1: Pre-Testing Setup

You need **3 components running** in this order:

```
┌─────────────────────────────────────────────────────┐
│  1. MySQL Database (must start FIRST)               │
│     └── Running on: localhost:3306                  │
└─────────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────┐
│  2. Python Backend Server                           │
│     └── Running on: http://localhost:5000           │
└─────────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────┐
│  3. Flutter App (on Emulator or Phone)              │
└─────────────────────────────────────────────────────┘
```

---

### OPTION A: Easy Way (Use BAT File)

**Step 1: Start MySQL Database FIRST**
1. Press `Windows + R`
2. Type `services.msc` and press Enter
3. Find **MySQL80** in the list
4. Right-click → **Start** (if not already running)
5. Status should show **Running**

**Step 2: Double-click `START_APP.bat`**
- Location: `C:\Users\Elaina\Desktop\smartfinance2\START_APP.bat`
- This will automatically:
  - Open Terminal 1: Backend server
  - Open Terminal 2: Flutter app
- Wait for everything to load (2-3 minutes first time)

---

### OPTION B: Manual Way (Step by Step)

**Step 1: Start MySQL Database**
1. Press `Windows + R`
2. Type `services.msc` and press Enter
3. Find **MySQL80** → Right-click → **Start**
4. OR: Open **MySQL Workbench** and connect to localhost

**Step 2: Start Backend Server**
1. Open **Windows Terminal** (or Command Prompt)
   - Press `Windows + R`, type `cmd`, press Enter
2. Run these commands:
   ```bash
   cd C:\Users\Elaina\Desktop\smartfinance2\backend
   python run.py
   ```
3. You should see:
   ```
   * Running on http://127.0.0.1:5000
   ```
4. **Keep this terminal open!** (Don't close it)

**Step 3: Start Android Emulator**
1. Open **Android Studio**
2. Click **Device Manager** (phone icon on right)
3. Click **Play ▶** on your emulator
4. Wait for emulator to fully boot (shows home screen)

**Step 4: Run Flutter App**
1. Open a **NEW** Windows Terminal (don't close the backend one!)
2. Run these commands:
   ```bash
   cd C:\Users\Elaina\Desktop\smartfinance2
   flutter run
   ```
3. Wait 2-3 minutes for first build
4. App will automatically open on emulator

---

### Which BAT File to Use?

| File | What it does | When to use |
|------|--------------|-------------|
| `START_APP.bat` | Starts backend + Flutter app | Normal testing/development |
| `START_FOR_DEMO.bat` | Starts backend only (for physical phone) | Demo on real phone |

---

### Verify Everything is Running

| Component | How to Check |
|-----------|--------------|
| MySQL | Services shows "MySQL80 - Running" |
| Backend | Terminal shows "Running on http://127.0.0.1:5000" |
| Emulator | Android home screen is visible |
| App | SmartFinance app opens on emulator |

---

## Part 2: Complete Feature Testing (Step-by-Step)

### STAGE 1: First Launch Experience

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1.1 | Launch app fresh (or clear app data) | Splash screen with SmartFinance logo appears |
| 1.2 | Wait 1-2 seconds | Onboarding screen appears |
| 1.3 | Swipe through all 4 onboarding pages | Each page shows different feature highlights |
| 1.4 | Tap "Get Started" | Navigate to Login screen |

---

### STAGE 2: Authentication

| Step | Action | Expected Result |
|------|--------|-----------------|
| 2.1 | On Login screen, tap "Register" | Registration form appears |
| 2.2 | Try submitting empty form | Validation errors shown |
| 2.3 | Enter invalid email (e.g., "test") | "Invalid email" error |
| 2.4 | Enter weak password (e.g., "123") | Password requirements shown |
| 2.5 | Fill valid details and register | Success message, redirect to login |
| 2.6 | Login with new credentials | Dashboard appears |
| 2.7 | (Test later) Tap "Forgot Password" | Password reset flow works |

---

### STAGE 3: Dashboard Overview

| Step | Action | Expected Result |
|------|--------|-----------------|
| 3.1 | Check greeting at top | Shows "Good morning/afternoon/evening, [Name]" based on time |
| 3.2 | View balance card | Shows Total Balance, Income, Expenses |
| 3.3 | Check "Recent Transactions" section | Empty state or list of transactions |
| 3.4 | Check "Upcoming Bills" section | Shows recurring transactions due soon |
| 3.5 | Pull down to refresh | Loading indicator, data refreshes |
| 3.6 | Tap hamburger menu icon | Side drawer opens |

---

### STAGE 4: Add Transactions

| Step | Action | Expected Result |
|------|--------|-----------------|
| 4.1 | Tap floating "+" button | Add Transaction screen opens |
| 4.2 | Select "Expense" tab | Expense form shown |
| 4.3 | Enter amount: 50 | Amount field accepts input |
| 4.4 | Select category: "Food & Dining" | Category selected with icon |
| 4.5 | Enter description: "Lunch" | Description entered |
| 4.6 | Tap date field | Date picker appears |
| 4.7 | Select today's date | Date selected |
| 4.8 | Tap "Save" | Transaction saved, return to dashboard |
| 4.9 | Verify transaction appears in "Recent Transactions" | New transaction visible |
| 4.10 | Add another: Income, RM 3000, "Salary" | Income transaction added |
| 4.11 | Verify balance updates | Total balance = 3000 - 50 = 2950 |

---

### STAGE 5: Transaction History

| Step | Action | Expected Result |
|------|--------|-----------------|
| 5.1 | From dashboard, tap "View all" on Recent Transactions | Transaction History screen opens |
| 5.2 | View full transaction list | All transactions displayed with icons |
| 5.3 | Tap search icon | Search bar appears |
| 5.4 | Type "Lunch" | Filters to show only matching transactions |
| 5.5 | Clear search, tap filter icon | Filter options appear |
| 5.6 | Filter by category: "Food & Dining" | Shows only food transactions |
| 5.7 | Filter by type: "Income only" | Shows only income transactions |
| 5.8 | Filter by date range | Shows transactions in date range |
| 5.9 | Test sort options (newest/oldest/highest/lowest) | List reorders correctly |
| 5.10 | Tap on a transaction | Transaction details or edit screen |

---

### STAGE 6: Recurring Transactions

| Step | Action | Expected Result |
|------|--------|-----------------|
| 6.1 | From drawer menu, tap "Recurring Transactions" | Recurring transactions screen opens |
| 6.2 | Tap "+" to add recurring | Add recurring transaction form |
| 6.3 | Enter: "Netflix", RM 45, Monthly, Bill | Recurring transaction form filled |
| 6.4 | Set next due date | Date selected |
| 6.5 | Save | Recurring transaction created |
| 6.6 | Return to dashboard | "Upcoming Bills" shows Netflix |
| 6.7 | Add another: "Spotify", RM 15, Monthly | Second recurring added |

---

### STAGE 7: Budget Management

| Step | Action | Expected Result |
|------|--------|-----------------|
| 7.1 | Tap "Budget" in bottom navigation | Budget screen opens |
| 7.2 | If no budget exists, "Create Budget" form shown | Budget creation form |
| 7.3 | Set budget amount: RM 2000 | Amount entered |
| 7.4 | Select period: Monthly | Period selected |
| 7.5 | Save budget | Budget created, overview shown |
| 7.6 | View budget progress bar | Shows spending vs budget |
| 7.7 | Add a food expense (RM 100) | Budget progress updates |
| 7.8 | Check budget alerts | Warning when approaching limit |
| 7.9 | Edit budget amount | Budget updated |
| 7.10 | Delete budget (optional test) | Budget removed |

---

### STAGE 8: Savings Goals

| Step | Action | Expected Result |
|------|--------|-----------------|
| 8.1 | From drawer, tap "Goals" | Goals screen opens |
| 8.2 | Tap "+" to create new goal | Goal creation form |
| 8.3 | Enter: "Vacation Fund", Target: RM 5000 | Goal details entered |
| 8.4 | Set target date (6 months away) | Date selected |
| 8.5 | Save | Goal created |
| 8.6 | View goal card with progress | 0% progress shown |
| 8.7 | Tap "Add Contribution" | Contribution form |
| 8.8 | Add RM 500 contribution | Progress updates to 10% |
| 8.9 | Create second goal: "New Phone", RM 2000 | Multiple goals supported |
| 8.10 | Check goal on dashboard | Goal progress card appears |

---

### STAGE 9: Analytics

| Step | Action | Expected Result |
|------|--------|-----------------|
| 9.1 | Tap "Analytics" in bottom navigation | Analytics screen opens |
| 9.2 | View 4-card summary at top | Total Income, Total Spent, Net Savings, Savings Rate |
| 9.3 | Check pie chart | Spending by category breakdown |
| 9.4 | Change time period to "Week" | Data updates for weekly view |
| 9.5 | Change to "Month" | Monthly data shown |
| 9.6 | Change to "Year" | Yearly overview |
| 9.7 | Verify numbers match your transactions | Data accuracy check |

---

### STAGE 10: Reports

| Step | Action | Expected Result |
|------|--------|-----------------|
| 10.1 | From drawer, tap "Reports" | Reports screen opens |
| 10.2 | View "Summary" tab | Overview statistics |
| 10.3 | Tap "Trends" tab | Spending trends chart |
| 10.4 | Tap "Categories" tab | Category breakdown |
| 10.5 | If no data, verify empty states show helpful messages | Proper guidance shown |

---

### STAGE 11: Investment Portfolio

| Step | Action | Expected Result |
|------|--------|-----------------|
| 11.1 | Tap "Portfolio" in bottom navigation | Portfolio screen opens |
| 11.2 | Tap "+" to add investment | Add investment form |
| 11.3 | Enter: Stock name, quantity, purchase price | Investment details entered |
| 11.4 | Save | Investment added |
| 11.5 | View portfolio overview | Total value, gain/loss shown |
| 11.6 | Update current price | Portfolio value updates |

---

### STAGE 12: Gamification & Achievements

| Step | Action | Expected Result |
|------|--------|-----------------|
| 12.1 | View level progress on dashboard | XP bar and level shown |
| 12.2 | From drawer, tap "Achievements" | Achievements screen opens |
| 12.3 | View available achievements | Achievement badges shown |
| 12.4 | Check unlocked achievements | Completed achievements highlighted |
| 12.5 | Add more transactions | XP increases, level up possible |

---

### STAGE 13: Settings & Profile

| Step | Action | Expected Result |
|------|--------|-----------------|
| 13.1 | From drawer, tap "Settings" | Settings screen opens |
| 13.2 | Toggle Dark Mode ON | App switches to dark theme |
| 13.3 | Navigate through all screens in dark mode | All screens render properly |
| 13.4 | Toggle Dark Mode OFF | Returns to light theme |
| 13.5 | Change currency setting | Currency symbol updates |
| 13.6 | Check notification settings | Options available |
| 13.7 | Tap "Security" | Security settings shown |
| 13.8 | Test 2FA setup (optional) | Two-factor authentication flow |
| 13.9 | Tap "Edit Profile" | Profile edit screen |
| 13.10 | Update name | Profile updated |
| 13.11 | Test logout | Returns to login screen |

---

## Part 3: Quick Test Checklist

Use this checklist for rapid testing:

- [ ] Onboarding screens work
- [ ] Register new account works
- [ ] Login works
- [ ] Dashboard shows greeting + data correctly
- [ ] Add expense works
- [ ] Add income works
- [ ] Transaction search works
- [ ] Transaction filter works
- [ ] Recurring transactions work
- [ ] Create budget works
- [ ] Budget progress updates
- [ ] Create goal works
- [ ] Goal contribution works
- [ ] Analytics 4-card summary displays
- [ ] Analytics charts work
- [ ] Analytics time period filter works
- [ ] Reports 3 tabs work
- [ ] Reports empty states show guidance
- [ ] Portfolio add investment works
- [ ] Achievements screen loads
- [ ] Dark mode toggle works
- [ ] Settings save correctly
- [ ] Profile edit works
- [ ] Logout works

---

## Part 4: Supervisor Presentation Guide

### Before Presentation Checklist
- [ ] MySQL database running (services.msc → MySQL80 → Running)
- [ ] Backend server running (terminal shows "Running on http://127.0.0.1:5000")
- [ ] Emulator running OR phone connected
- [ ] App launched and working
- [ ] Either fresh install OR pre-populated with demo data
- [ ] Done one test run to ensure everything works

### Quick Start for Presentation
1. Start MySQL: `services.msc` → MySQL80 → Start
2. Double-click `START_APP.bat`
3. Wait 2-3 minutes
4. Ready to present!

---

### Presentation Script (15-20 minutes)

#### 1. Opening (2 min)

**Say:**
> "This is SmartFinance, a personal finance management mobile application I developed using Flutter. The app helps users track their daily expenses, manage budgets, set savings goals, and visualize their financial health through analytics."

**Show:**
- App icon and splash screen briefly

---

#### 2. Onboarding & Authentication (2 min)

**Say:**
> "When users first open the app, they see an onboarding flow that introduces the key features."

**Demo:**
- Swipe through onboarding pages quickly
- Show registration form with validation
- Login to dashboard

**Highlight:**
- Form validation for security
- Clean, intuitive design

---

#### 3. Dashboard Tour (2 min)

**Say:**
> "The dashboard provides a comprehensive overview of the user's financial status at a glance."

**Point out:**
- Time-aware greeting ("Good morning/afternoon/evening")
- Balance overview card (Total, Income, Expenses)
- Recent transactions list
- Upcoming bills section
- Level/XP progress (gamification)

**Demo:**
- Pull to refresh

---

#### 4. Transaction Management (2 min)

**Say:**
> "Users can easily add and manage their transactions."

**Demo:**
1. Tap "+" button
2. Add an expense (Food, RM 25, "Lunch")
3. Show it appears in recent transactions
4. Open Transaction History
5. Demonstrate search (type "Lunch")
6. Show filter options briefly

**Highlight:**
- Category icons for visual clarity
- Powerful search and filter

---

#### 5. Budget Feature (1.5 min)

**Say:**
> "The budget feature helps users control their spending."

**Demo:**
1. Tap Budget in bottom nav
2. Show budget overview with progress bar
3. Point out visual indicators (green/yellow/red)

**Highlight:**
- Visual progress tracking
- Alerts when approaching limit

---

#### 6. Savings Goals (1.5 min)

**Say:**
> "Users can set financial goals and track their progress."

**Demo:**
1. Open Goals from drawer
2. Show existing goal or create one quickly
3. Add a contribution
4. Show progress update

**Highlight:**
- Motivating progress visualization
- Target date tracking

---

#### 7. Analytics (2 min)

**Say:**
> "The analytics screen provides insights into spending patterns."

**Demo:**
1. Tap Analytics in bottom nav
2. Point out 4-card summary (Income, Spent, Savings, Rate)
3. Show pie chart breakdown
4. Switch time periods (Week/Month/Year)

**Highlight:**
- At-a-glance financial health
- Multiple time period views

---

#### 8. Reports (1 min)

**Say:**
> "The reports section offers detailed financial analysis."

**Demo:**
- Show 3 tabs quickly: Summary, Trends, Categories
- Point out helpful empty states if no data

---

#### 9. Additional Features (2 min)

**Say:**
> "The app includes several additional features."

**Demo quickly:**
- Recurring transactions (for bills like Netflix, rent)
- Investment portfolio tracking
- Achievements/gamification system
- Dark mode toggle in Settings

---

#### 10. Technical Summary (1 min)

**Say:**
> "From a technical perspective:"
> - "Built with Flutter for cross-platform compatibility (iOS, Android, Web)"
> - "Backend API using Python Flask"
> - "SQLite database for data persistence"
> - "Secure authentication with optional two-factor authentication"
> - "Clean architecture with separation of concerns"

---

#### 11. Closing (1 min)

**Say:**
> "In summary, SmartFinance provides a complete personal finance management solution with an intuitive interface, comprehensive features, and gamification elements to encourage good financial habits."

> "Do you have any questions about the features or implementation?"

---

### Potential Questions & Answers

| Question | Answer |
|----------|--------|
| "How is user data stored?" | "User data is stored in a SQLite database on the backend server. User preferences are cached locally using SharedPreferences for faster access." |
| "Is the app secure?" | "Yes, it includes password hashing, secure API authentication with tokens, and optional two-factor authentication for additional security." |
| "Why Flutter?" | "Flutter allows building for multiple platforms (iOS, Android, Web, Desktop) from a single codebase, which improves development efficiency and ensures consistent UI." |
| "What makes this app unique?" | "It combines traditional expense tracking with goal setting and gamification elements like achievements and XP levels, which encourages users to maintain good financial habits." |
| "How does the budget alert work?" | "The app calculates spending against the budget in real-time and shows visual indicators - green when safe, yellow when approaching limit, red when exceeded." |
| "Can it sync across devices?" | "Yes, since data is stored on the backend server, users can login from any device and access their data." |

---

### Tips for a Smooth Presentation

1. **Practice the flow** - Do a dry run before the actual presentation
2. **Have backup data** - Pre-populate some transactions so screens aren't empty
3. **Know your shortcuts** - Familiarize yourself with navigation
4. **Keep it moving** - Don't spend too long on any single feature
5. **Be ready for questions** - Know the technical details
6. **Stay calm** - If something doesn't work, acknowledge it and move on

---

## Appendix: App Navigation Map

```
SmartFinance App
│
├── Splash Screen
│   └── Onboarding (first launch only)
│
├── Authentication
│   ├── Login
│   ├── Register
│   └── Forgot Password
│
├── Dashboard (Home)
│   ├── Balance Card
│   ├── Recent Transactions
│   ├── Upcoming Bills
│   ├── Goals Progress
│   └── Level/XP Progress
│
├── Bottom Navigation
│   ├── Home (Dashboard)
│   ├── Analytics
│   ├── Budget
│   └── Portfolio
│
└── Drawer Menu
    ├── Dashboard
    ├── Transactions
    ├── Recurring Transactions
    ├── Goals
    ├── Reports
    ├── Achievements
    ├── Settings
    │   ├── Profile Edit
    │   ├── Security (2FA)
    │   ├── Dark Mode
    │   └── Currency
    └── Logout
```

---

*Last Updated: February 2026*

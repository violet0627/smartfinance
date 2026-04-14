# SmartFinance — Final Presentation Preparation Guide

Do all of PART A, B, C, D the day before the presentation.
Do PART E on the day itself, about 30 minutes before you start.

---

# PART A — DELETE THE EXISTING ACCOUNT

**Step 1.** Open MySQL Workbench (or your MySQL terminal).

**Step 2.** Run this command:

```sql
USE smartfinance;
DELETE FROM Users WHERE Email = 'chuanshengsiow@gmail.com';
```

**Step 3.** Confirm it's deleted:

```sql
SELECT * FROM Users WHERE Email = 'chuanshengsiow@gmail.com';
```

It should return 0 rows. The DELETE CASCADE will automatically remove all old transactions, budgets, goals, investments, sessions, and everything else linked to that account.

---

# PART B — CREATE THE NEW DEMO ACCOUNT

**Step 1.** Make sure your Flask backend is running.

**Step 2.** Make sure the emulator is running and connected to the backend.

**Step 3.** Open the app on the emulator. You should see the login screen.

**Step 4.** Tap **Create Account** and fill in:
- Full Name: `Sarah Tan`  ← use this name, sounds natural for a Malaysian demo
- Email: `chuanshengsiow@gmail.com`
- Phone: `012-3456789`
- Password: `SmartFinance@2026`
- Confirm Password: `SmartFinance@2026`

**Step 5.** Tap **Create Account**.

**Step 6.** Check your Gmail inbox. Click the verification link in the email.

**Step 7.** Get the new UserId — you need this for the next steps:

```sql
USE smartfinance;
SELECT UserId FROM Users WHERE Email = 'chuanshengsiow@gmail.com';
```

Write down the number. For example if it returns `UserId = 3`, replace every `YOUR_USER_ID` below with `3`.

---

# PART C — ADD ALL DEMO DATA (Manual Tapping)

Enter everything through the app. This also doubles as practice for the presentation.
The achievements will unlock automatically as you do each action — no SQL needed for those.

Estimated time: about 30–45 minutes of tapping.

---

## C1 — Add Past Transactions

Go to the **Transactions** screen and tap **+** for each one below. Make sure you set the **date** correctly using the date picker — these are historical transactions, not today.

### February 2026 (6 transactions)

| Type | Amount | Category | Description | Date |
|------|--------|----------|-------------|------|
| Income | RM 3500.00 | Salary | Monthly salary | 1 Feb 2026 |
| Expense | RM 450.00 | Food & Dining | Food expenses Feb | 3 Feb 2026 |
| Expense | RM 280.00 | Transport | Transport Feb | 5 Feb 2026 |
| Expense | RM 80.00 | Entertainment | Entertainment Feb | 10 Feb 2026 |
| Expense | RM 520.00 | Bills & Utilities | Utilities Feb | 15 Feb 2026 |
| Expense | RM 150.00 | Shopping | Shopping Feb | 20 Feb 2026 |

### March 2026 (7 transactions)

| Type | Amount | Category | Description | Date |
|------|--------|----------|-------------|------|
| Income | RM 3500.00 | Salary | Monthly salary | 1 Mar 2026 |
| Income | RM 500.00 | Freelance | Web design project | 5 Mar 2026 |
| Expense | RM 520.00 | Food & Dining | Food expenses Mar | 4 Mar 2026 |
| Expense | RM 260.00 | Transport | Transport Mar | 6 Mar 2026 |
| Expense | RM 150.00 | Entertainment | Entertainment Mar | 10 Mar 2026 |
| Expense | RM 500.00 | Bills & Utilities | Utilities Mar | 15 Mar 2026 |
| Expense | RM 200.00 | Shopping | Shopping Mar | 22 Mar 2026 |

### April 2026 — Current Month (5 transactions)
These are the ones the budget will track against. The amounts are set so the budget shows green, amber, and red progress bars.

| Type | Amount | Category | Description | Date |
|------|--------|----------|-------------|------|
| Income | RM 3500.00 | Salary | Monthly salary | 1 Apr 2026 |
| Expense | RM 480.00 | Food & Dining | Food this month | 3 Apr 2026 |
| Expense | RM 280.00 | Transport | Grab and fuel | 5 Apr 2026 |
| Expense | RM 54.90 | Entertainment | Netflix subscription | 10 Apr 2026 |
| Expense | RM 560.00 | Bills & Utilities | Electricity and water | 12 Apr 2026 |

---

## C2 — Create the April 2026 Budget

Go to the **Budget** screen and tap **Create Budget**.

- **Month:** April 2026
- **Total Budget:** RM 2500.00
- **Allocate categories as follows:**

| Category | Allocated Amount | Why |
|----------|-----------------|-----|
| Food & Dining | RM 600.00 | RM480 spent → 80% → AMBER bar |
| Transport | RM 350.00 | RM280 spent → 80% → AMBER bar |
| Entertainment | RM 250.00 | RM54.90 spent → 22% → GREEN bar |
| Bills & Utilities | RM 600.00 | RM560 spent → 93% → RED bar |
| Shopping | RM 400.00 | RM0 spent → 0% → GREEN bar |
| Others | RM 300.00 | RM0 spent → 0% → GREEN bar |

Tap **Save**. After saving, open the Budget Overview — you should see all three colours (green, amber, red) visible at once. This looks great for the demo.

---

## C3 — Add Goals

Go to the **Goals** screen and tap **+** for each goal.

**Goal 1 — Emergency Fund**
- Name: `Emergency Fund`
- Description: `Save 3 months of expenses as emergency backup`
- Target Amount: RM 10000.00
- Current Amount: RM 3500.00  ← this shows 35% progress
- Start Date: 1 Jan 2026
- Deadline: 31 Dec 2026
- Category: Emergency Fund
- Priority: High

**Goal 2 — Japan Trip**
- Name: `Japan Trip`
- Description: `Holiday trip to Japan with family`
- Target Amount: RM 5000.00
- Current Amount: RM 1200.00  ← this shows 24% progress
- Start Date: 1 Feb 2026
- Deadline: 31 Mar 2027
- Category: Travel
- Priority: Medium

---

## C4 — Add Investments

Go to the **Investment Portfolio** screen and tap **+** for each holding.

**Investment 1 — Apple Inc. (profit, shows green)**
- Asset Type: Stocks
- Asset Name: `Apple Inc.`
- Stock Symbol: `AAPL`
- Quantity: `10`
- Purchase Price: RM 765.00
- Purchase Date: 10 Jan 2026
- Current Price: RM 825.00
- Notes: `Long-term hold`

**Investment 2 — Bitcoin (profit, shows green)**
- Asset Type: Cryptocurrency
- Asset Name: `Bitcoin`
- Stock Symbol: `BTC`
- Quantity: `0.05`
- Purchase Price: RM 290000.00
- Purchase Date: 1 Feb 2026
- Current Price: RM 315000.00
- Notes: `High risk high reward`

**Investment 3 — KLCI ETF (loss, shows red)**
- Asset Type: ETF
- Asset Name: `KLCI ETF`
- Stock Symbol: `KLCI`
- Quantity: `50`
- Purchase Price: RM 148.00
- Purchase Date: 20 Jan 2026
- Current Price: RM 142.00
- Notes: `Diversified local market`

**Investment 4 — Maybank FD (profit, shows green)**
- Asset Type: Fixed Deposit
- Asset Name: `Maybank FD`
- Stock Symbol: (leave empty)
- Quantity: `1`
- Purchase Price: RM 5000.00
- Purchase Date: 5 Jan 2026
- Current Price: RM 5150.00
- Notes: `3.8% annual return`

---

## C5 — Add Recurring Transactions

Go to the **Recurring Transactions** screen and tap **+** for each one.

**Recurring 1 — Monthly Salary**
- Name: `Monthly Salary`
- Type: Income
- Category: Salary
- Amount: RM 3500.00
- Frequency: Monthly
- Start Date: 1 Jan 2026

**Recurring 2 — Netflix Subscription**
- Name: `Netflix Subscription`
- Type: Expense
- Category: Entertainment
- Amount: RM 54.90
- Frequency: Monthly
- Start Date: 10 Jan 2026

---

## C6 — Small SQL Tweaks (Things You Can't Set in the App)

The three main achievements (First Step, Budget Beginner, Investment Initiate) will have **unlocked automatically** when you did C1, C2, and C4 above. No SQL needed for those.

But these three things can't be set through the app UI, so run this SQL in MySQL Workbench.

First, get your UserId:

```sql
USE smartfinance;
SELECT UserId FROM Users WHERE Email = 'chuanshengsiow@gmail.com';
```

Write down the number. Replace `YOUR_USER_ID` below with it.

```sql
-- Give XP and set level to 2
UPDATE Users
SET ExperiencePts = 320, CurrentLevel = 2
WHERE UserId = YOUR_USER_ID;

-- Set Week Warrior to 5/7 progress (looks almost complete — impressive)
UPDATE UserAchievements
SET Progress = 71
WHERE UserId = YOUR_USER_ID
  AND AchievementId = (SELECT AchievementId FROM Achievements WHERE Name = 'Week Warrior');

-- Set Expense Expert to 13/100 transactions
UPDATE UserAchievements
SET Progress = 13
WHERE UserId = YOUR_USER_ID
  AND AchievementId = (SELECT AchievementId FROM Achievements WHERE Name = 'Expense Expert');

-- Add habit streak (7-day current, 12-day longest)
INSERT INTO HabitStreaks (UserId, StreakType, CurrentStreak, LongestStreak, LastActivity)
VALUES (YOUR_USER_ID, 'transaction_log', 7, 12, '2026-04-13');

-- User settings (notifications and alerts on)
INSERT INTO UserSettings (UserId, EnableNotifications, EnableBudgetAlerts, EnableAchievementAlerts, EnableStreakAlerts, BudgetWarningThreshold, BudgetDangerThreshold, BudgetCriticalThreshold, ShowInLeaderboard)
VALUES (YOUR_USER_ID, TRUE, TRUE, TRUE, TRUE, 75, 90, 100, TRUE);
```

---

# PART D — SET UP 2FA (Do this AFTER PART C is done)

**Step 1.** Open the app on the emulator and log in with:
- Email: `chuanshengsiow@gmail.com`
- Password: `SmartFinance@2026`

**Step 2.** Navigate to **Settings → Security → Two-Factor Authentication**.

**Step 3.** Tap **Enable 2FA**.

**Step 4.** The app shows a QR code. Open **Google Authenticator** on your real phone. Tap **+** → **Scan QR code**. Scan the QR code on the emulator screen.

**Step 5.** Google Authenticator will show a 6-digit code that changes every 30 seconds. Type that code into the app to confirm setup.

**Step 6.** The app will show **10 backup codes**. **Screenshot them or write them down somewhere safe.** You need these if something goes wrong.

**Step 7.** Tap **Done / Confirm**.

**Step 8.** Log out from the app.

**Step 9.** Log back in. After entering the password, the app should ask for your TOTP code. Enter the code from Google Authenticator. Confirm this works.

**Step 10.** Check the Security Centre — the security score should now show **100** and the bar should be green.

---

# PART E — FINAL CHECKS (30 minutes before the presentation)

Go through this checklist. Tick each one before you start.

**Backend:**
- [ ] Flask backend is running — no errors in the terminal
- [ ] MySQL is running

**Emulator:**
- [ ] Android emulator is open
- [ ] App is installed and showing the login screen
- [ ] The app connects to the backend successfully (try logging in)

**Account:**
- [ ] Can log in with `chuanshengsiow@gmail.com` / `SmartFinance@2026`
- [ ] 2FA works — Google Authenticator gives the correct code
- [ ] Email is verified (no verification banner showing)
- [ ] Security score shows 100 (green bar)

**Features to check quickly:**
- [ ] Dashboard shows April 2026 income, expenses, and balance
- [ ] Transaction History shows multiple transactions
- [ ] Budget Overview shows progress bars in green, amber, and red
- [ ] Goals screen shows Emergency Fund and Japan Trip
- [ ] Investment Portfolio shows 4 holdings with green and red indicators
- [ ] Analytics shows charts with data (not empty)
- [ ] Achievements screen shows 3 unlocked badges
- [ ] Recurring Transactions shows Monthly Salary and Netflix

**Google Authenticator:**
- [ ] Your real phone is charged and nearby
- [ ] Google Authenticator app is open and showing the SmartFinance code

**Log out before the presentation starts** — so you start from the login screen, which is the right starting point for the demo.

---

# PART F — DURING THE PRESENTATION

## For the Registration Demo (Part 4.1 of the script):

Do NOT create a real new account — it would mess up the demo data.

Instead:
1. Tap **Create Account** to show the registration screen.
2. Fill in the form with fake details:
   - Name: `Alex Lim`
   - Email: `alex.demo@test.com`
   - Password: `Test@1234`
3. Explain the fields and the password rules while the form is visible.
4. **Do NOT tap Create Account.** Instead say: *"So after the user fills this in and taps Create Account, they'll receive a verification email. Let me go back and log in with my existing account."*
5. Tap the back button. Log in with `chuanshengsiow@gmail.com` and `SmartFinance@2026`.
6. When 2FA asks for the code — enter it from Google Authenticator.

## During the Transaction Demo (Part 4.4):

Add one real transaction live to show it working:
- Amount: `RM 15.00`
- Type: Expense
- Description: `lunch at mamak` (triggers food category suggestion)
- Category: Food & Dining
- Date: today
- Tap Save

This is real and live — the transaction will appear in the history immediately.

## Smooth recovery if something fails:

- App crashes → restart it and log back in, continue from where you stopped.
- Backend error → check the terminal, restart Flask if needed, say "let me just restart the server quickly."
- Can't remember the 2FA code → open Google Authenticator on your phone, wait for the new code.
- Charts look empty → check that the time range isn't too narrow. Switch to "3M" or "ALL".

---

## ACCOUNT DETAILS SUMMARY (keep this nearby during prep)

| Field | Value |
|-------|-------|
| Email | chuanshengsiow@gmail.com |
| Password | SmartFinance@2026 |
| Full Name | Sarah Tan |
| 2FA | Google Authenticator |
| Security Score | 100 (green) |

---

## DEMO DATA SUMMARY (what the moderator will see)

| Feature | What's prepared |
|---------|----------------|
| Transactions | Feb + Mar + Apr 2026 history, income + expenses |
| Budget | April 2026 — RM2,500 total. Green/amber/red bars visible |
| Goals | Emergency Fund 35%, Japan Trip 24% |
| Investments | Apple (+profit), Bitcoin (+profit), KLCI ETF (−loss), Maybank FD (+profit) |
| Recurring | Monthly Salary + Netflix Subscription |
| Analytics | 3 months of data — all 4 charts will have content |
| Achievements | 3 unlocked (First Step, Budget Beginner, Investment Initiate) |
| Streak | 7-day current streak, 12-day longest streak |
| Security | Score 100, 2FA enabled, green bar |

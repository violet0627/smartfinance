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

# PART C — ADD ALL DEMO DATA

Run the SQL below in MySQL Workbench. Replace `YOUR_USER_ID` with the number from Step 7 above.

---

## C1 — Past Transactions (February and March 2026)
## These give the Analytics charts enough data to look good.

```sql
USE smartfinance;

-- ===== FEBRUARY 2026 =====
INSERT INTO Transactions (UserId, Amount, Category, Description, TransactionDate, TransactionType) VALUES
(YOUR_USER_ID, 3500.00, 'Salary',             'Monthly salary',          '2026-02-01', 'income'),
(YOUR_USER_ID,  450.00, 'Food & Dining',       'Food expenses Feb',       '2026-02-03', 'expense'),
(YOUR_USER_ID,  280.00, 'Transport',           'Transport Feb',           '2026-02-05', 'expense'),
(YOUR_USER_ID,   80.00, 'Entertainment',       'Entertainment Feb',       '2026-02-10', 'expense'),
(YOUR_USER_ID,  520.00, 'Bills & Utilities',   'Utilities Feb',           '2026-02-15', 'expense'),
(YOUR_USER_ID,  150.00, 'Shopping',            'Shopping Feb',            '2026-02-20', 'expense');

-- ===== MARCH 2026 =====
INSERT INTO Transactions (UserId, Amount, Category, Description, TransactionDate, TransactionType) VALUES
(YOUR_USER_ID, 3500.00, 'Salary',             'Monthly salary',          '2026-03-01', 'income'),
(YOUR_USER_ID,  500.00, 'Freelance',          'Web design project',      '2026-03-05', 'income'),
(YOUR_USER_ID,  520.00, 'Food & Dining',       'Food expenses Mar',       '2026-03-04', 'expense'),
(YOUR_USER_ID,  260.00, 'Transport',           'Transport Mar',           '2026-03-06', 'expense'),
(YOUR_USER_ID,  150.00, 'Entertainment',       'Entertainment Mar',       '2026-03-10', 'expense'),
(YOUR_USER_ID,  500.00, 'Bills & Utilities',   'Utilities Mar',           '2026-03-15', 'expense'),
(YOUR_USER_ID,  200.00, 'Shopping',            'Shopping Mar',            '2026-03-22', 'expense');
```

---

## C2 — April 2026 Transactions (Current Month)
## These are the transactions the budget tracks against.
## The amounts are set so each budget category shows a different colour.

```sql
-- ===== APRIL 2026 (current month) =====
INSERT INTO Transactions (UserId, Amount, Category, Description, TransactionDate, TransactionType) VALUES
(YOUR_USER_ID, 3500.00, 'Salary',             'Monthly salary',          '2026-04-01', 'income'),
(YOUR_USER_ID,  480.00, 'Food & Dining',       'Food this month',         '2026-04-03', 'expense'),
(YOUR_USER_ID,  280.00, 'Transport',           'Grab and fuel',           '2026-04-05', 'expense'),
(YOUR_USER_ID,   54.90, 'Entertainment',       'Netflix subscription',    '2026-04-10', 'expense'),
(YOUR_USER_ID,  560.00, 'Bills & Utilities',   'Electricity and water',   '2026-04-12', 'expense');
```

---

## C3 — Budget for April 2026
## Shows Food at 80% (amber), Bills at 93% (red), Entertainment at 22% (green).
## This makes all three progress bar colours visible in the demo.

```sql
-- Create the parent budget record
INSERT INTO Budgets (UserId, MonthYear, BudgetPeriod, TotalBudget)
VALUES (YOUR_USER_ID, '2026-04', 'April 2026', 2500.00);

-- Get the BudgetId that was just created
-- Run this line separately and note the number:
SELECT BudgetId FROM Budgets WHERE UserId = YOUR_USER_ID AND MonthYear = '2026-04';
```

After you run the SELECT above, write down the BudgetId number. Replace `YOUR_BUDGET_ID` below with it:

```sql
-- Create budget categories
-- Food: RM600 budget, RM480 spent = 80% = AMBER (warning)
-- Transport: RM350 budget, RM280 spent = 80% = AMBER (warning)
-- Entertainment: RM250 budget, RM55 spent = 22% = GREEN (safe)
-- Bills: RM600 budget, RM560 spent = 93% = RED (danger)
-- Shopping: RM400 budget, RM0 spent = 0% = GREEN

INSERT INTO BudgetCategories (BudgetId, CategoryName, AllocatedAmount, SpentAmount) VALUES
(YOUR_BUDGET_ID, 'Food & Dining',     600.00, 480.00),
(YOUR_BUDGET_ID, 'Transport',         350.00, 280.00),
(YOUR_BUDGET_ID, 'Entertainment',     250.00,  54.90),
(YOUR_BUDGET_ID, 'Bills & Utilities', 600.00, 560.00),
(YOUR_BUDGET_ID, 'Shopping',          400.00,   0.00),
(YOUR_BUDGET_ID, 'Others',            300.00,   0.00);
```

---

## C4 — Goals

```sql
INSERT INTO Goals (UserId, GoalName, Description, TargetAmount, CurrentAmount, StartDate, Deadline, Status, Category, Priority)
VALUES
-- Emergency fund: 35% done, HIGH priority
(YOUR_USER_ID, 'Emergency Fund',  'Save 3 months of expenses as emergency backup', 10000.00, 3500.00, '2026-01-01', '2026-12-31', 'active', 'Emergency Fund', 'high'),
-- Japan trip: 24% done, MEDIUM priority
(YOUR_USER_ID, 'Japan Trip',      'Holiday trip to Japan with family',              5000.00,  1200.00, '2026-02-01', '2027-03-31', 'active', 'Travel',         'medium');
```

---

## C5 — Investments
## Mix of profit (green) and loss (red) to make the demo interesting.

```sql
INSERT INTO Investments (UserId, AssetName, AssetsType, StockSymbol, Quantity, PurchasePrice, PurchaseDate, CurrentPrice, Notes)
VALUES
-- Apple: profit (purchase RM765, now RM825)
(YOUR_USER_ID, 'Apple Inc.',   'Stocks',          'AAPL', 10.0000,   765.00, '2026-01-10',  825.00, 'Long-term hold'),
-- Bitcoin: profit (purchase RM290000, now RM315000)
(YOUR_USER_ID, 'Bitcoin',      'Cryptocurrency',  'BTC',   0.0500, 290000.00, '2026-02-01', 315000.00, 'High risk high reward'),
-- KLCI ETF: small loss (purchase RM148, now RM142) — shows red
(YOUR_USER_ID, 'KLCI ETF',     'ETF',             'KLCI', 50.0000,   148.00, '2026-01-20',  142.00, 'Diversified local market'),
-- Fixed Deposit: safe profit
(YOUR_USER_ID, 'Maybank FD',   'Fixed Deposit',   NULL,    1.0000,  5000.00, '2026-01-05',  5150.00, '3.8% annual return');
```

---

## C6 — Recurring Transactions

```sql
INSERT INTO recurringtransactions (UserId, Name, TransactionType, Category, Amount, Frequency, StartDate, NextExecution, IsActive)
VALUES
(YOUR_USER_ID, 'Monthly Salary',        'income',  'Salary',        3500.00, 'monthly', '2026-01-01', '2026-05-01', TRUE),
(YOUR_USER_ID, 'Netflix Subscription',  'expense', 'Entertainment',   54.90, 'monthly', '2026-01-10', '2026-05-10', TRUE);
```

---

## C7 — Unlock Starter Achievements and Give XP
## This gives the gamification screen something to show.

```sql
-- Give the user XP for all the activity above
UPDATE Users
SET ExperiencePts = 320, CurrentLevel = 2
WHERE UserId = YOUR_USER_ID;

-- Make sure all achievements exist for this user
-- First, insert UserAchievement rows for all 8 achievements
-- Get achievement IDs
SELECT AchievementId, Name FROM Achievements;
```

Run the SELECT above. It will show you the AchievementId for each achievement. Then run:

```sql
-- Insert all achievement tracking rows (all locked at first)
INSERT INTO UserAchievements (UserId, AchievementId, IsUnlocked, Progress)
SELECT YOUR_USER_ID, AchievementId, FALSE, 0
FROM Achievements;
```

Then unlock the three starter achievements:

```sql
-- Unlock "First Step" (recorded first transaction)
UPDATE UserAchievements
SET IsUnlocked = TRUE, Progress = 100, UnlockedAt = '2026-02-03 10:00:00'
WHERE UserId = YOUR_USER_ID
  AND AchievementId = (SELECT AchievementId FROM Achievements WHERE Name = 'First Step');

-- Unlock "Budget Beginner" (created first budget)
UPDATE UserAchievements
SET IsUnlocked = TRUE, Progress = 100, UnlockedAt = '2026-04-01 09:00:00'
WHERE UserId = YOUR_USER_ID
  AND AchievementId = (SELECT AchievementId FROM Achievements WHERE Name = 'Budget Beginner');

-- Unlock "Investment Initiate" (added first investment)
UPDATE UserAchievements
SET IsUnlocked = TRUE, Progress = 100, UnlockedAt = '2026-01-10 11:00:00'
WHERE UserId = YOUR_USER_ID
  AND AchievementId = (SELECT AchievementId FROM Achievements WHERE Name = 'Investment Initiate');

-- Set Week Warrior progress to 5/7 (almost unlocked — looks impressive)
UPDATE UserAchievements
SET Progress = 71
WHERE UserId = YOUR_USER_ID
  AND AchievementId = (SELECT AchievementId FROM Achievements WHERE Name = 'Week Warrior');

-- Set Expense Expert progress to 13/100 transactions
UPDATE UserAchievements
SET Progress = 13
WHERE UserId = YOUR_USER_ID
  AND AchievementId = (SELECT AchievementId FROM Achievements WHERE Name = 'Expense Expert');
```

---

## C8 — Habit Streak

```sql
INSERT INTO HabitStreaks (UserId, StreakType, CurrentStreak, LongestStreak, LastActivity)
VALUES
(YOUR_USER_ID, 'transaction_log', 7, 12, '2026-04-13');
```

---

## C9 — User Settings

```sql
INSERT INTO UserSettings (UserId, EnableNotifications, EnableBudgetAlerts, EnableAchievementAlerts, EnableStreakAlerts, BudgetWarningThreshold, BudgetDangerThreshold, BudgetCriticalThreshold, ShowInLeaderboard)
VALUES (YOUR_USER_ID, TRUE, TRUE, TRUE, TRUE, 75, 90, 100, TRUE);
```

---

# PART D — SET UP 2FA (Do this AFTER all the SQL above)

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

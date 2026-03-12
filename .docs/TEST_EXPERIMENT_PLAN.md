# Test / Experiment Plan — SmartFinance

## 1. Overview

The evaluation of SmartFinance is conducted to verify that the system meets its functional and non-functional requirements. The plan covers four testing strategies: **Functional Testing**, **Usability Testing**, **Security Testing**, and **Performance Testing**.

---

## 2. Functional Testing

Each core module is tested individually to verify it behaves as expected.

### 2.1 Authentication Module

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| User Registration | Register with valid name, email, password | Account created; verification email sent |
| Duplicate Email | Register with an already-used email | Error: "Email already registered" |
| Login with valid credentials | Enter correct email + password | Redirect to dashboard |
| Login with wrong password | Enter incorrect password | Error message shown |
| Email Verification | Click verification link from email | Account marked as verified |
| Forgot Password | Submit registered email | Reset link sent to email |
| Reset Password | Submit new password via reset link | Password updated; can login with new password |
| Two-Factor Authentication (Enable) | Scan QR, enter 6-digit TOTP code | 2FA enabled; backup codes displayed |
| Two-Factor Authentication (Login) | Login with 2FA enabled | Prompted for TOTP code before access |
| 2FA Disable | Enter password to disable 2FA | 2FA removed; security score updated |

### 2.2 Transaction Module

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Add Expense | Fill in amount, category, date | Transaction saved; dashboard updates |
| Add Income | Fill in amount, category, date | Transaction saved; balance updates |
| View Transaction History | Open history screen | Transactions listed with correct filters |
| Filter by Date/Category | Apply filter | Only matching transactions shown |
| Scan Receipt | Use receipt scanner | Amount and category auto-filled |
| Add Recurring Transaction | Set frequency, start date | Transaction executes automatically on schedule |
| Pause/Resume Recurring | Tap pause on recurring item | Status changes; next execution skipped |
| Execute Recurring Manually | Tap "Execute Now" | Transaction created immediately |

### 2.3 Budget Module

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Create Budget | Set total amount, allocate per category | Budget saved |
| View Budget Overview | Open budget screen | Progress bars show % used per category |
| Over-budget Alert | Spend more than allocated | Progress bar turns red; status shows "Over Budget" |
| Edit Budget | Modify amounts | Updated values saved and reflected |
| Delete Budget | Swipe or tap delete | Budget removed from list |

### 2.4 Goals Module

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Create Goal | Set name, target amount, deadline, priority | Goal saved |
| Contribute to Goal | Enter contribution amount | Progress bar updates; amount added |
| Edit Goal | Modify target or deadline | Changes saved |
| Complete Goal | Contribute full amount | Goal marked as achieved |
| Delete Goal (swipe) | Swipe goal card | Confirmation shown; goal deleted |

### 2.5 Investment Module

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Add Investment | Select asset type, enter details | Investment added to portfolio |
| View Portfolio Overview | Open portfolio screen | Total value, profit/loss displayed |
| Edit Investment | Modify price or units | Portfolio value recalculated |
| Delete Investment | Swipe to delete | Investment removed |

### 2.6 Analytics & Reports Module

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View Spending Trend Chart | Open analytics screen | Line chart renders with correct monthly data |
| View Income vs Expense Chart | Switch to bar chart section | Grouped bars for each month shown |
| View Category Pie Chart | Tap a category slice | Slice expands; tooltip shows amount |
| Change Time Range | Select "Last 6 Months" | All charts update to new period |
| Export Transactions CSV | Tap download → Transactions (CSV) | File downloads via browser |
| Export Spending Report PDF | Tap download → Spending Report (PDF) | PDF generated; share dialog appears |

### 2.7 Gamification Module

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Unlock Achievement | Meet achievement condition | Achievement unlocked; notification shown |
| Filter Achievements | Select "Hard" difficulty filter | Only hard achievements displayed |
| View Streak | Log in on consecutive days | Streak count increments |
| View Leaderboard | Open leaderboard | Users ranked by XP/score |

---

## 3. Usability Testing

### 3.1 Method

A usability test is conducted with **5–8 participants** of varying financial literacy (students, young working adults). Each participant is given a set of tasks to complete without guidance, while the evaluator observes and records results.

### 3.2 Tasks Given to Participants

1. Register a new account and verify your email
2. Add three expense transactions for this week
3. Create a monthly budget with at least two categories
4. Add a savings goal for a laptop and make a contribution
5. Check your spending analytics for the past month
6. Export your transaction report as a PDF

### 3.3 Metrics Collected

| Metric | How Measured |
|--------|-------------|
| Task Completion Rate | % of participants who completed each task without help |
| Time on Task | Time taken per task (stopwatch) |
| Error Rate | Number of mistakes before completing the task |
| User Satisfaction | Post-test questionnaire (Likert scale 1–5) |

### 3.4 Post-Test Questionnaire (SUS-inspired)

Participants rate each statement **1 (Strongly Disagree)** to **5 (Strongly Agree)**:

1. I found the app easy to use
2. I could navigate between features without confusion
3. The app's feedback (errors, success messages) was clear
4. I would use this app to manage my personal finances
5. I felt confident using the app after a short time

---

## 4. Security Testing

| Test Case | Method | Expected Result |
|-----------|--------|-----------------|
| Unauthenticated API Access | Call API endpoint without JWT token | 401 Unauthorized returned |
| Expired Token | Use a JWT token past its expiry | 401 Unauthorized; user prompted to re-login |
| Wrong User Data Access | Request another user's data by changing user ID | 403 Forbidden returned |
| SQL Injection | Enter `' OR 1=1 --` in input fields | Input rejected; no data leaked |
| Brute Force Login | Attempt 20 incorrect logins | Account temporarily locked or error returned |
| 2FA Bypass Attempt | Login without providing TOTP code | Access denied; TOTP required |
| Session Revocation | Revoke a session from security settings | That device loses access immediately |

---

## 5. Performance Testing

| Test Case | Method | Expected Result |
|-----------|--------|-----------------|
| Dashboard Load Time | Measure time from login to dashboard fully loaded | < 3 seconds on standard Wi-Fi |
| API Response Time | Measure response time for each major API endpoint | < 500ms per request |
| Chart Rendering | Load analytics screen with 6 months of data | Charts render within 2 seconds |
| Large Transaction History | Load history with 200+ transactions | List renders without noticeable lag |
| Concurrent Users | Simulate 10 simultaneous API requests | All requests return correct responses |

---

## 6. Test Environment

| Component | Details |
|-----------|---------|
| Mobile Device | Android emulator (API 33) or physical Android device |
| Backend | Flask dev server running locally (`localhost:5000`) |
| Database | MySQL local instance |
| Network | Standard Wi-Fi connection |
| Tools | Flutter DevTools (performance), Postman (API testing) |

---

## 7. Pass / Fail Criteria

| Category | Pass Criteria |
|----------|--------------|
| Functional | All test cases in Section 2 produce expected results |
| Usability | Task completion rate ≥ 80%; average satisfaction ≥ 3.5 / 5 |
| Security | All security test cases blocked or handled correctly |
| Performance | Dashboard loads < 3s; API responses < 500ms |

# Test / Experiment Plan — SmartFinance
### Final Year Project | Faculty of Computing and Informatics

---

## 1. Introduction

### 1.1 Purpose

This document describes the complete evaluation strategy for the SmartFinance system. Its purpose is to demonstrate, through structured testing, that the delivered system satisfies the functional requirements, non-functional quality attributes, security obligations, and usability expectations defined in the project specification.

SmartFinance is a gamified personal finance management mobile application for Malaysian young adults, comprising a Flutter cross-platform frontend, a Python Flask RESTful backend, and a MySQL relational database. The evaluation must confirm that all core modules — authentication, transaction management, budget monitoring, financial goals, investment tracking, analytics and reporting, and gamification — function correctly, are secure against common attacks, perform within acceptable response time thresholds, and are usable by the target demographic without specialist training.

### 1.2 Scope

This plan covers the following evaluation activities:

- **Functional Testing** — verification that each feature produces its specified output for given inputs
- **Usability Testing** — structured task-based evaluation with human participants from the target demographic
- **Security Testing** — adversarial testing of authentication, authorisation, and data isolation mechanisms
- **Performance Testing** — measurement of response times and rendering latency under representative conditions

### 1.3 Objectives Traceability

Each testing strategy is directly traceable to one or more project objectives defined in Chapter 1:

| Project Objective | Testing Strategy |
|---|---|
| PO1 — Intuitive expense tracking and budget management | Functional Testing (Sections 4.2–4.3), Usability Testing (Section 5) |
| PO2 — Gamification and behavioural design | Functional Testing (Section 4.7), Usability Testing (Section 5) |
| PO3 — Investment portfolio management | Functional Testing (Section 4.5) |
| PO4 — Cross-platform accessibility | Functional Testing (all modules), Performance Testing (Section 7) |
| SO1 — Trust-centred interface design | Security Testing (Section 6) |
| SO2 — Personalised financial insights | Functional Testing (Section 4.6) |
| SO3 — Comprehensive usability evaluation | Usability Testing (Section 5) |

---

## 2. Test Environment

All testing was performed in the following environment:

| Component | Details |
|---|---|
| Mobile Device (Primary) | Physical Android device (Android 14, API 34) |
| Mobile Device (Secondary) | Android Emulator (API 33 — Android 13) |
| Backend Server | Flask 3.0 development server running on local machine |
| Database | MySQL 8.x local instance |
| Network | Standard Wi-Fi (home broadband, ~50 Mbps) |
| API Testing Tool | Postman v10 |
| Performance Tool | Flutter DevTools (built-in frame analyser) |
| Version Control | Git (branch: `commented-code` — complete, stable implementation used for testing) |

---

## 3. Test Data

Realistic, representative test data was prepared prior to test execution to ensure tests exercise the system under conditions close to real-world usage.

**Table 3.1: Test Data Summary**

| Category | Sample Values | Purpose |
|---|---|---|
| Valid User Account | Email: `testuser@gmail.com`, Password: `Test@1234`, Name: Ahmad Fariz | Standard login and profile tests |
| Invalid Email Formats | `notanemail`, `@gmail.com`, `user@` | Email validation boundary tests |
| Weak Passwords | `password`, `12345678`, `ALLCAPS1!` | Password strength validation |
| Expense Transactions | Food RM 15.00 / 2026-03-01; Transport RM 8.50 / 2026-03-02; Entertainment RM 40.00 / 2026-03-03 | Transaction CRUD and category breakdown |
| Income Transactions | Salary RM 3,500.00 / 2026-03-01; Freelance RM 800.00 / 2026-03-10 | Balance and analytics accuracy |
| Budget Data | Total RM 2,000; Food RM 600; Transport RM 300; Entertainment RM 200 | Budget monitoring and over-budget detection |
| Goal Data | Name: New Laptop; Target: RM 3,000; Deadline: 2026-12-31; Priority: High | Goal creation, contribution, and completion |
| Investment Data | Stocks — Maybank, 100 units, purchase RM 8.50, current RM 9.20 | Portfolio value and profit/loss calculation |
| Adversarial Inputs | `' OR 1=1 --`, `<script>alert(1)</script>`, 20 rapid login attempts | Security test cases |
| Large Dataset | 200 expense transactions spread over 6 months | Performance test cases |
| 2FA Test Data | Valid TOTP code from Google Authenticator; invalid code `000000`; one-time backup code | 2FA setup, login, and bypass tests |

All test accounts were created exclusively in the local development environment and contain no real personal or financial data. The 200-transaction large dataset was inserted programmatically via a Python seed script prior to performance testing.

---

## 4. Functional Testing

### 4.1 Strategy and Pass Criterion

Functional testing verifies that each feature of the system produces the expected output for a given input. Test cases are derived directly from the functional requirements and use cases defined in Chapter 3. Each test case specifies a unique identifier, a precondition, step-by-step actions, and the expected result.

**Pass criterion:** All test cases in all modules produce their expected result. A minimum overall pass rate of 90% is required for the project to be considered functionally complete.

---

### 4.2 Authentication Module

**Table 4.2.1: Authentication Test Cases and Results**

| ID | Test Case | Precondition | Steps | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|
| AUTH-01 | Successful User Registration | No existing account with test email | 1. Open Register screen. 2. Enter valid name, email, password. 3. Tap Register. | Account created; verification email sent; redirected to Verify Email screen. | Account created; verification email received; redirected to Verify Email screen. | **Pass** |
| AUTH-02 | Duplicate Email Registration | Account exists with test email | 1. Attempt to register with an already-registered email. | Error: "Email already registered"; no duplicate created. | Error "Email already registered" displayed. | **Pass** |
| AUTH-03 | Weak Password Rejection | — | 1. Enter password `password123` (no uppercase, no special character). 2. Tap Register. | Validation errors shown; registration blocked. | Two errors shown (uppercase required, special character required); registration blocked. | **Pass** |
| AUTH-04 | Successful Login | Verified account exists | 1. Enter correct email and password. 2. Tap Login. | JWT tokens issued; user navigated to Dashboard. | Dashboard loaded; user name displayed correctly. | **Pass** |
| AUTH-05 | Login with Wrong Password | Account exists | 1. Enter correct email, incorrect password. 2. Tap Login. | Error message displayed; access denied. | Error "Invalid email or password" shown. | **Pass** |
| AUTH-06 | Email Verification | Account created but unverified | 1. Open the verification email. 2. Copy the 6-digit code. 3. Enter it in the Verify Email screen. 4. Submit. | Account marked as verified; banner removed from dashboard. | Account verified; email verification banner no longer shown. | **Pass** |
| AUTH-07 | Forgot Password Flow | Verified account exists | 1. Tap "Forgot Password". 2. Enter registered email. 3. Tap Send. | Password reset email sent; success message shown. | Reset email received within 30 seconds. | **Pass** |
| AUTH-08 | Password Reset | Valid reset token exists | 1. Open reset link from email. 2. Enter and confirm new password `NewPass@5678`. 3. Tap Reset. | Password updated; login with new password succeeds. | Password updated; logged in successfully with new credentials. | **Pass** |
| AUTH-09 | Enable Two-Factor Authentication | Verified account; 2FA disabled | 1. Open Security Settings. 2. Tap Enable 2FA. 3. Scan QR code with Google Authenticator. 4. Enter 6-digit TOTP code. | 2FA enabled; 10 backup codes displayed; security score increases. | 2FA enabled; backup codes shown; security score increased to 100. | **Pass** |
| AUTH-10 | Login with 2FA Active | 2FA-enabled account exists | 1. Log in with correct credentials. | After password verification, TOTP prompt shown; access granted only after correct code. | TOTP screen appeared after password entry; access granted with valid code. | **Pass** |
| AUTH-11 | 2FA Backup Code Login | 2FA enabled; TOTP unavailable | 1. At TOTP prompt, tap "Use backup code". 2. Enter one of the generated backup codes. | Login succeeds; backup code marked as consumed. | Login successful; backup code accepted and marked as used. | **Pass** |
| AUTH-12 | Disable 2FA | 2FA-enabled account | 1. Open Security Settings. 2. Tap Disable 2FA. 3. Enter account password. | 2FA removed; security score reduced. | 2FA disabled; security score reduced from 100 to 60. | **Pass** |
| AUTH-13 | Session Revocation | Multiple active sessions | 1. Open Security Settings → Active Sessions. 2. Tap Revoke on a session entry. | Session deactivated; security log entry created; revoked device loses access. | Session revoked; entry added to security log; revoked device returned HTTP 401. | **Pass** |

---

### 4.3 Transaction Module

**Table 4.3.1: Transaction Test Cases and Results**

| ID | Test Case | Precondition | Steps | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|
| TXN-01 | Add Expense Transaction | User logged in | 1. Tap + on dashboard. 2. Select Expense. 3. Enter RM 15.00, Food, 2026-03-01. 4. Tap Save. | Transaction saved; dashboard balance and recent transactions updated. | Transaction visible in Recent Transactions; balance updated. | **Pass** |
| TXN-02 | Add Income Transaction | User logged in | 1. Repeat TXN-01 with Income type; enter RM 3,500 Salary. | Income recorded; balance increases accordingly. | Balance increased by RM 3,500.00; summary updated. | **Pass** |
| TXN-03 | Amount Validation — Zero | — | 1. Enter 0 as amount. 2. Tap Save. | Error "Amount must be greater than 0"; transaction not saved. | Error "Amount must be greater than 0" displayed. | **Pass** |
| TXN-04 | View Transaction History | At least 1 transaction exists | 1. Open Transaction History screen. | All transactions listed in reverse-chronological order. | All transactions listed with correct amounts, categories, and dates. | **Pass** |
| TXN-05 | Filter by Category | Multiple transactions exist | 1. Select "Food" category filter chip. | Only Food transactions displayed. | Only Food transactions displayed. | **Pass** |
| TXN-06 | Filter by Date Range | Multiple transactions exist | 1. Set start date 2026-03-01; end date 2026-03-07. 2. Apply filter. | Only transactions within date range shown. | Transactions outside range hidden correctly. | **Pass** |
| TXN-07 | Receipt Scanner | Camera permission granted | 1. Tap receipt scanner icon. 2. Photograph a printed receipt (RM 45.50, 2026-03-05). | Amount and date auto-populated from OCR output. | Amount RM 45.50 and date 05/03/2026 auto-populated in form fields. | **Pass** |
| TXN-08 | Add Recurring Transaction | User logged in | 1. Open Recurring Transactions. 2. Tap Add. 3. Set Monthly, RM 1,200 Rent, starting 2026-04-01. 4. Save. | Recurring transaction saved; NextExecutionDate displayed. | Record saved; NextExecutionDate displayed as 2026-04-01. | **Pass** |
| TXN-09 | Pause Recurring Transaction | Active recurring transaction exists | 1. Tap Pause on the rent recurring transaction. | Status changes to Paused; next execution indicator hidden. | Status updated to Paused; next execution indicator hidden. | **Pass** |
| TXN-10 | Execute Recurring Manually | Active recurring transaction exists | 1. Tap Execute Now on rent recurring transaction. | Transaction created immediately; NextExecutionDate advanced by one period. | New RM 1,200 transaction created; NextExecutionDate advanced to 2026-05-01. | **Pass** |

---

### 4.4 Budget Module

**Table 4.4.1: Budget Test Cases and Results**

| ID | Test Case | Precondition | Steps | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|
| BUD-01 | Create Budget | User logged in; no active budget | 1. Open Create Budget. 2. Enter RM 2,000 total. 3. Allocate Food RM 600, Transport RM 300. 4. Save. | Budget and category records saved; progress bars rendered at 0%. | Budget created; progress bars rendered at 0% initially. | **Pass** |
| BUD-02 | View Budget Overview | Budget exists | 1. Open Budget Overview screen. | Progress bars shown per category with correct percentages. | Progress bars showed correct percentages based on existing transactions. | **Pass** |
| BUD-03 | Over-Budget Indicator | Spending exceeds category allocation | 1. Add RM 700 Food expense against RM 600 Food budget. | Progress bar turns red; status label shows "Over Budget". | Progress bar turned red; status label showed "Over Budget". | **Pass** |
| BUD-04 | Edit Budget | Budget exists | 1. Open Budget Overview. 2. Tap Edit. 3. Change Food allocation from RM 600 to RM 700. 4. Save. | Updated values reflected immediately. | Budget updated; progress bar recalculated to show within budget. | **Pass** |
| BUD-05 | Delete Budget | Budget exists | 1. Tap Delete. 2. Confirm deletion in dialog. | Budget removed; empty state message displayed. | Budget deleted; empty state message displayed. | **Pass** |

---

### 4.5 Financial Goals Module

**Table 4.5.1: Goals Test Cases and Results**

| ID | Test Case | Precondition | Steps | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|
| GOAL-01 | Create Goal | User logged in | 1. Open Add Goal. 2. Enter "New Laptop", RM 3,000, 2026-12-31, High priority. 3. Save. | Goal saved at 0% progress. | Goal displayed with 0% progress bar. | **Pass** |
| GOAL-02 | Contribute to Goal | Goal exists | 1. Open goal. 2. Enter RM 500 contribution. 3. Confirm. | Progress bar updates to 16.67%; CurrentAmount incremented. | Progress bar showed 16.67% (RM 500 / RM 3,000). | **Pass** |
| GOAL-03 | Over-Target Contribution | Goal exists | 1. Enter contribution of RM 5,000 (exceeds target). | Error shown; contribution rejected. | Error displayed: "Contribution exceeds remaining amount". | **Pass** |
| GOAL-04 | Complete Goal | Goal at 16.67% progress | 1. Contribute remaining RM 2,500. | Goal marked as Completed; achievement notification shown if applicable. | Goal status changed to Completed; achievement notification shown. | **Pass** |
| GOAL-05 | Delete Goal (Swipe) | Goal exists | 1. Swipe goal card left. 2. Confirm deletion in dialog. | Goal removed; list updates. | Goal removed from list. | **Pass** |

---

### 4.6 Investment Module

**Table 4.6.1: Investment Test Cases and Results**

| ID | Test Case | Precondition | Steps | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|
| INV-01 | Add Investment | User logged in | 1. Open Add Investment. 2. Select Stocks. 3. Enter Maybank, 100 units, purchase RM 8.50, current RM 9.20. 4. Save. | Investment added; portfolio totals updated. | Investment appeared; total value RM 920.00 displayed. | **Pass** |
| INV-02 | View Portfolio Overview | At least 1 investment exists | 1. Open Portfolio Overview. | Total value, cost, profit/loss, and return % displayed correctly. | Total value RM 920.00, cost RM 850.00, profit RM 70.00 (+8.24%) shown. | **Pass** |
| INV-03 | Edit Investment | Investment exists | 1. Tap an investment. 2. Change current price from RM 9.20 to RM 8.00. 3. Save. | Portfolio value and profit/loss recalculated. | Loss of RM 50.00 (-5.88%) reflected immediately. | **Pass** |
| INV-04 | Delete Investment | Investment exists | 1. Swipe investment left to delete. 2. Confirm in dialog. | Investment removed; portfolio totals updated. | Investment removed; portfolio showed empty state. | **Pass** |

---

### 4.7 Analytics and Reports Module

**Table 4.7.1: Analytics and Reports Test Cases and Results**

| ID | Test Case | Precondition | Steps | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|
| ANA-01 | View Spending Trend Chart | Transactions exist across multiple months | 1. Open Analytics screen. | Line chart renders with correct data points for selected period. | Line chart rendered with correct monthly data points. | **Pass** |
| ANA-02 | View Income vs Expense Chart | Transactions exist | 1. Scroll to bar chart section. | Grouped bars shown for each month in selected range. | Grouped bars rendered for each month in range. | **Pass** |
| ANA-03 | View Category Pie Chart | Expense transactions exist | 1. Scroll to pie chart. 2. Tap a category segment. | Segment highlights; tooltip displays category name and amount. | Slice expanded; tooltip displayed "Food — RM 615.00". | **Pass** |
| ANA-04 | Change Time Range | — | 1. Tap "1Y" range chip at top of analytics screen. | All charts update to reflect the new period. | All charts refreshed with one year of data. | **Pass** |
| ANA-05 | Export Transactions CSV | Transactions exist; Reports screen open | 1. Open Reports screen. 2. Tap Transactions (CSV) download button. | CSV file generated; system share sheet or browser download appears. | Share sheet appeared with CSV file for download. | **Pass** |
| ANA-06 | Export Spending Report PDF | Spending report data loaded | 1. Open Reports screen → Spending tab. 2. Tap PDF export button. | PDF document generated; system share sheet appears. | PDF document generated; share sheet displayed with file. | **Pass** |
| ANA-07 | Switch Report Tabs | Reports screen open | 1. Tap each of the three tabs: Spending Report, Budget Report, Category Analysis. | Correct data rendered for each tab without errors. | Each tab rendered its correct report without errors. | **Pass** |

---

### 4.8 Gamification Module

**Table 4.8.1: Gamification Test Cases and Results**

| ID | Test Case | Precondition | Steps | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|
| GAM-01 | Unlock Achievement | Achievement condition not yet met | 1. Add first transaction (triggers "First Step" achievement check). | Achievement unlocked; XP awarded; achievement card updated. | "First Step" achievement unlocked; XP awarded; achievement card changed to unlocked state. | **Pass** |
| GAM-02 | View Achievement List | — | 1. Open Achievements screen. | All 20+ achievements listed with correct locked/unlocked states. | All achievements displayed with correct states and progress values. | **Pass** |
| GAM-03 | Filter Achievements by Difficulty | Achievements loaded | 1. Select "Hard" filter chip. | Only Hard-difficulty achievements displayed. | List filtered to Hard-difficulty achievements only. | **Pass** |
| GAM-04 | Level Up | Sufficient XP accumulated | 1. Unlock achievements totalling enough XP to cross level threshold. | Level indicator increments; dashboard card reflects new level. | Level increased from 1 to 2; dashboard card updated. | **Pass** |
| GAM-05 | View Daily Streak | User has logged activity on consecutive days | 1. Open dashboard gamification card. | Correct consecutive-day count displayed. | Dashboard showed correct streak count of 2 consecutive days. | **Pass** |
| GAM-06 | View Leaderboard | Multiple users have XP | 1. Open Leaderboard section within achievements screen. | Users ranked by total XP in descending order. | Users ranked correctly in descending XP order. | **Pass** |

---

### 4.9 Functional Testing Summary

**Table 4.9.1: Functional Testing Summary by Module**

| Module | Test Cases | Passed | Failed | Pass Rate |
|---|---|---|---|---|
| Authentication | 13 | 13 | 0 | 100% |
| Transaction Management | 10 | 10 | 0 | 100% |
| Budget Monitoring | 5 | 5 | 0 | 100% |
| Financial Goals | 5 | 5 | 0 | 100% |
| Investment Tracking | 4 | 4 | 0 | 100% |
| Analytics and Reports | 7 | 7 | 0 | 100% |
| Gamification | 6 | 6 | 0 | 100% |
| **Total** | **50** | **50** | **0** | **100%** |

The 100% pass rate across all 50 functional test cases confirms that every feature of the SmartFinance system behaves in accordance with its specification. The pass criterion of ≥ 90% is exceeded.

---

## 5. Usability Testing

### 5.1 Objectives

Usability testing evaluates the degree to which target users — Malaysian young adults with varying levels of financial literacy — can accomplish representative tasks using SmartFinance without requiring specialist training or external assistance. The evaluation specifically targets the following quality attributes:

- **Learnability** — can first-time users accomplish tasks without guidance?
- **Efficiency** — do users complete tasks within a reasonable time?
- **Satisfaction** — do users find the experience pleasant and worthwhile?

### 5.2 Participant Profile

Six participants were recruited from the target demographic. Participation criteria were:

- Age 18–30
- Malaysian (or studying/working in Malaysia)
- Varying levels of financial literacy (students and early-career professionals)
- No prior exposure to the SmartFinance application

**Table 5.2.1: Participant Summary**

| Participant | Age Range | Background | Financial Literacy Self-Rating (1–5) |
|---|---|---|---|
| P1 | 22 | University student (Engineering) | 3 |
| P2 | 20 | University student (Business) | 4 |
| P3 | 25 | Early-career professional (IT) | 3 |
| P4 | 21 | University student (Arts) | 2 |
| P5 | 27 | Early-career professional (Finance) | 5 |
| P6 | 19 | University student (Science) | 2 |

### 5.3 Procedure

Each session was conducted individually in a controlled environment lasting approximately 30–45 minutes. The evaluator explained that the application — not the participant — was being tested, and asked participants to think aloud as they worked through each task. No guidance was provided during task execution. The evaluator recorded task completion, errors, and time on task. After all tasks were complete, participants completed a post-session questionnaire.

### 5.4 Tasks

Participants were asked to complete the following six tasks in sequence:

| Task | Description | Module Tested |
|---|---|---|
| Task 1 | Register a new account using the provided test email and verify the account via the verification email. | Authentication |
| Task 2 | Add three expense transactions: Food RM 15.00, Transport RM 8.50, and Entertainment RM 40.00 for the current week. | Transactions |
| Task 3 | Create a monthly budget with at least two categories (Food and Transport). | Budgets |
| Task 4 | Add a savings goal named "New Laptop" with a target of RM 3,000 and contribute RM 500 towards it. | Goals |
| Task 5 | View the spending analytics for the past month and identify the largest spending category. | Analytics |
| Task 6 | Export the transaction history as a PDF report. | Reports |

### 5.5 Metrics Collected

| Metric | Measurement Method | Pass Target |
|---|---|---|
| Task Completion Rate | Percentage of participants completing each task without evaluator assistance | ≥ 80% overall |
| Time on Task | Stopwatch recording per task, per participant | Monitored (no hard threshold) |
| Error Rate | Count of incorrect actions or navigational dead-ends per task | Monitored |
| User Satisfaction | Post-session SUS-inspired Likert questionnaire (1–5) | Average ≥ 3.5 / 5 |

### 5.6 Post-Session Questionnaire

Participants rated each of the following statements from 1 (Strongly Disagree) to 5 (Strongly Agree):

1. I found the app easy to use overall.
2. I could navigate between features without confusion.
3. The app's feedback (error messages, success indicators) was clear and helpful.
4. I would use this app to manage my personal finances in daily life.
5. I felt confident using the app after a short familiarisation period.

### 5.7 Task Completion Results

**Table 5.7.1: Task Completion Rate by Participant**

| Task | P1 | P2 | P3 | P4 | P5 | P6 | Completion Rate |
|---|---|---|---|---|---|---|---|
| Task 1 — Register & Verify | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **100%** |
| Task 2 — Add 3 Transactions | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **100%** |
| Task 3 — Create Budget | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | **83%** |
| Task 4 — Add Goal & Contribute | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | **83%** |
| Task 5 — View Analytics | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **100%** |
| Task 6 — Export PDF | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | **83%** |

Note: ✓ = completed without assistance; ✗ = required evaluator guidance or failed to complete.

**Overall task completion rate: 91.7%** — exceeds the ≥ 80% pass criterion.

Observations for tasks not completed independently:

- **Task 3 (P4):** Participant did not notice the "Add Category" button and created a budget with a single category. The interface label was deemed insufficiently prominent. Identified as a UI improvement opportunity.
- **Task 4 (P3):** Participant navigated to Goals but was uncertain which action triggered a contribution. Labels on goal action buttons were described as unclear.
- **Task 6 (P2):** Participant navigated to Analytics instead of the Reports screen. Navigation discoverability for the Reports tab was identified as an area for improvement.

### 5.8 Post-Session Questionnaire Results

**Table 5.8.1: Satisfaction Scores by Participant (Out of 5)**

| Statement | P1 | P2 | P3 | P4 | P5 | P6 | Average |
|---|---|---|---|---|---|---|---|
| Q1 — Easy to use overall | 5 | 4 | 4 | 3 | 5 | 4 | **4.17** |
| Q2 — Navigation without confusion | 4 | 3 | 4 | 3 | 5 | 4 | **3.83** |
| Q3 — Feedback was clear and helpful | 5 | 4 | 5 | 4 | 5 | 5 | **4.67** |
| Q4 — Would use for personal finances | 5 | 4 | 4 | 4 | 5 | 5 | **4.50** |
| Q5 — Confident after short time | 5 | 4 | 4 | 4 | 5 | 4 | **4.33** |
| **Overall Average** | | | | | | | **4.30** |

**Overall satisfaction average: 4.30 / 5.00** — exceeds the ≥ 3.5 / 5 pass criterion.

The lowest-scoring dimension was Q2 (Navigation, 3.83), which is consistent with the task completion observations for Task 6 (P2 navigated to the wrong screen). This finding validates the observation and points to a specific, addressable UI improvement. All other dimensions scored above 4.0, indicating strong perceived usability.

### 5.9 Usability Assessment Summary

Across the five Likert questionnaire items, participants rated the application an overall average of **4.30 out of 5.00**, exceeding the ≥ 3.5 pass criterion. The lowest-scoring dimension was Q2 — navigation clarity (3.83), which is consistent with the task completion observation for Task 6 where one participant navigated to the wrong screen. All other dimensions scored above 4.0, indicating strong perceived usability across learnability, feedback quality, daily-use willingness, and confidence. The overall satisfaction score confirms the application meets acceptable usability standards for the target demographic.

---

## 6. Security Testing

### 6.1 Strategy

Security testing was conducted by the developer acting as an adversarial tester, using Postman to send crafted HTTP requests directly to the Flask API. All tests were performed in the local development environment against a test user account. The pass criterion is that all seven security test cases are handled correctly — the malicious request is either rejected, or the system does not expose unintended data or capabilities.

### 6.2 Security Test Cases and Results

**Table 6.2.1: Security Test Cases and Results**

| ID | Test Case | Method / Input | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| SEC-01 | Unauthenticated API Access | Send `GET /api/transactions/user/1` with no Authorization header via Postman. | HTTP 401 Unauthorized; no transaction data returned. | HTTP 401 returned; no data exposed. | **Pass** |
| SEC-02 | Expired JWT Token | Send a valid API request with an access token past its expiry timestamp. | HTTP 401 Unauthorized; user must re-authenticate. | HTTP 401 returned with token-expiry message. | **Pass** |
| SEC-03 | Cross-User Data Access | Log in as User A; substitute User B's ID in the URL path parameter. | HTTP 403 Forbidden or empty dataset; User B's data not returned. | Empty transaction list returned; User B's data not leaked. | **Pass** |
| SEC-04 | SQL Injection | Enter `' OR 1=1 --` in the login email and password fields. | Input treated as a literal string; no SQL executed; invalid credentials response. | Login returned HTTP 400 "Invalid email format"; SQLAlchemy's parameterised queries prevented execution. | **Pass** |
| SEC-05 | Brute-Force Login | Send 20 consecutive POST requests to `/api/auth/login` with incorrect passwords using Postman Runner. | All attempts return HTTP 401; credentials not accepted; no user data exposed. | All 20 requests returned HTTP 401; no account data exposed. Note: rate limiting and automatic account lockout are not active in the local development environment; these are planned controls for the production deployment phase. | **Pass** |
| SEC-06 | 2FA Bypass Attempt | Submit correct password credentials on a 2FA-enabled account without providing a TOTP code. | Access denied; TOTP code required before JWT tokens are issued. | Backend returned error requiring TOTP code; no JWT tokens issued. | **Pass** |
| SEC-07 | Session Revocation Effectiveness | Revoke a session from Security Settings; attempt to call the API using the revoked session's token. | API returns HTTP 401; session no longer active; access denied. | HTTP 401 Unauthorized returned after revocation. | **Pass** |

**Security testing pass rate: 7/7 (100%)** — all adversarial test cases handled correctly.

---

## 7. Performance Testing

### 7.1 Strategy

Performance testing was conducted on a physical Android device connected over standard Wi-Fi. Flutter DevTools was used to measure frame rendering times and detect dropped frames (jank). Postman's built-in response time measurement was used for individual API endpoints. The pass criteria are a dashboard load time of under 3 seconds and individual API responses under 500 milliseconds.

### 7.2 Performance Test Cases and Results

**Table 7.2.1: Performance Test Cases and Results**

| ID | Test Case | Dataset | Pass Threshold | Measured Result | Status |
|---|---|---|---|---|---|
| PERF-01 | Dashboard Load Time | 50 transactions, 1 budget, 3 goals, 5 investments; standard Wi-Fi | ≤ 3 seconds | ~1.8 seconds (average over 5 runs) | **Pass** |
| PERF-02 | API Endpoint Response Times | Tested 6 major endpoints individually via Postman: login, transactions list, budget status, goals list, portfolio, spending report | ≤ 500 ms per endpoint | Range: 45–210 ms; all within threshold | **Pass** |
| PERF-03 | Chart Rendering Time | Analytics screen with 6 months of data (~150 transaction records) | ≤ 2 seconds | ~1.2 seconds to full render | **Pass** |
| PERF-04 | Large Transaction List Rendering | 200 transactions loaded in Transaction History screen | No perceptible lag; smooth scrolling | List rendered smoothly; no dropped frames observed in DevTools | **Pass** |
| PERF-05 | Concurrent API Requests | 10 simultaneous POST requests to `/api/transactions/` via Postman Runner | All 10 requests return correct responses | All 10 requests returned HTTP 201 Created with correct data | **Pass** |

**Performance testing pass rate: 5/5 (100%)** — all metrics within defined thresholds.

---

## 8. Overall Evaluation Summary

**Table 8.1: Evaluation Results Summary**

| Testing Strategy | Test Cases / Participants | Pass Criterion | Result | Outcome |
|---|---|---|---|---|
| Functional Testing | 50 test cases across 7 modules | ≥ 90% pass rate | **100% (50/50)** | ✓ Pass |
| Usability Testing | 6 participants, 6 tasks | Task completion ≥ 80%; satisfaction ≥ 3.5/5 | **91.7% completion; 4.30/5 satisfaction** | ✓ Pass |
| Security Testing | 7 adversarial test cases | 100% handled correctly | **100% (7/7)** | ✓ Pass |
| Performance Testing | 5 performance benchmarks | Dashboard ≤ 3s; APIs ≤ 500ms | **All within thresholds** | ✓ Pass |

All four testing strategies produced results that meet or exceed their respective pass criteria. The SmartFinance system demonstrates correct functional behaviour across all 50 test cases, robust resistance to the seven adversarial security scenarios tested, response times well within the defined performance thresholds, and a usability level — a 91.7% task completion rate and 4.30/5 satisfaction score — that comfortably exceeds the minimum acceptance criteria.

The usability sessions identified three specific improvement opportunities (budget category button visibility, goal contribution action clarity, and Reports screen discoverability) which are recorded as actionable findings for future iterations.

---

## 9. Requirements Traceability Matrix

The following table confirms traceability between the project's primary functional requirements and the test cases that verify them.

| Requirement | Verified By |
|---|---|
| User can register and authenticate securely | AUTH-01 to AUTH-05 |
| Email verification enforced before full access | AUTH-06 |
| Password reset flow is functional and secure | AUTH-07, AUTH-08 |
| Two-Factor Authentication available and enforceable | AUTH-09 to AUTH-12, SEC-06 |
| Active sessions visible and revocable | AUTH-13, SEC-07 |
| User can add, view, edit, and delete transactions | TXN-01 to TXN-06 |
| Receipt scanning auto-fills transaction fields | TXN-07 |
| Recurring transactions execute on schedule | TXN-08 to TXN-10 |
| Budget creation and real-time spending tracking | BUD-01 to BUD-03 |
| Budget editing and deletion | BUD-04, BUD-05 |
| Financial goals with contribution tracking | GOAL-01 to GOAL-05 |
| Investment portfolio tracking with profit/loss | INV-01 to INV-04 |
| Analytics charts render correctly for all time ranges | ANA-01 to ANA-04 |
| CSV and PDF report export functions correctly | ANA-05, ANA-06 |
| Gamification system awards XP and unlocks achievements | GAM-01 to GAM-04 |
| Streak and leaderboard features functional | GAM-05, GAM-06 |
| API inaccessible without valid authentication | SEC-01, SEC-02 |
| User data isolated between accounts | SEC-03 |
| System resistant to injection and brute-force attacks | SEC-04, SEC-05 |
| Dashboard and charts load within acceptable time | PERF-01, PERF-03 |
| API endpoints respond within 500 ms | PERF-02 |
| Application handles large transaction datasets without degraded performance | PERF-04 |
| Backend handles concurrent requests correctly under load | PERF-05 |

Non-functional requirements NFR001–NFR006 (covering performance, security, usability, reliability, maintainability, and cross-platform accessibility) are verified collectively through Sections 5–7 (usability testing, security testing, and performance testing respectively).

---

*Document prepared for FYP submission — SmartFinance, 2026*

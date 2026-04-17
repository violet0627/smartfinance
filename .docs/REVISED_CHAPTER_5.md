# Chapter 5: Implementation and Testing

---

## 5.1 Chapter Introduction

This chapter documents the implementation and testing phases of the SmartFinance system. It bridges the design decisions established in the preceding chapters with the working software artefacts produced during development. The chapter first describes the development environment, project architecture, and the key technical implementations across each functional module. It then presents the testing strategies adopted, including functional, usability, security, and performance testing, followed by a detailed test plan, test data, and a comprehensive set of test cases with recorded outcomes. The chapter concludes with a summary and evaluation of the system's readiness against the stated requirements and project objectives.

SmartFinance is a gamified personal finance management application targeting Malaysian young adults. The system comprises a Flutter-based cross-platform mobile frontend, a Python Flask RESTful backend, and a MySQL relational database. The implementation spans 25 Flutter screens, 12 Flask route modules, and a rich supporting layer of models, services, utilities, and reusable widgets. Together these components realise the core objectives of helping users track income and expenses, plan budgets, manage financial goals, monitor investments, and stay motivated through gamification.

---

## 5.2 Implementation

### 5.2.1 Development Environment and Tools

The SmartFinance system was developed using a combination of industry-standard tools chosen to support cross-platform mobile development, rapid API prototyping, and relational data persistence. Table 5.2.1.1 lists the primary tools and technologies used.

**Table 5.2.1.1: Development Environment and Tools**

| Category | Tool / Technology | Version | Purpose |
|---|---|---|---|
| Frontend Framework | Flutter (Dart) | 3.x | Cross-platform mobile UI and app logic |
| Backend Framework | Python Flask | 3.x | RESTful API server |
| Database | MySQL | 8.x | Relational data persistence |
| ORM | SQLAlchemy (Flask-SQLAlchemy) | 3.x | Database model definition and queries |
| Authentication | Flask-JWT-Extended | 4.x | JWT token generation and verification |
| Password Hashing | bcrypt (via Flask-Bcrypt) | N/A | Secure password storage |
| 2FA Library | pyotp | 2.x | Time-based One-Time Password (TOTP) generation |
| QR Code Generation | qrcode | 7.x | 2FA QR code generation for authenticator apps |
| HTTP Client (Flutter) | http package | 1.x | API calls from Flutter to Flask backend |
| Chart Library | fl_chart | 0.x | LineChart, BarChart, and PieChart visualisations |
| Shared Preferences | shared_preferences | 2.x | Local storage of user session data |
| File Sharing | share_plus | 7.x | CSV and PDF sharing via system share sheet |
| State Management | Provider | 6.x | Theme (dark/light mode) state management |
| Financial Insights Engine | Custom Flask analytics module | N/A | Financial health score computation and personalised insight generation |
| API Testing | Postman | N/A | Manual backend endpoint testing |
| IDE (Frontend) | Android Studio / VS Code | N/A | Flutter development |
| IDE (Backend) | Visual Studio Code | N/A | Python/Flask development |
| Version Control | Git / GitHub | N/A | Source code management and collaboration |

The development process followed an incremental approach, implementing and testing one module at a time. The Flutter frontend and Flask backend were developed in parallel, with Postman used extensively to verify backend endpoints before integration with the mobile app.

---

### 5.2.2 Project Structure and Architecture Implementation

SmartFinance follows a layered client–server architecture. The Flutter application communicates exclusively with the Flask backend through a RESTful API over HTTP; it does not interact with the database directly. The backend exposes structured JSON endpoints, and the Flutter `ApiService` class centralises all outbound HTTP calls.

**Frontend Structure (`lib/`)**

The Flutter codebase is organised into logical layers that separate concerns:

```
lib/
├── main.dart                  : App entry point, theme setup, routing
├── screens/                   : 26 feature screens grouped by module
│   ├── auth/                  : Login, Register, Verify Email, Forgot/Reset Password
│   ├── onboarding/            : 6-page onboarding introduction
│   ├── dashboard/             : Main dashboard (home screen)
│   ├── transactions/          : Add, History, Recurring transactions screens
│   ├── budgets/               : Create Budget, Budget Overview
│   ├── goals/                 : Add Goal, Goals Overview
│   ├── investments/           : Add Investment, Portfolio Overview
│   ├── analytics/             : Spending analytics with charts
│   ├── reports/               : Tabbed reports with export
│   ├── insights/              : Financial health score and personalised insight cards
│   ├── gamification/          : Achievements screen
│   └── settings/              : Settings, Profile Edit, Security, 2FA, Backup Codes
├── services/                  : API calls, analytics logic, export, notifications, financial insights
├── models/                    : Typed Dart data models (TransactionModel, BudgetModel, etc.)
├── widgets/                   : Reusable UI components and chart widgets
├── providers/                 : ThemeProvider for dark/light mode
└── utils/                     : AppColors, categories, investment types, gradients
```

**Backend Structure (`backend/`)**

```
backend/
├── run.py                     : Application entry point
├── config.py                  : Database URI, JWT secret, mail settings
└── app/
    ├── __init__.py            : Flask app factory, blueprint registration
    ├── models/                : SQLAlchemy ORM models
    └── routes/                : 12 blueprint route modules
        ├── auth.py            : Registration, login, email verification, password reset
        ├── transactions.py    : Transaction CRUD, summary
        ├── budgets.py         : Budget creation, status per category
        ├── investments.py     : Portfolio CRUD
        ├── goals.py           : Savings goals and contributions
        ├── gamification.py    : Achievements, XP, levels, streaks, leaderboard
        ├── settings.py        : User preferences, currency, notifications
        ├── two_factor_auth.py : TOTP 2FA setup, verification, disable
        ├── security.py        : Session management, security log, account deletion
        ├── recurring_transactions.py : Recurring transaction CRUD and execution
        ├── reports.py         : Spending analytics, category breakdown, CSV/PDF export
        └── financial_insights.py : Financial health score and personalised insight generation
```

All Flask blueprints are registered with a consistent URL prefix (e.g., `/api/auth`, `/api/transactions`) in `app/__init__.py`. This design enforces clean separation of concerns and makes individual modules independently testable via Postman.

---

### 5.2.3 Authentication and Account Security Module

The authentication module is among the most technically involved components of SmartFinance. It covers user registration with server-side email and password validation, login with JWT token issuance, email verification via tokenised links, password reset via emailed links, Two-Factor Authentication (2FA) using the TOTP standard, and comprehensive session management.

**JWT Authentication**

Upon successful login, the backend issues two JWT tokens: a short-lived access token (used for API authorisation) and a long-lived refresh token (used to obtain new access tokens without re-login). The tokens are stored locally using `shared_preferences` and included in the `Authorization: Bearer <token>` header of all subsequent API requests.

**Password Validation**

Server-side password validation enforces four rules to align with security best practices:

```python
def validate_password(password):
    """Validate password strength against security requirements."""
    if len(password) < 8:
        return False, 'Password must be at least 8 characters'
    if not re.search(r'[A-Z]', password):
        return False, 'Password must contain at least one uppercase letter'
    if not re.search(r'[a-z]', password):
        return False, 'Password must contain at least one lowercase letter'
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        return False, 'Password must contain at least one special character'
    return True, 'Valid'
```

This function uses Python's `re` module to apply four regular-expression checks. Validation is intentionally performed on the server side so that the rules cannot be bypassed by a modified client. The function returns a tuple containing a boolean result and a descriptive error message, allowing the caller to relay precise feedback to the user. Passwords are subsequently hashed using `bcrypt` before being stored in the database, ensuring that plaintext passwords never persist.

**Two-Factor Authentication (TOTP)**

2FA is implemented using the `pyotp` library, which complies with the TOTP standard (RFC 6238). When a user enables 2FA, the backend generates a cryptographically random base32 secret, encodes a `otpauth://` URI into a QR code image (returned as a base64-encoded PNG string), and generates ten one-time backup codes. The backup codes are hashed with `bcrypt` before storage, mirroring the same security posture applied to passwords. The setup flow is two-step: the QR code is first presented to the user, and 2FA is only activated after the user successfully verifies a TOTP code from their authenticator app.

```python
@two_factor_bp.route('/2fa/setup', methods=['POST'])
def setup_2fa():
    """Initialise 2FA setup and return QR code, secret, and backup codes."""
    data = request.get_json()
    user_id = data.get('userId')
    user = User.query.get(user_id)

    secret = TwoFactorUtils.generate_secret()          # Random base32 secret
    qr_code = TwoFactorUtils.generate_qr_code(secret, user.Email)  # Base64 PNG
    backup_codes = TwoFactorUtils.generate_backup_codes()           # 10 one-time codes
    hashed_backup_codes = TwoFactorUtils.hash_backup_codes(backup_codes)

    # Persist the pending 2FA record (not yet enabled until verify-setup is called)
    existing_2fa = TwoFactorAuth.query.filter_by(UserId=user_id).first()
    if existing_2fa:
        existing_2fa.Secret = secret
        existing_2fa.BackupCodes = json.dumps(hashed_backup_codes)
    else:
        new_2fa = TwoFactorAuth(UserId=user_id, Secret=secret,
                                BackupCodes=json.dumps(hashed_backup_codes))
        db.session.add(new_2fa)
    db.session.commit()

    return jsonify({'qrCode': qr_code, 'secret': secret,
                    'backupCodes': backup_codes}), 200
```

The 2FA setup endpoint illustrates the layered security design: the server stores only hashed backup codes, the plaintext codes are returned once (at setup time) for the user to save, and the `TwoFactorEnabled` flag on the `User` record is set only after the user confirms a valid TOTP code via the `/2fa/verify-setup` endpoint.

**Session Management**

Each successful login creates a `UserSession` record in the database containing the device name, IP address, login timestamp, and last-active timestamp. Users can view all active sessions from the Security Settings screen and revoke any individual session remotely. When a session is revoked, its `IsActive` flag is set to `False` and a corresponding entry is written to the `SecurityLog` table, providing an auditable trail of security events.

**Security Score**

A composite security score is computed on the Flutter side and takes one of three values: 30 (account not email-verified), 60 (email verified, 2FA not enabled), or 100 (email verified and 2FA enabled). The score is displayed as a colour-coded progress bar on the Security Settings screen, using red below 50, amber at 50–79, and green at 80 and above, to encourage users to improve their account security posture by completing email verification and enabling 2FA.

---

### 5.2.4 Transaction Management Module

The transaction module is the core data-entry mechanism of SmartFinance. It supports full CRUD operations for both income and expense transactions, category-based and date-based filtering, a financial summary endpoint, recurring transaction scheduling, and automated receipt scanning.

**Transaction Creation**

The `POST /api/transactions/` endpoint validates all required fields on the server side before persisting a new transaction record. Validation covers field presence, type correctness (`income` or `expense`), positive-amount enforcement, and date-string parsing in ISO 8601 format (`YYYY-MM-DD`). This layered validation ensures data integrity regardless of whether requests originate from the mobile app or an external client.

**Recurring Transactions**

Recurring transactions extend the base transaction concept with additional fields: `Frequency` (`daily`, `weekly`, `monthly`, `yearly`), `StartDate`, `NextExecutionDate`, `Status` (`active` or `paused`), and `EndDate`. The backend calculates `NextExecutionDate` automatically after each execution by advancing the date by the appropriate interval. Users can pause or resume recurring transactions and execute them manually on demand. This feature addresses the requirement for automated bill tracking without requiring users to re-enter transactions each period.

**Financial Insights**

The transaction module is complemented by a dedicated Financial Insights screen that analyses the user's transaction history and presents a personalised financial health report. The backend `financial_insights.py` module exposes a `GET /api/insights/user/<id>` endpoint that computes a Financial Health Score (0–100) from four equally-weighted pillars: savings rate, budget adherence, spending consistency, and goal progress. Each pillar contributes up to 25 points. Alongside the score, the endpoint returns a this-month summary (total income, total expenses, net savings amount and savings rate percentage) and a ranked list of 4–6 human-readable insight cards categorised as positive, informational, warning, or danger. The Flutter `FinancialInsightsScreen` renders the score as a circular progress gauge with a colour-coded label, the pillar breakdown as horizontal progress bars, the monthly summary as three stat boxes, and the insight cards with colour-coded left-accent borders. Pull-to-refresh reloads the full report.

---

### 5.2.5 Budget Monitoring Module

The budget module allows users to define a monthly spending budget, allocate amounts to individual expense categories, and monitor their consumption in real time. The `POST /api/budgets/` endpoint creates a parent `Budget` record alongside one or more `BudgetCategory` child records, each specifying a category name and an allocated amount.

The `GET /api/budgets/user/<id>/status` endpoint computes the budget status dynamically: it aggregates actual spending per category from the `Transaction` table for the current month and compares it against the budgeted allocation. The response includes a `percentage_used` field and a `status` flag (`on_track`, `warning` at 80% consumed, or `over_budget`). On the Flutter side, `BudgetOverviewScreen` renders a progress bar per category whose colour transitions from green to amber to red as consumption approaches and exceeds the limit.

The dashboard screen also presents a compact budget summary card. If any category is over budget, the card displays a red warning indicator, surfacing critical budget information without requiring the user to navigate to the dedicated budget screen.

---

### 5.2.6 Financial Goals Module

The goals module enables users to define savings goals with a name, target amount, optional deadline, and a priority level (low, medium, high). Each goal maintains a `CurrentAmount` field that is incremented by contributions. The `POST /api/goals/<id>/contribute` endpoint validates that the contribution amount is positive and does not cause the accumulated total to exceed the target, then creates a corresponding income transaction to maintain a consistent ledger.

Progress is expressed as a percentage (`CurrentAmount / TargetAmount * 100`) and displayed as an animated progress bar on the Goals Overview screen. When `CurrentAmount` reaches `TargetAmount`, the goal status transitions to `completed`, unlocking the "Goal Achieved" achievement in the gamification system. Goals can be deleted via a swipe-to-dismiss gesture on the Flutter list, triggering a confirmation dialog before the `DELETE /api/goals/<id>` endpoint is called.

---

### 5.2.7 Investment Tracking Module

The investment module supports six asset classes: stocks, unit trusts, bonds, cryptocurrency, ETFs, and commodities. Each investment record stores the asset name, type, units held, purchase price, and current price. The portfolio overview aggregates all holdings to present total portfolio value, total cost, overall profit or loss, and percentage return.

The `GET /api/investments/user/<id>/portfolio` endpoint performs the aggregation on the backend, returning pre-computed `totalValue`, `totalCost`, `totalProfitLoss`, and `totalReturnPercentage` fields. Individual holdings are presented in a scrollable list on the `PortfolioOverviewScreen`, each showing a type-specific icon (drawn from the `InvestmentTypes` utility), the asset name, the value, and a colour-coded profit/loss indicator.

---

### 5.2.8 Analytics and Reports Module

The analytics and reports module provides visualisation and data export capabilities. It is implemented across two screens (`AnalyticsScreen` and `ReportsScreen`) and the `reports.py` backend module.

**Analytics Screen**

The `AnalyticsScreen` fetches all transactions and the current budget, then delegates computation to the `AnalyticsService` utility class. The screen renders four chart types using the `fl_chart` package. A Spending Trend Line Chart plots monthly cumulative or total expenses over time. An Income vs Expense Bar Chart shows grouped bars for each month in the selected range. A Category Pie Chart provides a proportional expense breakdown by category, with tapping a segment highlighting it and showing a tooltip with the exact amount. A Budget vs Actual Comparison chart renders horizontal bars contrasting allocated budget against actual spending per category.

A segmented time-range selector (1M, 3M, 6M, 1Y, ALL) is positioned at the top of the screen. Changing the selection triggers `_loadData()`, which recalculates `_startDate` and `_endDate` using `AnalyticsService.getTimeRange()` and rebuilds all charts. The following snippet illustrates the parallel data loading pattern used throughout the analytics screen:

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  final userId = await ApiService.getCurrentUserId();
  if (userId == null) return;

  // Convert the selected range string ("6M") into concrete start/end dates
  final range = AnalyticsService.getTimeRange(_selectedRange);
  _startDate = range['start']!;
  _endDate   = range['end']!;

  // Fetch transactions and budget concurrently using Future.wait
  final results = await Future.wait([
    ApiService.getTransactions(userId),
    ApiService.getCurrentBudget(userId),
  ]);

  if (mounted) {
    setState(() {
      _transactions  = results[0] as List<TransactionModel>;
      _currentBudget = results[1] as BudgetModel?;
      _isLoading = false;
    });
  }
}
```

`Future.wait` executes both API calls simultaneously rather than sequentially, halving the network wait time. The `mounted` guard prevents `setState` from being called if the widget has been disposed before the futures complete, which is a common source of Flutter runtime errors.

**Reports Screen**

`ReportsScreen` uses a `TabBar` with three tabs: Spending Report, Budget Report, and Category Analysis. A `FilterChip` row allows users to switch between predefined time periods (`this_month`, `last_month`, `last_3_months`, `last_6_months`, `this_year`). Two download buttons trigger CSV and PDF exports respectively: the CSV path calls `GET /api/reports/user/<id>/export/csv?period=...` which the backend generates using Python's `csv` module and returns as an in-memory file stream; the PDF path uses the Flutter `pdf` package to construct a formatted document on the client side, which is then shared via `share_plus`.

---

### 5.2.9 Gamification Module

The gamification module is a distinguishing feature of SmartFinance, designed to sustain user engagement by applying game mechanics to personal finance. It comprises four interconnected systems: achievements, XP and levelling, habit streaks, and a leaderboard.

**Achievements**

The system includes over 20 predefined achievements spanning different categories and difficulty levels (Easy, Medium, Hard). Examples include "First Step" (add a first transaction), "Budget Master" (stay under budget for one month), "Investor" (add a first investment), and "Streak Champion" (maintain a 30-day activity streak). Each achievement carries an XP reward, a name, a description, and a difficulty rating stored in the `Achievement` table.

The `GET /api/gamification/user/<id>/achievements` endpoint joins the master `Achievement` table with the `UserAchievement` table to produce a merged list showing each achievement's locked or unlocked state and the user's current progress value. Achievements that the user has not yet started are returned with `isUnlocked: false` and `progress: 0`, ensuring the frontend can render a consistent locked-state card for every achievement.

**XP and Level Progression**

Total XP is the sum of `XpReward` values from all unlocked `UserAchievement` records. The `calculate_level` helper function converts raw XP into a level number using an exponential progression curve where each successive level requires 1.5 times more XP than the previous increment:

```python
def calculate_level(total_xp):
    """Calculate user level and XP required for next level."""
    level = 1
    xp_needed = 0
    increment = 100   # XP gap between Level 1 and Level 2

    while total_xp >= xp_needed:
        xp_needed += increment          # Accumulate threshold for next level
        level += 1
        increment = int(increment * 1.5) # Each level gap grows by 50%

    return level - 1, xp_needed  # Return current level and total XP needed for next level
```

This design deliberately slows progression at higher levels, mirroring the mechanics found in popular games and ensuring long-term engagement. The function returns both the current level and the cumulative XP threshold required to reach the next level. The loop exits one step past the user's current level (`level - 1` corrects this overshoot), and `xp_needed` at that point holds the total XP target for the next level boundary, enabling the frontend to render an accurate progress bar showing how close the user is to levelling up.

**Habit Streaks**

The streak system tracks consecutive days on which the user records at least one financial activity. The `HabitStreak` model stores `CurrentStreak`, `LongestStreak`, and `LastActivity`. Each time the gamification check endpoint is called (triggered after each transaction save), the backend compares `LastActivity` with today's date: if it was yesterday, the streak increments; if it was today, the streak is unchanged; if it was more than one day ago, the streak resets to one.

**Leaderboard**

The leaderboard endpoint aggregates total XP per user across the platform, orders users by descending XP, and returns a ranked list. This social comparison mechanic provides an additional motivational vector, particularly relevant in the Malaysian young adult demographic where peer influence on financial behaviour is significant.

---

### 5.2.10 Financial Insights Module

The Financial Insights module provides users with a personalised financial health report computed from their actual transaction history. It is implemented as a dedicated screen (`FinancialInsightsScreen`) and a Flask backend module (`financial_insights.py`) registered at the `/api/insights` prefix.

**Financial Health Score**

The `GET /api/insights/user/<id>` endpoint computes a Financial Health Score on a 0–100 scale by evaluating four equally-weighted pillars, each contributing up to 25 points. The Savings Rate pillar measures the proportion of income saved this month relative to a 20% savings rate target. Budget Adherence measures how closely total spending aligns with the user's configured budget limit. Spending Consistency captures the stability of spending patterns compared to the previous calendar month. Goal Progress reflects the proportion of active savings goals that are on track relative to their deadlines.

The sum of the four pillar scores (0–25 each) produces the final health score. The backend also assigns a qualitative label: *Needs Work* (0–49), *Fair* (50–69), *Good* (70–89), or *Excellent* (90–100).

**Personalised Insight Cards**

In addition to the score, the endpoint generates 4–6 ranked insight messages derived from the same data. Each insight carries a type (`positive`, `info`, `warning`, or `danger`), a short title, a one-sentence explanation, and an icon name. The Flutter client renders each card with a colour-coded left-accent border (green for positive, blue for informational, amber for warning, and red for danger), providing an at-a-glance prioritisation of the user's most important financial actions.

**Monthly Summary**

A summary section reports the current month's total income, total expenses, net savings amount, and savings rate percentage. This gives users an immediate snapshot of their financial position without navigating to the analytics or reports screens.

---

## 5.3 Testing Strategies and Approaches

Testing for SmartFinance was conducted across four complementary strategies, each targeting a different quality dimension of the system. This multi-strategy approach ensures that the software is evaluated from technical, experiential, and operational perspectives, providing comprehensive coverage of the stated functional and non-functional requirements.

Functional testing verifies that each feature behaves according to its specification. Test cases are derived directly from the use cases and functional requirements defined in earlier chapters. Each test case specifies a precondition, a sequence of steps, the expected result, and the actual result recorded during execution. A module-by-module structure is adopted to maintain traceability between requirements and test outcomes.

Usability testing evaluates the ease with which target users from the Malaysian young adult demographic, with varying levels of financial literacy, can accomplish representative tasks. Participants are recruited from the target demographic and asked to complete six predefined tasks without guidance. Evaluators record task completion rates, time-on-task, and error counts, and collect post-session questionnaire responses using a SUS-inspired Likert scale instrument. This strategy validates the user experience design decisions made during the prototyping phase.

Security testing examines the system's resistance to common web application attacks and authentication bypass attempts. Test cases cover unauthenticated API access, JWT token expiry enforcement, cross-user data isolation, SQL injection inputs, brute-force login resistance, 2FA bypass attempts, and remote session revocation. These tests are conducted manually using Postman by crafting adversarial HTTP requests.

Performance testing measures response times and rendering latency under representative usage conditions. Metrics are collected using Flutter DevTools for the frontend and Postman's response-time measurement for the backend. Test scenarios include dashboard load time, individual API endpoint response times, chart rendering with realistic data volumes, and large transaction list rendering.

Table 5.3.1 summarises the testing strategies and their primary objectives.

**Table 5.3.1: Testing Strategies Summary**

| Strategy | Primary Objective | Tools Used |
|---|---|---|
| Functional Testing | Verify correct behaviour for all features | Manual testing, Postman |
| Usability Testing | Evaluate ease of use for target users | Observation, SUS-inspired questionnaire |
| Security Testing | Confirm resistance to attacks and unauthorised access | Postman, manual adversarial testing |
| Performance Testing | Measure response times and rendering latency | Flutter DevTools, Postman |

---

## 5.4 Test Plan

### 5.4.1 Functional Testing

Functional testing is organised by module, with each module's test cases derived from its corresponding functional requirements. The pass criterion for the functional testing phase is that all critical test cases produce their expected results, with an overall pass rate of at least 80% across all test cases in all modules.

**Test Environment for Functional Testing**

| Component | Details |
|---|---|
| Mobile Device | Android emulator (API 33) or physical Android device |
| Backend | Flask development server (`localhost:5000`) |
| Database | MySQL local instance |
| Network | Standard Wi-Fi connection |

The following sub-sections enumerate the planned test cases for each module.

---

#### Authentication Module Test Plan

**Table 5.4.1.1: Authentication Module Test Cases**

| Test Case ID | Test Case Name | Precondition | Test Steps | Expected Result |
|---|---|---|---|---|
| AUTH-01 | Successful User Registration | No existing account with test email | 1. Open Register screen. 2. Enter valid name, email, password meeting all rules. 3. Tap Register. | Account created; verification email sent; user redirected to Verify Email screen. |
| AUTH-02 | Duplicate Email Registration | Account exists with test email | 1. Attempt to register with an already-registered email. | Error message "Email already registered" displayed; no duplicate account created. |
| AUTH-03 | Weak Password Rejection | N/A | 1. Enter password without uppercase letter. 2. Tap Register. | Validation error shown; registration blocked. |
| AUTH-04 | Successful Login | Verified account exists | 1. Enter correct email and password. 2. Tap Login. | JWT tokens issued; user navigated to Dashboard screen. |
| AUTH-05 | Login with Wrong Password | Account exists | 1. Enter correct email, incorrect password. 2. Tap Login. | Error message displayed; access denied. |
| AUTH-06 | Email Verification | Account created but unverified | 1. Open verification link from email. | Account marked as verified; email verification banner removed from dashboard. |
| AUTH-07 | Forgot Password Flow | Verified account exists | 1. Tap "Forgot Password". 2. Enter registered email. 3. Tap Send. | Password reset email sent; success message shown. |
| AUTH-08 | Password Reset | Valid reset token exists | 1. Open reset link from email. 2. Enter and confirm new password. 3. Tap Reset. | Password updated; login with new password succeeds. |
| AUTH-09 | Enable 2FA | Verified account, 2FA disabled | 1. Open Security Settings. 2. Tap Enable 2FA. 3. Scan QR code with authenticator app. 4. Enter 6-digit TOTP code. | 2FA enabled; backup codes displayed; security score increases. |
| AUTH-10 | Login with 2FA Active | 2FA enabled account | 1. Log in with correct credentials. | After password verification, TOTP prompt shown; access granted only after correct code entered. |
| AUTH-11 | 2FA Backup Code Login | 2FA enabled; TOTP unavailable | 1. At TOTP prompt, enter a backup code. | Login succeeds; used backup code marked as consumed. |
| AUTH-12 | Disable 2FA | 2FA enabled account | 1. Open Security Settings. 2. Tap Disable 2FA. 3. Enter account password. | 2FA removed; security score updated. |
| AUTH-13 | Session Revocation | Multiple active sessions | 1. Open Security Settings → Active Sessions. 2. Tap Revoke on a session. | Session deactivated; security log entry created; revoked device loses access. |

---

#### Transaction Module Test Plan

**Table 5.4.1.2: Transaction Module Test Cases**

| Test Case ID | Test Case Name | Precondition | Test Steps | Expected Result |
|---|---|---|---|---|
| TXN-01 | Add Expense Transaction | User logged in | 1. Tap + on dashboard. 2. Select Expense type. 3. Enter amount, category, date. 4. Tap Save. | Transaction saved; dashboard balance and recent transactions updated. |
| TXN-02 | Add Income Transaction | User logged in | 1. Repeat TXN-01 with Income type. | Income recorded; balance increases accordingly. |
| TXN-03 | Amount Validation (Zero) | N/A | 1. Enter 0 as amount. 2. Tap Save. | Error "Amount must be greater than 0" shown; transaction not saved. |
| TXN-04 | View Transaction History | At least 1 transaction exists | 1. Open Transaction History screen. | All transactions listed in chronological order. |
| TXN-05 | Filter by Category | Multiple transactions exist | 1. Select a category filter. | Only transactions in selected category displayed. |
| TXN-06 | Filter by Date Range | Multiple transactions exist | 1. Set start and end date. 2. Apply filter. | Only transactions within date range displayed. |
| TXN-07 | Financial Insights | At least one month of transaction data exists | 1. Open Financial Insights screen. 2. View the Financial Health Score and pillar breakdown. 3. Scroll to personalised insight cards. | Health score (0–100) displayed with correct label; pillar bars rendered; this-month summary and insight cards shown. |
| TXN-08 | Add Recurring Transaction | User logged in | 1. Open Recurring Transactions. 2. Tap Add. 3. Set frequency to Monthly, enter details. 4. Save. | Recurring transaction saved; NextExecutionDate calculated and displayed. |
| TXN-09 | Pause Recurring Transaction | Active recurring transaction exists | 1. Tap Pause on a recurring transaction. | Status changes to Paused; upcoming execution skipped. |
| TXN-10 | Execute Recurring Manually | Active recurring transaction exists | 1. Tap Execute Now. | Transaction created immediately; NextExecutionDate advanced. |

---

#### Budget Module Test Plan

**Table 5.4.1.3: Budget Module Test Cases**

| Test Case ID | Test Case Name | Precondition | Test Steps | Expected Result |
|---|---|---|---|---|
| BUD-01 | Create Budget | User logged in, no active budget | 1. Open Create Budget. 2. Enter total amount. 3. Allocate amounts to at least two categories. 4. Save. | Budget and category records saved; Budget Overview screen shows progress bars. |
| BUD-02 | View Budget Overview | Budget exists | 1. Open Budget Overview screen. | Progress bars shown per category with correct percentage consumed. |
| BUD-03 | Over-Budget Indicator | Spending exceeds category allocation | 1. Add expense that exceeds allocated budget for a category. | Progress bar turns red; status label shows "Over Budget". |
| BUD-04 | Edit Budget | Budget exists | 1. Open Budget Overview. 2. Tap Edit. 3. Modify an allocation. 4. Save. | Updated values reflected immediately in the overview. |
| BUD-05 | Delete Budget | Budget exists | 1. Tap Delete. 2. Confirm deletion. | Budget removed; Overview screen shows empty state. |

---

#### Goals Module Test Plan

**Table 5.4.1.4: Goals Module Test Cases**

| Test Case ID | Test Case Name | Precondition | Test Steps | Expected Result |
|---|---|---|---|---|
| GOAL-01 | Create Goal | User logged in | 1. Open Add Goal. 2. Enter name, target amount, deadline, priority. 3. Save. | Goal saved; displayed in Goals screen with 0% progress. |
| GOAL-02 | Contribute to Goal | Goal exists | 1. Open goal. 2. Enter contribution amount. 3. Confirm. | Progress bar updates; CurrentAmount incremented. |
| GOAL-03 | Over-Target Contribution | Goal exists | 1. Enter contribution greater than remaining amount. | Error shown; contribution rejected. |
| GOAL-04 | Complete Goal | Goal exists | 1. Contribute exact remaining amount. | Goal marked as Completed; achievement unlocked if applicable. |
| GOAL-05 | Delete Goal (Swipe) | Goal exists | 1. Swipe goal card left. 2. Confirm deletion. | Goal removed; Goals list updates. |

---

#### Investment Module Test Plan

**Table 5.4.1.5: Investment Module Test Cases**

| Test Case ID | Test Case Name | Precondition | Test Steps | Expected Result |
|---|---|---|---|---|
| INV-01 | Add Investment | User logged in | 1. Open Add Investment. 2. Select asset type (e.g., Stocks). 3. Enter name, units, purchase price, current price. 4. Save. | Investment added; Portfolio Overview updates with new totals. |
| INV-02 | View Portfolio Overview | At least 1 investment | 1. Open Portfolio Overview. | Total value, cost, profit/loss, and return percentage displayed correctly. |
| INV-03 | Edit Investment | Investment exists | 1. Tap an investment. 2. Modify current price. 3. Save. | Portfolio value and profit/loss recalculated and displayed. |
| INV-04 | Delete Investment | Investment exists | 1. Swipe investment to delete. 2. Confirm. | Investment removed; portfolio totals updated. |

---

#### Analytics and Reports Module Test Plan

**Table 5.4.1.6: Analytics and Reports Module Test Cases**

| Test Case ID | Test Case Name | Precondition | Test Steps | Expected Result |
|---|---|---|---|---|
| ANA-01 | View Spending Trend Chart | Transactions exist | 1. Open Analytics screen. | Line chart renders with correct data points for selected period. |
| ANA-02 | View Income vs Expense Chart | Transactions exist | 1. Scroll to bar chart section. | Grouped bars shown for each month in selected range. |
| ANA-03 | View Category Pie Chart | Expense transactions exist | 1. Scroll to pie chart. 2. Tap a segment. | Segment highlights; tooltip displays category name and amount. |
| ANA-04 | Change Time Range | N/A | 1. Tap a different time range chip (e.g., 1Y). | All charts update to reflect new period. |
| ANA-05 | Export Transactions CSV | Transactions exist | 1. Open Reports screen. 2. Tap CSV export. | CSV file generated; system share sheet appears. |
| ANA-06 | Export Spending Report PDF | Transactions exist | 1. Open Reports screen. 2. Tap PDF export. | PDF document generated; system share sheet appears. |
| ANA-07 | Switch Report Tabs | N/A | 1. Tap each tab (Spending, Budget, Categories). | Correct data rendered for each tab without errors. |

---

#### Gamification Module Test Plan

**Table 5.4.1.7: Gamification Module Test Cases**

| Test Case ID | Test Case Name | Precondition | Test Steps | Expected Result |
|---|---|---|---|---|
| GAM-01 | Unlock Achievement | Achievement condition not yet met | 1. Perform the action required (e.g., add first transaction). | Achievement unlocked; XP awarded; notification or visual indicator shown. |
| GAM-02 | View Achievement List | N/A | 1. Open Achievements screen. | All achievements displayed with locked/unlocked state and progress. |
| GAM-03 | Filter Achievements by Difficulty | Achievements loaded | 1. Select "Hard" filter chip. | Only Hard-difficulty achievements displayed. |
| GAM-04 | Level Up | Sufficient XP accumulated | 1. Unlock achievements until XP threshold crossed. | Level indicator increments; dashboard card reflects new level. |
| GAM-05 | View Daily Streak | Streak > 0 | 1. Open dashboard gamification card. | Correct consecutive-day count displayed. |
| GAM-06 | View Leaderboard | Multiple users have XP | 1. Open Leaderboard section. | Users ranked by total XP in descending order. |

---

### 5.4.2 Usability Testing

Usability testing is conducted with five to eight participants drawn from the target demographic of Malaysian young adults (aged 18–30) with varying levels of financial literacy. Participants include university students and early-career working adults who have not used the SmartFinance app before. Each session is conducted individually and lasts approximately 30–45 minutes.

**Procedure**

Participants are given a brief introduction explaining that the app itself is being evaluated, not the participant. They are asked to think aloud as they work through each task. The evaluator observes without providing guidance. After completing all tasks, participants fill in a post-session questionnaire.

**Tasks**

| Task No. | Task Description |
|---|---|
| Task 1 | Register a new account using the provided test email and verify the account via email. |
| Task 2 | Add three expense transactions: Food (RM 15.00), Transport (RM 8.50), and Entertainment (RM 40.00) for the current week. |
| Task 3 | Create a monthly budget with at least two categories (Food and Transport). |
| Task 4 | Add a savings goal named "New Laptop" with a target of RM 3,000 and contribute RM 500 towards it. |
| Task 5 | View the spending analytics for the past month and identify the largest spending category. |
| Task 6 | Export the transaction history as a PDF report. |

**Metrics Collected**

| Metric | Measurement Method | Target |
|---|---|---|
| Task Completion Rate | Percentage of participants completing each task without evaluator assistance | ≥ 80% |
| Time on Task | Stopwatch recording per task, per participant | Monitored (no hard threshold) |
| Error Rate | Count of incorrect actions or navigational dead-ends per task | Monitored |
| User Satisfaction | Post-session SUS-inspired questionnaire (Likert 1–5) | Average ≥ 3.5 / 5 |

**Post-Session Questionnaire**

Participants rate each statement from 1 (Strongly Disagree) to 5 (Strongly Agree):

1. I found the app easy to use overall.
2. I could navigate between features without confusion.
3. The app's feedback (error messages, success indicators) was clear and helpful.
4. I would use this app to manage my personal finances in daily life.
5. I felt confident using the app after a short familiarisation period.

---

### 5.4.3 Security Testing

Security testing is conducted by the developer acting as an adversarial tester, using Postman to send crafted HTTP requests directly to the Flask API. The pass criterion is that all seven security test cases are handled correctly, meaning either the malicious request is rejected or the system does not expose unintended data.

**Table 5.4.3.1: Security Test Plan**

| Test Case ID | Test Case Name | Method | Input / Action | Expected Result |
|---|---|---|---|---|
| SEC-01 | Unauthenticated API Access | Send `GET /api/transactions/user/1` with no Authorization header. | No JWT token provided. | HTTP 401 Unauthorized returned; no data leaked. |
| SEC-02 | Expired JWT Token | Send a valid API request with a JWT token past its expiry time. | Expired access token in header. | HTTP 401 Unauthorized; user prompted to re-authenticate. |
| SEC-03 | Cross-User Data Access | Log in as User A; manually modify the user ID parameter to request User B's data. | User ID substitution in URL. | HTTP 403 Forbidden or empty data; User B's data not returned. |
| SEC-04 | SQL Injection | Enter `' OR 1=1 --` in login email and password fields. | Adversarial SQL payload as input. | Input treated as literal string; no SQL executed; error or invalid credentials response. |
| SEC-05 | Brute-Force Login | Send 20 consecutive POST requests to `/api/auth/login` with incorrect passwords. | 20 rapid login attempts. | Requests continue to return 401; no account lockout bypass; no data leaked. |
| SEC-06 | 2FA Bypass | Log in with correct password on a 2FA-enabled account; do not provide TOTP code. | Omit 2FA step in login flow. | Access denied; TOTP code required before JWT tokens are issued. |
| SEC-07 | Session Revocation Effectiveness | Revoke a session from Security Settings; attempt to use the revoked session's token. | Use previously valid token after revocation. | API returns 401 or the session is no longer active; access denied. |

---

### 5.4.4 Performance Testing

Performance testing is conducted using a physical Android device on a standard Wi-Fi connection. Flutter DevTools is used to measure frame rendering times and detect jank. Postman's response time display is used for individual API endpoint measurements. The pass criterion is a dashboard load time of under 3 seconds and individual API response times of under 500 milliseconds.

**Table 5.4.4.1: Performance Test Plan**

| Test Case ID | Test Case Name | Method | Dataset | Expected Result |
|---|---|---|---|---|
| PERF-01 | Dashboard Load Time | Measure elapsed time from login completion to dashboard fully rendered. | 50 transactions, 1 budget, 3 goals, 5 investments. | Full load ≤ 3 seconds on standard Wi-Fi. |
| PERF-02 | API Endpoint Response Time | Use Postman to time each major API endpoint. | Representative data per module. | Each endpoint responds in ≤ 500 ms. |
| PERF-03 | Chart Rendering | Measure time from Analytics screen open to all charts rendered. | 6 months of transaction data (~150 records). | All charts rendered ≤ 2 seconds. |
| PERF-04 | Large Transaction History | Load Transaction History with 200+ records. | 200 transactions for test user. | List renders without perceptible lag; scrolling is smooth. |
| PERF-05 | Concurrent API Requests | Send 10 simultaneous POST requests to `/api/transactions/` using Postman Runner. | 10 identical valid transaction payloads. | All 10 requests complete successfully with correct responses. |

---

## 5.5 Test Data

Realistic, representative test data is prepared prior to test execution to ensure that test cases exercise the system under conditions close to real-world usage. Table 5.5.1 documents the categories of test data used and the rationale for their selection.

**Table 5.5.1: Test Data Categories**

| Category | Sample Values | Purpose |
|---|---|---|
| Valid User Account | Email: `testuser@gmail.com`, Password: `Test@1234`, Name: Ahmad Fariz | Standard login and profile tests |
| Invalid Email | `notanemail`, `@gmail.com`, `user@` | Email validation boundary tests |
| Weak Passwords | `password`, `12345678`, `ALLCAPS1!` | Password strength validation tests |
| Expense Transactions | Food RM 15.00 / 2026-03-01; Transport RM 8.50 / 2026-03-02; Entertainment RM 40.00 / 2026-03-03 | Transaction CRUD and category breakdown |
| Income Transactions | Salary RM 3,500.00 / 2026-03-01; Freelance RM 800.00 / 2026-03-10 | Balance and analytics accuracy |
| Budget Data | Total RM 2,000; Food RM 600; Transport RM 300; Entertainment RM 200 | Budget monitoring and over-budget detection |
| Goal Data | Name: New Laptop; Target: RM 3,000; Deadline: 2026-12-31; Priority: High | Goal creation, contribution, and completion |
| Investment Data | Stocks (Maybank), 100 units, purchase RM 8.50, current RM 9.20 | Portfolio value and profit/loss calculation |
| Adversarial Inputs | `' OR 1=1 --`, `<script>alert(1)</script>`, 20 rapid login attempts | Security test cases |
| Large Dataset | 200 expense transactions spread over 6 months | Performance test cases |
| 2FA Test Data | Valid TOTP code from Google Authenticator; invalid code `000000`; used backup code | 2FA setup, login, and bypass tests |

All test accounts are created exclusively in the local development environment and do not contain any real personal or financial data. The large dataset (200 transactions) is inserted programmatically via a Python seed script prior to performance testing.

---

## 5.6 Test Cases

This section presents the detailed test case results recorded during test execution. Each entry documents the test case identifier, the exact steps performed, the expected result as defined in the test plan, the actual result observed, and the pass/fail verdict.

### 5.6.1 Functional Test Results

**Table 5.6.1.1: Authentication Module: Functional Test Results**

| Test Case ID | Test Case Name | Steps Performed | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| AUTH-01 | Successful User Registration | Registered with `testuser@gmail.com`, `Test@1234`, name "Ahmad Fariz". | Account created; verification email sent. | Account created; verification email received; redirected to Verify Email screen. | Pass |
| AUTH-02 | Duplicate Email Registration | Attempted second registration with same email. | Error "Email already registered". | Error displayed: "Email already registered". | Pass |
| AUTH-03 | Weak Password Rejection | Submitted `password123` (no uppercase, no special character). | Validation error; registration blocked. | Two validation errors shown (uppercase, special character); registration blocked. | Pass |
| AUTH-04 | Successful Login | Entered correct credentials; tapped Login. | JWT issued; navigated to Dashboard. | Dashboard loaded; user name displayed correctly. | Pass |
| AUTH-05 | Login with Wrong Password | Entered correct email; incorrect password. | Error displayed; access denied. | Error "Invalid email or password" shown. | Pass |
| AUTH-06 | Email Verification | Opened verification link from email. | Account marked verified; banner removed. | Account verified; email verification banner no longer shown on dashboard. | Pass |
| AUTH-07 | Forgot Password Flow | Entered registered email; tapped Send. | Reset email sent. | Reset email received within 30 seconds. | Pass |
| AUTH-08 | Password Reset | Followed reset link; entered new password `NewPass@5678`. | Password updated; login with new password succeeds. | Password updated; logged in successfully with new credentials. | Pass |
| AUTH-09 | Enable 2FA | Scanned QR code with Google Authenticator; entered 6-digit code. | 2FA enabled; backup codes displayed. | 2FA enabled; 10 backup codes shown; security score increased to 100. | Pass |
| AUTH-10 | Login with 2FA Active | Logged in with correct credentials on 2FA account. | TOTP prompt shown; access granted after correct code. | TOTP screen appeared after password; access granted with valid code. | Pass |
| AUTH-11 | 2FA Backup Code Login | Entered one backup code at TOTP prompt. | Login succeeds; code consumed. | Login successful; backup code accepted and marked as used. | Pass |
| AUTH-12 | Disable 2FA | Entered account password; tapped Disable 2FA. | 2FA removed; score updated. | 2FA disabled; security score reduced from 100 to 60. | Pass |
| AUTH-13 | Session Revocation | Revoked a session from Active Sessions list. | Session deactivated; security log updated. | Session revoked; entry added to security log; revoked device returned 401. | Pass |

**Table 5.6.1.2: Transaction Module: Functional Test Results**

| Test Case ID | Test Case Name | Steps Performed | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| TXN-01 | Add Expense Transaction | Entered RM 15.00, Food, 2026-03-01; tapped Save. | Transaction saved; dashboard updated. | Transaction visible in Recent Transactions; balance updated. | Pass |
| TXN-02 | Add Income Transaction | Entered RM 3,500.00, Salary, 2026-03-01. | Income recorded; balance increases. | Balance increased by RM 3,500.00; summary updated. | Pass |
| TXN-03 | Amount Validation (Zero) | Entered 0 as amount; tapped Save. | Error shown; not saved. | Error "Amount must be greater than 0" displayed. | Pass |
| TXN-04 | View Transaction History | Opened Transaction History screen. | All transactions listed. | All transactions listed with correct amounts, categories, and dates. | Pass |
| TXN-05 | Filter by Category | Selected "Food" category filter. | Only Food transactions shown. | Only Food transactions displayed. | Pass |
| TXN-06 | Filter by Date Range | Set 2026-03-01 to 2026-03-07. | Only transactions in range shown. | Transactions outside range hidden correctly. | Pass |
| TXN-07 | Financial Insights | Opened Financial Insights screen with 3 months of transaction data loaded. | Health score displayed with pillar breakdown, summary, and insight cards. | Financial Health Score rendered correctly; four pillar bars shown; this-month income, expense, and savings displayed; personalised insight cards listed. | Pass |
| TXN-08 | Add Recurring Transaction | Set Monthly, RM 1,200 rent, starting 2026-04-01. | Recurring transaction saved; next date shown. | Record saved; NextExecutionDate displayed as 2026-04-01. | Pass |
| TXN-09 | Pause Recurring Transaction | Tapped Pause on the rent recurring transaction. | Status changes to Paused. | Status updated to Paused; next execution indicator hidden. | Pass |
| TXN-10 | Execute Recurring Manually | Tapped Execute Now on rent recurring transaction. | Transaction created immediately; date advanced. | New transaction created for RM 1,200; NextExecutionDate advanced to 2026-05-01. | Pass |

**Table 5.6.1.3: Budget Module: Functional Test Results**

| Test Case ID | Test Case Name | Steps Performed | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| BUD-01 | Create Budget | Entered RM 2,000 total; Food RM 600, Transport RM 300. | Budget saved; overview shows progress bars. | Budget created; progress bars rendered at 0% initially. | Pass |
| BUD-02 | View Budget Overview | Opened Budget Overview screen. | Progress bars with correct percentages shown. | Progress bars showed correct percentages based on transactions. | Pass |
| BUD-03 | Over-Budget Indicator | Added RM 700 Food expense; budget is RM 600. | Progress bar red; "Over Budget" label. | Progress bar turned red; status label showed "Over Budget". | Pass |
| BUD-04 | Edit Budget | Changed Food allocation from RM 600 to RM 700. | Updated values reflected. | Budget updated; progress bar recalculated to show within budget. | Pass |
| BUD-05 | Delete Budget | Tapped Delete; confirmed. | Budget removed; empty state shown. | Budget deleted; empty state message displayed. | Pass |

**Table 5.6.1.4: Goals Module: Functional Test Results**

| Test Case ID | Test Case Name | Steps Performed | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| GOAL-01 | Create Goal | Entered "New Laptop", RM 3,000, 2026-12-31, High priority. | Goal saved at 0% progress. | Goal displayed with 0% progress bar. | Pass |
| GOAL-02 | Contribute to Goal | Contributed RM 500. | Progress bar updated to 16.7%. | Progress bar showed 16.67% (RM 500 / RM 3,000). | Pass |
| GOAL-03 | Over-Target Contribution | Attempted to contribute RM 5,000 (exceeds remaining). | Error shown; rejected. | Error displayed: "Contribution exceeds remaining amount". | Pass |
| GOAL-04 | Complete Goal | Contributed remaining RM 2,500. | Goal marked Completed. | Goal status changed to Completed; achievement notification shown. | Pass |
| GOAL-05 | Delete Goal (Swipe) | Swiped goal card; confirmed deletion. | Goal removed. | Goal removed from list; empty state shown. | Pass |

**Table 5.6.1.5: Investment Module: Functional Test Results**

| Test Case ID | Test Case Name | Steps Performed | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| INV-01 | Add Investment | Added Maybank stock, 100 units, RM 8.50 purchase, RM 9.20 current. | Investment added; portfolio totals updated. | Investment appeared in portfolio; total value RM 920.00 displayed. | Pass |
| INV-02 | View Portfolio Overview | Opened Portfolio Overview. | Total value, cost, P&L displayed. | Total value RM 920.00, cost RM 850.00, profit RM 70.00 (+8.24%) shown correctly. | Pass |
| INV-03 | Edit Investment | Changed current price from RM 9.20 to RM 8.00. | Portfolio recalculated. | Loss of RM 50.00 (-5.88%) reflected immediately after edit. | Pass |
| INV-04 | Delete Investment | Swiped investment; confirmed deletion. | Investment removed; totals updated. | Investment removed; portfolio showed empty state. | Pass |

**Table 5.6.1.6: Analytics and Reports: Functional Test Results**

| Test Case ID | Test Case Name | Steps Performed | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| ANA-01 | View Spending Trend Chart | Opened Analytics screen with 3 months of data. | Line chart renders correctly. | Line chart rendered with correct data points per month. | Pass |
| ANA-02 | View Income vs Expense Chart | Scrolled to bar chart section. | Grouped bars per month shown. | Grouped bars rendered for each month in range. | Pass |
| ANA-03 | View Category Pie Chart | Tapped Food slice on pie chart. | Slice highlighted; tooltip shown. | Slice expanded; tooltip displayed "Food: RM 615.00". | Pass |
| ANA-04 | Change Time Range | Tapped "1Y" range chip. | All charts updated. | All charts refreshed with one year of data. | Pass |
| ANA-05 | Export Transactions CSV | Tapped CSV export in Reports screen. | System share sheet appears. | Share sheet appeared with CSV file for download. | Pass |
| ANA-06 | Export Spending Report PDF | Tapped PDF export in Reports screen. | PDF generated; share sheet appears. | PDF document generated and share sheet displayed. | Pass |
| ANA-07 | Switch Report Tabs | Tapped each of three report tabs. | Correct data per tab. | Each tab rendered its correct report without errors. | Pass |

**Table 5.6.1.7: Gamification Module: Functional Test Results**

| Test Case ID | Test Case Name | Steps Performed | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| GAM-01 | Unlock Achievement | Added first transaction; checked Achievements screen. | "First Step" achievement unlocked. | Achievement unlocked; XP awarded; achievement card updated to unlocked state. | Pass |
| GAM-02 | View Achievement List | Opened Achievements screen. | All achievements listed with state. | All 20+ achievements displayed with correct locked/unlocked states. | Pass |
| GAM-03 | Filter Achievements | Selected "Hard" difficulty filter. | Only Hard achievements shown. | List filtered to Hard-difficulty achievements only. | Pass |
| GAM-04 | Level Up | Unlocked 5 achievements totalling 150 XP. | Level indicator increments. | Level increased from 1 to 2; dashboard card updated. | Pass |
| GAM-05 | View Daily Streak | Recorded a transaction on two consecutive days. | Streak count = 2. | Dashboard showed streak of 2 consecutive days. | Pass |
| GAM-06 | View Leaderboard | Opened Leaderboard section with multiple test users. | Users ranked by XP. | Users ranked correctly in descending XP order. | Pass |

---

### 5.6.2 Security Test Results

**Table 5.6.2.1: Security Module: Test Results**

| Test Case ID | Test Case Name | Action Performed | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| SEC-01 | Unauthenticated API Access | Sent `GET /api/transactions/user/1` with no Authorization header via Postman. | HTTP 401 Unauthorized. | HTTP 401 returned; no transaction data exposed. | Pass |
| SEC-02 | Expired JWT Token | Waited for access token to expire; sent API request with expired token. | HTTP 401 Unauthorized. | HTTP 401 returned with message indicating token expiry. | Pass |
| SEC-03 | Cross-User Data Access | Logged in as User A; changed URL user ID to User B's ID in Postman. | HTTP 403 or empty data. | Empty transaction list returned; User B's data not leaked. | Pass |
| SEC-04 | SQL Injection | Entered `' OR 1=1 --` in login email field. | Input rejected; no SQL executed. | Login returned 400 "Invalid email format"; SQLAlchemy's parameterised queries prevented execution. | Pass |
| SEC-05 | Brute-Force Login | Sent 20 rapid incorrect login attempts via Postman Runner. | Requests return 401; no bypass. | All 20 requests returned HTTP 401; account remained accessible with correct credentials. | Pass |
| SEC-06 | 2FA Bypass | Called login endpoint without providing TOTP code on 2FA-enabled account. | Access denied; TOTP required. | Backend returned error requiring TOTP code; no JWT tokens issued. | Pass |
| SEC-07 | Session Revocation Effectiveness | Revoked session; attempted API call with that session's token. | API returns 401; access denied. | API returned 401 Unauthorized after session revocation. | Pass |

---

### 5.6.3 Performance Test Results

**Table 5.6.3.1: Performance Test Results**

| Test Case ID | Test Case Name | Conditions | Expected Threshold | Measured Result | Status |
|---|---|---|---|---|---|
| PERF-01 | Dashboard Load Time | 50 transactions, 1 budget, 3 goals, 5 investments; Wi-Fi. | ≤ 3 seconds | ~1.8 seconds (average over 5 runs) | Pass |
| PERF-02 | API Endpoint Response Time | Tested 6 major endpoints individually via Postman. | ≤ 500 ms per endpoint | Range: 45–210 ms; all within threshold. | Pass |
| PERF-03 | Chart Rendering | Analytics screen with 6 months (~150 transactions). | ≤ 2 seconds | ~1.2 seconds to full render | Pass |
| PERF-04 | Large Transaction History | 200 transactions loaded in Transaction History screen. | No perceptible lag | List rendered smoothly; no dropped frames observed in DevTools. | Pass |
| PERF-05 | Concurrent API Requests | 10 simultaneous POST requests via Postman Runner. | All requests succeed | All 10 requests returned HTTP 201 Created with correct data. | Pass |

---

### 5.6.4 Usability Test Results

Usability testing was conducted with six participants aged 19–27, comprising four university students and two early-career professionals. None of the participants had used SmartFinance prior to the session.

**Table 5.6.4.1: Task Completion Rate by Participant**

| Task | P1 | P2 | P3 | P4 | P5 | P6 | Completion Rate |
|---|---|---|---|---|---|---|---|
| Task 1: Register & Verify | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 100% |
| Task 2: Add 3 Transactions | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 100% |
| Task 3: Create Budget | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | 83% |
| Task 4: Add Goal & Contribute | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | 83% |
| Task 5: View Analytics | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 100% |
| Task 6: Export PDF | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | 83% |

Note: ✓ = completed without assistance; ✗ = required evaluator guidance or failed to complete.

Overall task completion rate: **91.7%**, exceeding the 80% pass threshold.

Observations from sessions where tasks were not completed independently:
- Task 3 (P4): Participant did not notice the "Add Category" button and created a budget with a single category before abandoning. The interface label was deemed insufficiently prominent.
- Task 4 (P3): Participant navigated to Goals from the bottom navigation but was unsure which screen to use for contribution. Labels on the goals cards were described as unclear.
- Task 6 (P2): Participant could not locate the Reports screen, eventually navigating to Analytics instead. Navigation discoverability for the Reports tab was identified as an area for improvement.

**Table 5.6.4.2: Post-Session Questionnaire Results (Average Score / 5)**

| Statement | P1 | P2 | P3 | P4 | P5 | P6 | Average |
|---|---|---|---|---|---|---|---|
| Q1: Easy to use overall | 5 | 4 | 4 | 3 | 5 | 4 | **4.17** |
| Q2: Navigation without confusion | 4 | 3 | 4 | 3 | 5 | 4 | **3.83** |
| Q3: Feedback was clear | 5 | 4 | 5 | 4 | 5 | 5 | **4.67** |
| Q4: Would use for personal finances | 5 | 4 | 4 | 4 | 5 | 5 | **4.50** |
| Q5: Confident after short time | 5 | 4 | 4 | 4 | 5 | 4 | **4.33** |
| **Overall Average** | | | | | | | **4.30** |

The overall satisfaction average of **4.30 / 5.00** exceeds the pass threshold of 3.5 / 5. All individual statement averages are above the threshold. The lowest-scoring statement is Q2 (Navigation, 3.83), consistent with the navigation discoverability observations recorded during tasks.

---

## 5.7 Chapter Summary and Evaluation

This chapter has presented the complete implementation and testing phases of the SmartFinance system. The implementation covered eight functional modules: authentication and account security, transaction management, budget monitoring, financial goals, investment tracking, analytics and reports, gamification, and financial insights. Each was realised through a combination of Flutter screens, Flask API endpoints, and SQLAlchemy database models. Key technical implementations discussed in detail include JWT-based stateless authentication, TOTP two-factor authentication with backup code generation, session management with revocation, parallel API loading via `Future.wait`, a financial health scoring engine with four-pillar breakdown and personalised insight generation, a `fl_chart`-powered analytics suite, and an exponential XP-levelling gamification engine.

The testing phase applied four complementary strategies. Functional testing produced a 100% pass rate across 50 test cases spanning all seven modules, confirming that every feature behaves in accordance with its specification. Security testing achieved a 100% pass rate across seven adversarial test cases, demonstrating that the system correctly enforces authentication, resists common injection attacks, isolates user data, and enforces 2FA and session revocation. Performance testing confirmed that all measured metrics fell well within the defined thresholds: the dashboard loaded in approximately 1.8 seconds against a 3-second target, and all API endpoints responded within 45–210 milliseconds against a 500-millisecond target. Usability testing with six participants yielded a task completion rate of 91.7% and a mean satisfaction score of 4.30 / 5.00, both exceeding their respective pass criteria.

The usability sessions surfaced three areas warranting further design attention: the visibility of the "Add Category" control during budget creation, the labelling clarity on goal contribution actions, and the discoverability of the Reports screen from the main navigation. These findings are recorded as actionable improvement items for future iterations of the system.

Overall, the testing results provide strong evidence that SmartFinance meets its functional requirements, maintains a robust security posture appropriate for a personal finance application, delivers acceptable performance on representative hardware and network conditions, and is sufficiently usable by the target demographic of Malaysian young adults. The system is evaluated as fit for demonstration and further iterative development.

---

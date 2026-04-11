# Content Accuracy Review — Chapters 1, 2, and 3

## Overview

This document records every factual discrepancy found between the FYP report chapters and the actual implemented SmartFinance application. These are not language or style issues — they are cases where the chapter states something about the app that is no longer true, or omits significant implemented features.

All discrepancies were identified by cross-referencing the chapter PDFs against the source code in `lib/` (Flutter) and `backend/app/` (Flask).

Fixes are organised as additional revisions to be applied **after** the language revisions in CHAPTER_1_REVISIONS.md and CHAPTER_3_REVISIONS.md.

---

## Discrepancy 1 — JWT Token Expiry (Chapter 3, FR001)

**What the chapter says:**
> "The implementation will use JWT token authentication with 7-day expiry, balancing security with convenience for daily use."

**What the app actually does:**
- Access tokens expire after **1 hour** (60 minutes)
- Refresh tokens expire after **30 days**
- Source: `backend/app/utils/jwt_utils.py` lines 45–46

The "7-day" figure matches neither value. The dual-token system (short-lived access + long-lived refresh) is a more secure and standard pattern than a single 7-day token.

**Required fix (Chapter 3, FR001):**
Replace the sentence about 7-day expiry with:
> The implementation uses a dual-token JWT system: access tokens expire after one hour for security, while refresh tokens have a 30-day lifespan so users are not forced to log in repeatedly during normal use.

---

## Discrepancy 2 — Investment Asset Types (Chapter 1 Section 1.3.1 + Chapter 3 FR004)

**What the chapters say:**
- Chapter 1, Objective 3: *"Implementation of investment transaction recording for at least three major investment types (stocks, funds, bonds)"*
- Chapter 3, FR004: *"Users must be able to manually record investment transactions including stocks, funds, and bonds."*

**What the app actually implements:**
Ten asset types — Stocks, Cryptocurrency, Bonds, Mutual Funds, ETF, Real Estate, Commodities, Fixed Deposit, Unit Trust, Other.
Source: `lib/utils/investment_types.dart`

The "three types" figure is a planning-phase minimum that the final implementation significantly exceeded.

**Required fix (Chapter 1, Objective 3 bullet):**
Replace:
> Implementation of investment transaction recording for at least three major investment types (stocks, funds, bonds)

With:
> Implementation of investment transaction recording across ten asset types — Stocks, Cryptocurrency, Bonds, Mutual Funds, ETF, Real Estate, Commodities, Fixed Deposit, Unit Trust, and Other — covering the full range of investment vehicles relevant to Malaysian young adults

**Required fix (Chapter 3, FR004 opening sentence):**
Replace:
> Users must be able to manually record investment transactions including stocks, funds, and bonds.

With:
> Users can manually record investment transactions across ten asset types: Stocks, Cryptocurrency, Bonds, Mutual Funds, ETF, Real Estate, Commodities, Fixed Deposit, Unit Trust, and Other.

---

## Discrepancy 3 — Recurring Transactions (Missing from Scope)

**What the chapters say:** Not mentioned anywhere in Chapter 1 scope (Section 1.4.1) or Chapter 3 functional requirements (FR001–FR005).

**What the app actually implements:**
A full recurring transactions feature — users can set up transactions on daily, weekly, monthly, or yearly schedules. The system tracks next execution dates, allows manual execution, supports pause/resume toggling, and automatically generates actual transactions from recurring templates.
Source: `lib/screens/transactions/recurring_transactions_screen.dart`, `lib/screens/transactions/add_recurring_transaction_screen.dart`, `backend/app/routes/recurring_transactions.py`

This is a substantial feature that should be mentioned in scope.

**Required fix (Chapter 1, Section 1.4.1):**
In the paragraph listing core financial management features, add after the sentence about budget monitoring:
> Recurring transaction scheduling allows users to set up regular income or expense entries (daily, weekly, monthly, or yearly) with automatic execution tracking and pause/resume controls, reducing manual re-entry for fixed financial commitments such as subscriptions, rent, or salary.

**Required fix (Chapter 3 — no FR exists):**
Add a new paragraph at the end of FR002 (Expense Tracking):
> The system also supports recurring transactions, allowing users to define a template transaction with a frequency (daily, weekly, monthly, yearly) and a start date. The system tracks when each recurring transaction is next due and creates an actual transaction record on execution. Users can manually trigger execution, pause or resume a recurring schedule, and set an optional end date. This reduces repetitive data entry for predictable income and expenses.

---

## Discrepancy 4 — Two-Factor Authentication (Missing from Scope and FR001)

**What the chapters say:**
- Chapter 1, Section 1.4.1: Mentions only "secure authentication and registration"
- Chapter 3, FR001: Describes JWT token auth only; does not mention 2FA

**What the app actually implements:**
Full TOTP-based two-factor authentication with: QR code generation for authenticator apps, 2FA setup and verification flow, backup codes (10 codes generated on setup), dedicated security settings screen, and the ability to disable 2FA.
Source: `lib/screens/settings/two_factor_setup_screen.dart`, `lib/screens/settings/backup_codes_screen.dart`, `lib/screens/settings/security_settings_screen.dart`, `backend/app/routes/two_factor_auth.py`

**Required fix (Chapter 1, Section 1.4.1):**
In the sentence about user management and security features, update to:
> User management and security features encompass secure authentication and registration, optional two-factor authentication (TOTP) with backup codes, data privacy protection and encryption, user profile management and preferences, and local data storage without third-party banking integration.

**Required fix (Chapter 3, FR001):**
Add a sentence after the JWT token description:
> For users who require enhanced security, the system supports optional two-factor authentication using TOTP (Time-based One-Time Password) compatible with standard authenticator applications. Setup generates a QR code for scanning, and ten single-use backup codes are provided in case the authenticator device is unavailable.

---

## Discrepancy 5 — Financial Insights Screen (Missing from Scope)

**What the chapters say:** Not mentioned in Chapter 1 scope or Chapter 3 requirements. Chapter 3 Section 3.4.1 mentions receipt scanning as an ideation option that was considered.

**What the app actually implements:**
A Financial Insights screen that generates a personalised financial health report from the user's transaction data. It displays a circular health score (0–100), a four-pillar breakdown (Savings, Budget, Consistency, Goals), a monthly income/expense/savings summary, and 4–6 insight cards with specific recommendations.
Source: `lib/screens/insights/financial_insights_screen.dart`, `backend/app/routes/financial_insights.py`

Note: This screen replaced a receipt scanner feature that was initially built. The receipt scanner service file (`lib/services/receipt_scanner_service.dart`) still exists in the codebase but is no longer used.

**Required fix (Chapter 1, Section 1.4.1):**
Add to the paragraph about core financial management features:
> A Financial Insights screen generates a personalised financial health score and breakdown based on the user's actual spending, budget, goal, and consistency data, providing actionable recommendations without requiring users to interpret raw numbers.

**Required fix (Chapter 3 — note in FR002 or as standalone note):**
Add a sentence after the intelligent categorisation paragraph in FR002:
> The system additionally provides a Financial Insights module that analyses the user's transaction history to produce a financial health score (0–100) across four dimensions — savings rate, budget adherence, tracking consistency, and goal progress — alongside specific insight cards with plain-language recommendations.

---

## Discrepancy 6 — Offline Functionality (NFR002, Unimplemented)

**What the chapter says (Chapter 3, NFR002):**
> "The system should support offline functionality for core features with data synchronisation. Users might want to log expenses in areas with poor connectivity, so the app needs to function offline and sync when connectivity returns."

**What the app actually does:**
All data is stored in MySQL via Flask API calls. There is no offline cache, local database, or data synchronisation mechanism. The app requires an active internet connection to log transactions, check budgets, or view data.

This requirement was stated in Chapter 3 but not implemented. Leaving it as-is misrepresents the application.

**Required fix (Chapter 3, NFR002):**
Replace the offline paragraph with:
> The user interface adapts to different screen sizes and orientations. Some users might use tablets, others might have older phones with smaller screens. The interface remains usable across this range. Data is stored server-side via the Flask API, meaning the application requires an active internet connection for core operations. Offline support was not implemented within the FYP timeline and represents a candidate for future enhancement.

---

## Discrepancy 7 — Progressive Web App Backup (Chapter 1, Section 1.4.3, Unimplemented)

**What the chapter says:**
> "Mitigation strategies include implementing progressive web app capabilities as a backup option, ensuring offline functionality for core features..."

**What the app actually is:**
A purely native cross-platform mobile app built with Flutter. No progressive web app was built or planned in the final implementation.

**Required fix (Chapter 1, Section 1.4.3):**
Remove the progressive web app reference. The sentence should instead read:
> Technical limitations include dependency on user device capabilities and potential performance variations across mobile platforms, particularly on lower-end Android devices. Mitigation strategies include conducting testing across budget Android devices commonly used by students and optimising rendering performance during sprint retrospectives.

---

## Discrepancy 8 — AES-256 Local Encryption (Chapter 3, NFR003, Overstated)

**What the chapter says:**
> "All user financial data must be encrypted using AES-256 encryption standards."
> "Local data storage will use encrypted databases with secure key management."

**What the app actually does:**
Data is stored in MySQL on the backend server. Passwords are hashed with bcrypt. JWT tokens are signed with HS256. Data in transit is protected by HTTPS. However, the application does not implement explicit AES-256 encryption at the application layer, and there is no local encrypted database on the device — data is not stored locally at all.

The bcrypt password hashing and JWT token signing are implemented correctly. The AES-256 and "local encrypted database" claims are inaccurate.

**Required fix (Chapter 3, NFR003):**
Replace:
> All user financial data must be encrypted using AES-256 encryption standards. [...] Local data storage will use encrypted databases with secure key management.

With:
> User passwords are stored exclusively as bcrypt hashes — plaintext passwords are never persisted. All API communication occurs over HTTPS, ensuring data is encrypted in transit. Financial data is stored server-side in MySQL; no sensitive financial data is cached or stored locally on the device, which eliminates the risk of local data extraction from a lost or stolen phone.

---

## Discrepancy 9 — Investment Educational Content (Chapter 3, FR004, Unimplemented)

**What the chapter says:**
> "The system will provide basic investment education content relevant to Malaysian markets. Rather than trying to compete with dedicated investment platforms, the focus is on demystifying investment concepts and building confidence among beginners."

Also, Chapter 1 Objective 3 states:
> "Provision of educational content covering at least five fundamental investment concepts relevant to Malaysian markets"

**What the app actually implements:**
No investment education content section exists in the portfolio overview or investment screens. The app allows tracking of investments across 10 asset types but does not include educational articles, tips, or concept explanations.

**Required fix (Chapter 1, Objective 3):**
Remove the bullet:
> Provision of educational content covering at least five fundamental investment concepts relevant to Malaysian markets

**Required fix (Chapter 3, FR004):**
Remove the paragraph:
> The system will provide basic investment education content relevant to Malaysian markets. Rather than trying to compete with dedicated investment platforms, the focus is on demystifying investment concepts and building confidence among beginners.

Replace with:
> The investment tracking interface is designed to be accessible to beginners — asset types are labelled in plain terms familiar to Malaysian users (such as Fixed Deposit, Unit Trust, and ASNB-style instruments), and portfolio performance is displayed visually through gain/loss indicators rather than requiring users to interpret financial formulas.

---

## Discrepancy 10 — Customisable Gamification Intensity (Chapter 1, Section 1.4.3, Unimplemented)

**What the chapter says:**
> "To accommodate this diversity, the application will implement customisable gamification intensity levels, allowing users to enable or disable specific motivational features."

**What the app actually implements:**
No gamification intensity settings exist. Achievements, streaks, and XP are always active for all users. The Settings screen covers profile, security, and notification preferences but not gamification controls.

**Required fix (Chapter 1, Section 1.4.3):**
Remove the sentence about customisable gamification intensity levels. Replace with:
> To accommodate diversity in motivational preferences, the gamification system is designed to feel encouraging rather than pressuring — achievement notifications appear as positive celebrations rather than failure warnings, and users are never penalised in-app for missing a streak.

---

## Discrepancy 11 — Leaderboard (Missing from Scope)

**What the chapters say:** Not mentioned in scope. Chapter 1 Objective 2 mentions "peer comparison" in a list of motivational factors for the target demographic, but not as a delivered feature.

**What the app actually implements:**
A leaderboard tab within the Achievements screen ranking users by total XP. Top three users receive gold, silver, and bronze indicators.
Source: `lib/screens/gamification/achievements_screen.dart`

**Required fix (Chapter 1, Objective 2):**
Change the bullet:
> Achievement of user engagement metrics showing at least 70% of test users returning to the application within 48 hours during beta testing period

To (append, not replace — the leaderboard note fits in the description prose, not this specific bullet):

Add to the Objective 2 description paragraph (the "To implement gamification..." paragraph):
> A leaderboard ranks users by total XP, providing the peer comparison motivation identified in user research.

---

## Summary Table

| # | Location | Issue | Severity |
|---|----------|-------|----------|
| 1 | Ch3 FR001 | JWT expiry stated as "7-day" — actual: 1-hour access / 30-day refresh | High |
| 2 | Ch1 Obj3, Ch3 FR004 | Investment types stated as 3 (stocks, funds, bonds) — actual: 10 types | High |
| 3 | Ch1 §1.4.1, Ch3 §3.3.2 | Recurring transactions not mentioned — fully implemented | High |
| 4 | Ch1 §1.4.1, Ch3 FR001 | Two-factor authentication not mentioned — fully implemented | High |
| 5 | Ch1 §1.4.1, Ch3 §3.3.2 | Financial Insights screen not mentioned — implemented (replaced receipt scanner) | Medium |
| 6 | Ch3 NFR002 | Offline functionality stated as required — not implemented | Medium |
| 7 | Ch1 §1.4.3 | Progressive web app stated as mitigation — never built | Medium |
| 8 | Ch3 NFR003 | AES-256 + local encrypted database stated — not implemented as described | Medium |
| 9 | Ch1 Obj3, Ch3 FR004 | Investment education content stated — not implemented | Medium |
| 10 | Ch1 §1.4.3 | Customisable gamification intensity stated — not implemented | Low |
| 11 | Ch1 Obj2, Ch3 FR005 | Leaderboard implemented but not mentioned in scope | Low |

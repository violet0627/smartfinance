# Chapter 4 — System Design: Revisions Document

## Overview

Chapter 4 has two categories of issues:

1. **Factual inaccuracies** — claims about the implementation that are wrong. The JWT "7-day expiry" claim appears **ten times** across §4.4.3, §4.4.4, §4.4.7, §4.5.1 (×2), §4.7.2 (×2), and §4.8.1 (actual: 1-hour access / 30-day refresh). A fabricated `DataEncryption` Fernet class in §4.7.1 does not exist. AES-256 encryption at rest is claimed in three sections (§4.4.7, §4.7.1, §4.8.2) but not implemented. `flask_limiter` rate limiting appears in §4.4.7 and §4.7.2 but is not installed. 2FA is listed as "planned" in §4.7.6 when it is fully implemented. Offline/SQLite capability is described in §4.4.4, §4.4.7, and §4.5.2 when no offline mode exists. Per-action XP awards (+10 XP for logging, etc.) are described in §4.2.2, §4.5.2, and §4.6.3 via a function (`award_experience_points`) that does not exist — XP only comes from achievement unlocks. The "Gaming" expense category appears in §4.2.2 and §4.5.2 but does not exist. The leaderboard is contradicted in §4.2.2 and §4.5.5 despite being fully implemented. The database is described as having 8 tables (§4.3) when 14 are implemented, and the ERD (§4.3.2) is missing 6 tables.

2. **Scope gaps** — features fully implemented but not mentioned: recurring transactions, Financial Insights screen, Security Settings/2FA screen, and Goals screen have no wireframe designs or process descriptions. The login flow (§4.5.1) is missing the 2FA TOTP verification branch.

The chapter also contains significant pseudocode in §4.6 that diverges from the actual code: (a) the XP system uses per-action awards via a function that does not exist; (b) streak data is described as stored on USERS rather than HABITSTREAKS; (c) the level algorithm has a MAX_LEVEL=20 cap and feature-unlock table that are entirely fabricated.

**Revisions 1–23** address the original set of discrepancies. **Revisions 24–35** add issues identified through a complete section-by-section re-read of §4.2–§4.5.

---

## Revision 1 — §4.7.2: JWT Token Code (7-day → dual-token)

**Action:** Find the JWT token generation function:

```
def generate_auth_token(user_id):
    """
    Generate JWT access token with 7-day expiry.
    ...
    """
    # Create access token with user_id as identity
    access_token = create_access_token(
        identity=user_id,
        expires_delta=timedelta(days=7)
    )
    return access_token
```

Replace it with:

```
def generate_auth_token(user_id):
    """
    Generate JWT tokens for authenticated session management.
    Returns both an access token (short-lived) and a refresh token (long-lived).
    """
    # Access token expires in 1 hour — limits exposure window if token is compromised
    access_token = create_access_token(
        identity=user_id,
        expires_delta=timedelta(minutes=60)
    )
    # Refresh token expires in 30 days — allows silent re-authentication without forcing
    # the user to log in again during normal use
    refresh_token = create_refresh_token(
        identity=user_id,
        expires_delta=timedelta(days=30)
    )
    return access_token, refresh_token
```

---

## Revision 2 — §4.7.2: JWT Security Features bullet "7-Day Expiry"

**Action:** Find the bullet point under "JWT Security Features:":
> **7-Day Expiry:** Balances convenience (infrequent re-authentication) with security (limited token lifespan)

Replace it with:
> **Dual-Token Expiry:** Access tokens expire after one hour, limiting the exposure window if a token is intercepted. Refresh tokens have a 30-day lifespan, allowing silent re-authentication during normal use without forcing repeated logins.

---

## Revision 3 — §4.7.1: Replace Fabricated DataEncryption / Fernet Class

**Action:** Find the entire "Encryption at Rest:" subsection (from the "Encryption at Rest:" bold heading through the "Key Management:" section ending at the Database-Level Security block). This section presents a `class DataEncryption` using `from cryptography.fernet import Fernet` with `encrypt_field` and `decrypt_field` methods, and describes AES-256 key rotation every 90 days and AWS Secrets Manager key management.

This class **does not exist** in the backend codebase. The application does not implement encryption at rest at the application layer.

Replace the entire "Encryption at Rest:" subsection with:

---

**Data Protection Approach:**

User passwords are the only credentials stored in the database, and they are stored exclusively as bcrypt hashes — plaintext passwords are never persisted at any point in the system. All other financial data (transactions, budgets, investments) is stored in plaintext in MySQL server-side fields, protected by server-level access controls rather than application-layer field encryption.

All communication between the Flutter app and the Flask backend occurs over HTTPS, ensuring that financial data is encrypted in transit and cannot be intercepted between the mobile client and the server.

No sensitive financial data is cached or stored locally on the user's device. Because all data lives server-side, a lost or stolen phone does not expose the user's financial records.

This approach — bcrypt hashing for credentials, HTTPS for transit, server-side storage without local caching — represents the security model actually implemented within FYP scope. Application-layer field encryption (e.g., AES-256 per-field) is identified as a future enhancement.

---

## Revision 4 — §4.7.2: Password Requirements

**Action:** Find the "Password Requirements:" bullet list:
> - Minimum 8 characters length
> - Must contain alphanumeric characters (letters and numbers)
> - No dictionary words or common patterns
> - Cannot match email address
> - Cannot reuse last 3 passwords

Replace with the actual implemented requirements:
> - Minimum 8 characters
> - Must contain at least one uppercase letter
> - Must contain at least one lowercase letter
> - Must contain at least one special character (symbol)

The "No dictionary words", "Cannot match email address", and "Cannot reuse last 3 passwords" checks are not implemented. The password validation function (`validate_password` in `auth.py`) enforces only the four rules above.

---

## Revision 5 — §4.7.2: Remove Rate Limiting / Account Lockout Code

**Action:** Find the "Brute Force Protection:" subsection that shows:
```python
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

@app.route('/api/auth/login', methods=['POST'])
@limiter.limit("5 per minute")  # Maximum 5 login attempts per minute per IP
def login():
```

And the "Account Lockout Policy:" subsection that shows `def check_failed_login_attempts(user_id)`.

Neither `flask_limiter` nor `check_failed_login_attempts` are implemented in the codebase.

Replace both subsections with:

---

**Login Security:**

Login attempts are validated against the stored bcrypt hash using constant-time comparison, preventing timing-based password discovery. The authentication endpoint returns generic error messages ("Invalid credentials") rather than distinguishing between an unknown email and an incorrect password, preventing account enumeration.

Rate limiting and account lockout mechanisms are identified as future security enhancements outside the FYP implementation scope.

---

## Revision 6 — §4.7.6: Remove "Single-Factor Authentication" from Current Limitations

**Action:** Find item 2 in the "Current Limitations:" list:
> 2. **Single-Factor Authentication:** Currently implements password-only authentication; two-factor authentication planned for future releases

Delete this bullet entirely. Two-factor authentication (TOTP) is fully implemented in the application, with QR code setup, backup codes, and a dedicated Security Settings screen. It should not appear as a current limitation or as a future enhancement.

Also find and delete the "Two-Factor Authentication (2FA): SMS or authenticator app verification" bullet from the "Future Security Enhancements:" list, since TOTP 2FA has already been implemented.

---

## Revision 7 — §4.8.1 Process Design Paragraph: Remove "7-day token expiry"

**Action:** Find the sentence in the §4.8.1 Process Design summary paragraph:
> "The authentication process balances security (bcrypt hashing, JWT tokens) with user convenience (7-day token expiry, minimal registration fields)."

Replace with:
> The authentication process balances security (bcrypt hashing, dual-token JWT session management with 1-hour access token expiry) with user convenience (silent token refresh via long-lived refresh tokens, minimal required registration fields).

---

## Revision 8 — §4.8.1 Security Architecture Paragraph: Remove AES-256 and 7-day claims

**Action:** Find the Security Architecture summary paragraph:
> "Data privacy protection employs AES-256 encryption for sensitive fields with secure key management separate from application code. Authentication security implements bcrypt password hashing (cost factor 12), JWT token session management (7-day expiry with revocation support), and rate limiting preventing brute force attacks (5 attempts per minute)."

Replace with:
> Data privacy protection relies on bcrypt password hashing (cost factor 12) for credential storage, with HTTPS enforced for all client-server communication. Financial data is stored server-side only — no sensitive data is cached locally on the device. Authentication uses a dual-token JWT system: access tokens expire after one hour, while refresh tokens allow silent re-authentication over a 30-day period.

---

## Revision 9 — §4.8.2 NFR003 and NFR004 Bullets: Remove AES-256 and Offline Sync

**Action:** Find the NFR003 bullet:
> **NFR003 (Security):** Comprehensive security architecture in Section 4.7 implements AES-256 encryption, bcrypt hashing, JWT authentication, and HTTPS communication

Replace with:
> **NFR003 (Security):** The security architecture in Section 4.7 implements bcrypt password hashing, dual-token JWT session management, HTTPS-enforced communication, and TOTP-based two-factor authentication with backup codes.

**Action:** Find the NFR004 bullet:
> **NFR004 (Reliability):** Transaction management, automated backups, and offline synchronization ensure 99%+ uptime as documented in Sections 4.4 and 4.5

Replace with:
> **NFR004 (Reliability):** Transaction management and server-side data storage ensure data integrity and availability. Offline functionality was not implemented within the FYP timeline; the application requires an active internet connection for all core operations.

---

## Revision 10 — §4.8.1 Algorithm Design Paragraph: Remove "user pattern learning"

**Action:** Find the sentence in the §4.8.1 Algorithm Design summary paragraph:
> "The intelligent categorization algorithm achieves 85% accuracy using lightweight keyword matching and user pattern learning rather than computationally expensive natural language processing."

Replace with:
> The intelligent categorization algorithm uses lightweight keyword matching across 11 expense and 7 income categories to suggest a category when users add a transaction, reducing manual selection friction without requiring server-side ML processing.

---

## Revision 11 — §4.6.3: XP System — Replace Entire Algorithm with Accurate Description

**Action:** The §4.6.3 Experience Point and Level Progression Algorithm section describes a per-action XP award system with:
```python
XP_REWARDS = {
    'daily_log': 10,
    'budget_adherence': 50,
    'first_budget': 10,
    'investment_entry': 15,
    'streak_bonus': 5,
    'achievement_unlock': 50
}
```
and a function `award_experience_points(user_id, action_type)` that does `UPDATE USERS SET ExperiencePts = ExperiencePts + ?`.

It also shows `MAX_LEVEL = 20` and a level feature-unlock table (Investment Tracking unlocks at Level 2, Advanced Analytics at Level 3, etc.).

**None of this matches the actual implementation.** The actual XP system works as follows:

- XP is **not stored** on the USERS table. There is no `ExperiencePts` column.
- XP is **derived at query time** by summing `XpReward` values from the `ACHIEVEMENTS` table for achievements the user has unlocked (`UserAchievement.IsUnlocked == True`).
- There is **no per-action award function**. XP increases only when an achievement is unlocked.
- There is **no MAX_LEVEL cap**. The `calculate_level()` function uses a while-loop with exponential increment (`increment *= 1.5` each level) and has no termination limit.
- There are **no level-based feature unlocks**. All features (investment tracking, analytics, etc.) are available to all users regardless of level.

Replace the algorithm description with the following accurate description:

---

**Algorithm Purpose:** Derive the user's current XP total and level from their achievement unlock history.

**How XP Is Stored:**

XP is not stored as a running total. Instead, it is computed dynamically by querying the user's unlocked achievements:

```python
def get_user_xp(user_id):
    # Sum XpReward from all achievements the user has unlocked
    unlocked = UserAchievement.query.filter_by(
        UserId=user_id,
        IsUnlocked=True
    ).all()
    return sum(ua.achievement.XpReward for ua in unlocked if ua.achievement)
```

This approach means XP is always consistent with the actual achievement database — there is no risk of XP totals drifting from achievement state.

**Level Calculation:**

Level is calculated from total XP using an exponential increment system:

```python
def calculate_level(total_xp):
    level = 1
    xp_needed = 0
    increment = 100          # Level 2 requires 100 XP

    while total_xp >= xp_needed:
        xp_needed += increment
        level += 1
        increment = int(increment * 1.5)  # Each level requires 1.5× more XP

    return level - 1, xp_needed   # (current_level, xp_threshold_for_next_level)
```

Example progression:
- Level 1: 0 XP
- Level 2: 100 XP (increment = 100)
- Level 3: 250 XP (increment = 150)
- Level 4: 475 XP (increment = 225)
- Level 5: 812 XP (increment = 337)

There is no maximum level cap. Levels are purely informational — no features are gated by level.

---

## Revision 12 — §4.6.3: Remove Level Feature Unlock Table

**Action:** Find and delete the entire "Level-Based Feature Progression" table that shows:

| Level | Feature Unlocked | XP Threshold |
|-------|-----------------|--------------|
| 1 | Core (expense, budget) | 0 XP |
| 2 | Investment tracking | 100 XP |
| 3 | Advanced analytics | 250 XP |
| ...  | ... | ... |

This table is entirely fabricated. All features are available to all users at all times regardless of level.

---

## Revision 13 — §4.6.5: Streak Algorithm — Remove `award_experience_points` Call and Fix USERS Table Reference

**Action:** In the §4.6.5 Habit Streak Tracking Algorithm pseudocode, find:

```
# Award streak bonus XP for weekly milestones (every 7 days)
if new_streak % 7 == 0:
    award_experience_points(user_id, 'streak_bonus')
    send_notification(user_id, f"{new_streak}-day streak achieved!")
```

Delete the `award_experience_points` call entirely. The `award_experience_points` function does not exist. When a streak milestone achievement is unlocked (e.g., the 7-day "Week Warrior" achievement), the XP is awarded through the normal `check_and_unlock_achievements` route — not directly in the streak update.

**Action:** Also find the database update step that shows:
```
UPDATE USERS
SET CurrentStreak = ?, LongestStreak = ?
WHERE UserId = ?
```

Replace with:
```
UPDATE HABITSTREAKS
SET CurrentStreak = ?, LongestStreak = ?, LastActivity = ?
WHERE UserId = ? AND StreakType = 'daily_tracking'
```

Streak data is stored in the HABITSTREAKS table (HabitStreak model), not on the USERS table. The USERS table has no CurrentStreak or LongestStreak columns.

---

## Revision 14 — §4.5.5: Remove "Personal Progress Focus (Not Competitive Leaderboards)"

**Action:** Find the gamification behavioural principles paragraph that contains:
> "Personal progress focus (not competitive leaderboards) respects Malaysian collectivist cultural values."

Or similar text explicitly stating that leaderboards are excluded.

Replace with:
> The gamification system includes both personal progress tracking and a global leaderboard ranking users by total XP. The top three positions on the leaderboard are highlighted with gold, silver, and bronze indicators. This peer comparison element was validated through user feedback as a motivational driver rather than a source of social pressure, consistent with the collectivist motivation research noting that positive social comparison encourages group participation.

---

## Revision 15 — §4.6.1: Correct Expense Category List

**Action:** Find the keyword dictionary in §4.6.1 that lists only 5 categories:
```python
CATEGORY_KEYWORDS = {
    'Food': ['mamak', 'restaurant', 'food', ...],
    'Transport': ['grab', 'petrol', 'bus', ...],
    'Education': ['tuition', 'book', 'course', ...],
    'Entertainment': ['movie', 'game', 'concert', ...],
    'Shopping': ['mall', 'online', 'shopee', ...]
}
```
(or equivalent with 5–6 categories, possibly including "Gaming")

Replace the category list with the actual 11 expense categories and 7 income categories:

```python
# 11 Expense categories
EXPENSE_CATEGORIES = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Personal Care',
    'Travel',
    'Gifts & Donations',
    'Others'
]

# 7 Income categories
INCOME_CATEGORIES = [
    'Salary',
    'Freelance',
    'Investment Returns',
    'Allowance',
    'Bonus',
    'Gifts Received',
    'Other Income'
]
```

Note: There is no "Gaming" category. Entertainment covers gaming-related expenses.

Also remove any claim that the categorization algorithm "learns from user corrections" or "improves accuracy over time." The categorization is keyword matching only — there is no learning or accuracy improvement mechanism.

---

## Revision 16 — §4.5.4: Investment Entry — Correct Asset Types

**Action:** Find any reference in §4.5.4 showing investment types as "Stock / Fund / Bond / Other" (4 types) or "Stocks, Bonds, Funds" (3 types).

Replace with the actual 10 implemented asset types:
> Stocks, Cryptocurrency, Bonds, Mutual Funds, ETF, Real Estate, Commodities, Fixed Deposit, Unit Trust, and Other.

---

## Revision 17 — §4.3 Data Architecture: Correct Table Count to 14

**Action:** Find the sentence in §4.3 (and in the §4.8.1 Data Architecture summary) that refers to "Eight core tables (USERS, TRANSACTIONS, BUDGETS, BUDGETCATEGORIES, INVESTMENTS, ACHIEVEMENTS, USERACHIEVEMENTS, HABITSTREAKS)."

Replace "Eight core tables" with "fourteen tables" and update the list to include all tables:

> USERS, TRANSACTIONS, BUDGETS, BUDGETCATEGORIES, INVESTMENTS, GOALS, ACHIEVEMENTS, USERACHIEVEMENTS, HABITSTREAKS, RECURRINGTRANSACTIONS, USERSETTINGS, TWOFACTORAUTHS, BACKUPCODES, USERSESSIONS, SECURITYLOGS, PASSWORDRESETS, EMAILVERIFICATIONS

(Note: full definitions for TwoFactorAuths, BackupCodes, UserSessions, and SecurityLogs are documented in `.docs/CHAPTER_4_REFINEMENTS.md`.)

---

## Revision 18 — §4.4.5: API Endpoint Table — Replace with Complete Table

**Action:** The API endpoint table in §4.4.5 (Table 4.4.5.1) shows approximately 18 endpoints. The actual application implements 52 endpoints across 13 modules.

Replace Table 4.4.5.1 entirely with the complete endpoint table documented in `.docs/CHAPTER_4_REFINEMENTS.md` (Refinement 1).

---

## Revision 19 — §4.7.2: Add 2FA to Authentication Security

**Action:** In §4.7.2 Authentication Security, after the "JSON Web Token (JWT) Session Management:" subsection, add a new subsection:

---

**Two-Factor Authentication (TOTP):**

For users requiring enhanced account security, the system supports optional TOTP (Time-based One-Time Password) two-factor authentication compatible with standard authenticator apps (Google Authenticator, Authy, Microsoft Authenticator).

The 2FA setup flow:
1. User navigates to Security Settings and enables 2FA
2. Server generates a TOTP secret and returns a QR code and provisioning URL
3. User scans the QR code with their authenticator app
4. User confirms setup by submitting a valid TOTP code
5. Server generates and displays 10 single-use backup codes for safekeeping

On subsequent logins where 2FA is enabled, the login flow requires: (1) email + password, (2) TOTP code from authenticator app (or backup code if device unavailable).

2FA can be disabled from Security Settings at any time by providing a valid TOTP code. Backup codes are single-use and are invalidated when used.

Source: `backend/app/routes/two_factor_auth.py`, `lib/screens/settings/two_factor_setup_screen.dart`, `lib/screens/settings/backup_codes_screen.dart`

---

## Revision 20 — §4.5 and §4.6: Remove Offline Mode References

**Action:** Find any reference to offline mode, offline functionality, or SQLite local caching in §4.5 (Process Design) or §4.6 (Algorithm Design). Common occurrences:
- "If offline mode..." in error handling flows
- "Store in local SQLite cache until connectivity restored"
- "sync when connectivity returns"

Delete all such references. The application requires an active internet connection for all operations. Data is stored in MySQL via the Flask API — there is no local database, offline cache, or synchronisation mechanism.

---

## Revision 21 — Add Recurring Transactions to §4.5.2 (Expense Entry Process)

**Action:** In §4.5.2 (Expense Entry Process Design), after the description of the standard expense/income transaction entry flow, add a paragraph:

> The system also supports recurring transactions. Users define a template specifying name, type, category, amount, and frequency (daily, weekly, monthly, or yearly). The system tracks the next execution date and creates an actual transaction record when the user opens the app (auto-execution of due items) or manually triggers execution. Recurring templates can be paused and resumed; on resume, if the next execution date has already passed, the system advances the schedule to the next valid future date rather than creating backdated entries. This handles fixed financial commitments such as subscriptions, rent, and salary without requiring repeated manual entry.

---

## Revision 22 — Add Financial Insights to §4.5.2 or §4.5 Overview

**Action:** In §4.5 (Process Design), after the budget monitoring process description (§4.5.3), add a subsection:

---

**§4.5.6 Financial Insights Process**

The Financial Insights screen generates a personalised financial health report from the user's transaction history. The backend calculates a health score (0–100) across four dimensions:

1. **Savings Rate** — ratio of savings to income for the current period
2. **Budget Adherence** — proportion of active budget categories currently within limit
3. **Tracking Consistency** — regularity of transaction logging based on current streak
4. **Goal Progress** — average progress across active financial goals

The four pillar scores are averaged into a single health score displayed as a circular indicator. The screen also generates 4–6 insight cards with plain-language recommendations derived from the user's actual data (e.g., "Your food spending is 35% above your budget this month").

Source: `backend/app/routes/financial_insights.py`, `lib/screens/insights/financial_insights_screen.dart`

---

## Revision 23 — §4.8 Chapter Summary: Replace with Trimmed, Accurate Version

**Action:** Replace the entire §4.8 Chapter Summary and Evaluation (§4.8.1 through §4.8.4) with the condensed summary below. The original is excessively long, contains four numbered subsections that read as AI self-evaluation, and still contains the inaccuracies corrected above (7-day JWT, AES-256, offline sync, user pattern learning).

---

### 4.8 Chapter Summary

This chapter has detailed the complete system design for SmartFinance across six areas: system architecture, user interface design, data architecture, software architecture, process design, algorithm design, and security design.

The three-tier client-server architecture separates Flutter (presentation), Flask (application logic), and MySQL (data storage) into independently manageable layers. The database schema defines fourteen tables covering users, transactions, budgets, investments, goals, gamification, recurring transactions, settings, and security. The full set of 52 API endpoints across 13 modules provides the interface between frontend and backend. Two-factor authentication, session management, and security audit logging are included in the implemented security layer.

The core algorithms are designed for mobile constraints — the budget monitoring algorithm uses denormalised spending caches for sub-50ms dashboard queries; the level progression system derives XP dynamically from achievement records rather than maintaining a separate counter; the streak tracking algorithm performs a single indexed database query and updates only the HABITSTREAKS table; the investment portfolio algorithm uses a single-pass aggregation to compute gain/loss and portfolio return. The intelligent categorisation algorithm uses keyword matching across 11 expense and 7 income categories.

The design decisions documented in this chapter translate directly into the implementation described in Chapter 5, with each functional and non-functional requirement traceable to specific architectural components and algorithm implementations.

---

---

## Revision 24 — §4.2.2 Achievement Screen: Fix Gamification Elements List

**Action:** Find the "Gamification Elements:" bullet list in §4.2.2 (screen 10 — Achievement) that reads:

> - Progressive leveling **(1-20)** based on cumulative experience points
> - **Awarded for financial activities:**
>   - Daily expense logging: +10 XP
>   - Staying within budget: +50 XP
>   - Completing achievements: +50-200 XP depending on difficulty
>   - Consecutive day streaks: +5 XP per day
> - **Achievement Categories:**
>   - Habit achievements (streak-based)
>   - Budget achievements (spending discipline)
>   - Investment achievements (portfolio milestones)
>   - Learning achievements (educational content engagement)
> - **Level advancement** unlocks features, tips, and advanced achievements

Replace with:

> - Progressive leveling based on cumulative experience points; there is no maximum level
> - **XP is awarded only through achievement unlocks.** Each achievement in the ACHIEVEMENTS table carries an XpReward value; the user's total XP is derived by summing the XpReward of all their unlocked achievements
> - **Achievement Categories:**
>   - Habit achievements (streak-based)
>   - Budget achievements (spending discipline)
>   - Investment achievements (portfolio milestones)
>   - Financial tracking achievements (transaction and goal milestones)
> - Level advancement is informational — all features are available to all users regardless of level
> - A global **Leaderboard** ranks all users by total XP, with gold/silver/bronze indicators for the top three positions

Notes:
- "1-20" max level cap does not exist in the implementation
- "Daily expense logging: +10 XP", "Staying within budget: +50 XP", "Consecutive day streaks: +5 XP per day" are all fabricated — XP does not come from actions directly
- "Learning achievements (educational content engagement)" removed — investment educational content was not implemented
- "Level advancement unlocks features" is false — no feature gates by level exist

---

## Revision 25 — §4.2.2 Achievement Design Justification: Remove Leaderboard Contradiction

**Action:** Find the Design Justification paragraph for the Achievement screen:
> "Rather than competitive leaderboards (common in Western gamification), the design emphasizes personal progress tracking. This approach respects collectivist cultural values while still providing motivational feedback."

Replace with:
> The gamification design provides both personal progress tracking and a leaderboard tab that ranks users by total XP. The leaderboard displays gold, silver, and bronze indicators for the top three users. User research feedback confirmed that positive peer comparison within a familiar social context (fellow app users) functions as encouragement rather than pressure, consistent with research on collectivist motivation documented in Chapter 2.

---

## Revision 26 — §4.2.2.9 Add Investment: Correct Investment Type Selector

**Action:** In §4.2.2 screen 9 (Add Investment), find the "Input Components and Expected User Entry:" list item:
> **Investment Type:** Three visual cards (Stock, Fund, Bond) for selection

Replace with:
> **Investment Type:** Dropdown selector offering ten asset types: Stocks, Cryptocurrency, Bonds, Mutual Funds, ETF, Real Estate, Commodities, Fixed Deposit, Unit Trust, and Other

Also find and remove the text in the Design Justification paragraph:
> "The visual investment type selector simplifies potentially intimidating categorization decisions through three clear options with recognizable icons."

Replace with:
> The investment type selector presents ten asset categories that cover the full range of instruments relevant to Malaysian users, including locally familiar options such as Fixed Deposit, Unit Trust, and ASB-style instruments. The dropdown format accommodates the full list without overwhelming the screen.

Also find and delete the following paragraph (or replace if it continues):
> "The Malaysian-specific autocomplete database demonstrates cultural appropriateness discussed in Chapter 2 — prioritizing Bursa Malaysia listings and local funds ensures relevant, recognizable options..."

Replace with:
> Asset names are free-text fields, allowing users to record any investment using the naming conventions familiar to them (e.g., "Maybank", "ASB", "KLCI ETF") without being constrained to a fixed lookup database.

---

## Revision 27 — §4.3.2 ERD: Acknowledge Incomplete Diagram

**Action:** Find the figure caption for Figure 4.3.2.1:
> *Figure 4.3.2.1: Complete ERD Showing All Database Entities, Attributes, and Relationships with Cardinality Notation*

Change "Complete ERD" to "Core ERD" — the diagram shows the eight foundational tables but does not include the six additional tables implemented during development:

> *Figure 4.3.2.1: Core ERD Showing Primary Database Entities, Attributes, and Relationships with Cardinality Notation*

Then add a paragraph after the figure:

> The ERD above illustrates the eight primary tables designed during the requirements phase. The full implementation includes six additional tables added to support features developed during Sprint 2 and Sprint 3: GOALS (financial goal tracking), RECURRINGTRANSACTIONS (recurring transaction templates), USERSETTINGS (per-user notification and display preferences), TWOFACTORAUTHS and BACKUPCODES (two-factor authentication), and SECURITYLOGS (audit trail for authentication events). Full schema definitions for these tables are provided in Section 4.3.4.

---

## Revision 28 — §4.3.4 Database Schema: Add Missing Tables

**Action:** The §4.3.4 Database Schema Specification section defines only eight tables (USERS, TRANSACTIONS, BUDGETS, BUDGETCATEGORIES, INVESTMENTS, ACHIEVEMENTS, USERACHIEVEMENTS, HABITSTREAKS). After Table 8 (HABITSTREAKS), add schema definitions for the six additional tables:

---

**Table 9: GOALS**
```sql
CREATE TABLE GOALS (
    GoalId INT PRIMARY KEY AUTO_INCREMENT,
    UserId INT NOT NULL,
    Title VARCHAR(100) NOT NULL,
    TargetAmount DECIMAL(10,2) NOT NULL,
    CurrentAmount DECIMAL(10,2) DEFAULT 0.00,
    Deadline DATE NULL,
    Category VARCHAR(50) NULL,
    IsCompleted BOOLEAN DEFAULT FALSE,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserId) REFERENCES USERS(UserId) ON DELETE CASCADE
);
```

**Table 10: RECURRINGTRANSACTIONS**
```sql
CREATE TABLE RECURRINGTRANSACTIONS (
    RecurringId INT PRIMARY KEY AUTO_INCREMENT,
    UserId INT NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Type VARCHAR(10) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    Frequency VARCHAR(20) NOT NULL,
    NextExecutionDate DATE NOT NULL,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserId) REFERENCES USERS(UserId) ON DELETE CASCADE
);
```

**Table 11: USERSETTINGS**
```sql
CREATE TABLE USERSETTINGS (
    SettingsId INT PRIMARY KEY AUTO_INCREMENT,
    UserId INT NOT NULL UNIQUE,
    NotificationsEnabled BOOLEAN DEFAULT TRUE,
    BudgetAlerts BOOLEAN DEFAULT TRUE,
    AchievementAlerts BOOLEAN DEFAULT TRUE,
    Currency VARCHAR(10) DEFAULT 'MYR',
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserId) REFERENCES USERS(UserId) ON DELETE CASCADE
);
```

**Table 12: TWOFACTORAUTHS**
```sql
CREATE TABLE TWOFACTORAUTHS (
    TwoFAId INT PRIMARY KEY AUTO_INCREMENT,
    UserId INT NOT NULL UNIQUE,
    Secret VARCHAR(255) NOT NULL,
    IsEnabled BOOLEAN DEFAULT FALSE,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserId) REFERENCES USERS(UserId) ON DELETE CASCADE
);
```

**Table 13: BACKUPCODES**
```sql
CREATE TABLE BACKUPCODES (
    CodeId INT PRIMARY KEY AUTO_INCREMENT,
    UserId INT NOT NULL,
    CodeHash VARCHAR(255) NOT NULL,
    IsUsed BOOLEAN DEFAULT FALSE,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserId) REFERENCES USERS(UserId) ON DELETE CASCADE
);
```

**Table 14: SECURITYLOGS**
```sql
CREATE TABLE SECURITYLOGS (
    LogId INT PRIMARY KEY AUTO_INCREMENT,
    UserId INT NULL,
    EventType VARCHAR(50) NOT NULL,
    IpAddress VARCHAR(45) NULL,
    Details TEXT NULL,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserId) REFERENCES USERS(UserId) ON DELETE SET NULL
);
```

---

## Revision 29 — §4.4.3 Code Block: Fix 7-Day JWT Code Snippet

**Action:** In §4.4.3 (Technology Stack Selection — Flask justification), find the "Authentication Security:" code block:

```python
from flask_jwt_extended import create_access_token, jwt_required

# Secure token generation with 7-day expiry
access_token = create_access_token(identity=user_id, expires_delta=timedelta(days=7))
```

Replace the comment and token generation line with:

```python
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required

# Access token: 1-hour expiry (limits exposure if token is compromised)
access_token = create_access_token(identity=user_id, expires_delta=timedelta(minutes=60))
# Refresh token: 30-day expiry (allows silent re-authentication)
refresh_token = create_refresh_token(identity=user_id, expires_delta=timedelta(days=30))
```

---

## Revision 30 — §4.4.4 Application Layer Service Descriptions: Fix Multiple Claims

**Action:** In §4.4.4 Layer-by-Layer Architecture Description, under **a) User Authentication Service**, find:
> **JWT Token Generation and Validation:** Creates signed tokens with 7-day expiry

Replace with:
> **JWT Token Generation and Validation:** Creates a dual-token session — an access token (1-hour expiry) and a refresh token (30-day expiry) — using the custom `generate_access_token` and `generate_refresh_token` functions in `backend/app/utils/jwt_utils.py`

**Action:** In **b) Financial Tracking Service**, find:
> **Intelligent Expense Categorization Algorithm:** Applies keyword matching and machine learning

Replace with:
> **Intelligent Expense Categorization Algorithm:** Applies keyword matching across 11 expense categories and 7 income categories to suggest a category when a description is provided. No machine learning or user-pattern learning is involved.

**Action:** In **e) Gamification Engine Service**, find:
> **Experience Point Calculation:** Awards XP based on activity type

Replace with:
> **Experience Point Calculation:** Derives the user's total XP dynamically by summing the `XpReward` field from all achievements the user has unlocked. XP is not stored as a running counter and is not awarded for individual actions.

**Action:** In the Presentation Layer **State Management** component, find:
> Caching mechanism for offline functionality addressing NFR002 requirement: "System should support offline functionality for core features with data synchronization"

Delete this bullet entirely. Offline caching was not implemented.

**Action:** In the Presentation Layer **Responsibilities**, find:
> Provide offline data access for core features (expense entry, budget viewing)

Replace with:
> Require active internet connection for all data operations; financial data is fetched from the Flask API and is not cached locally

---

## Revision 31 — §4.4.7 Architecture Quality Attributes: Fix Security and Reliability Claims

**Action:** In §4.4.7 under **Layer 2 - Application Layer Security**, find:
> Rate limiting on authentication endpoints prevents brute force attacks

Replace with:
> Authentication endpoints return generic error messages ("Invalid credentials") regardless of failure reason, preventing account enumeration. Rate limiting is identified as a future security enhancement.

**Action:** In **Layer 3 - Data Layer Security**, find:
> AES-256 encryption for sensitive fields at rest

Replace with:
> Passwords stored as bcrypt hashes; financial data stored in server-side MySQL with no sensitive data cached on the user's device

**Action:** In **Layer 2 - Application Layer Security**, find:
> JWT token authentication with 7-day expiry and signed tokens

Replace with:
> JWT dual-token authentication: 1-hour access tokens and 30-day refresh tokens, both HS256-signed

**Action:** In **Reliability Mechanisms**, find:
> **Offline Capability for Core Features:** Flutter local database (SQLite) enables expense entry without connectivity

Delete this bullet entirely. There is no local SQLite database and no offline capability.

Also find the NFR002 reliability bullet:
> **NFR002:** Offline capability meets requirement: "System should support offline functionality for core features with data synchronization"

Replace with:
> **NFR002 (Cross-Platform):** Flutter compiles to native ARM code for both Android 8.0+ and iOS, delivering consistent performance across platforms

---

## Revision 32 — §4.5.1 Authentication Process: Fix JWT Reference and Add 2FA to Login Flow

**Action:** In §4.5.1 Login Process Flow, find step 5:
> **Token Generation:** Upon successful verification, system generates JWT authentication token with **7-day expiry**

Replace with:
> **Token Generation:** Upon successful verification, the server generates a dual-token pair: an access token (1-hour expiry) and a refresh token (30-day expiry). If the user has 2FA enabled, a temporary token is returned instead and the client is prompted for a TOTP code before full tokens are issued.

**Action:** In §4.5.1 Login Process Flow, after step 5 (Token Generation), insert a new conditional step:

> **5a. Two-Factor Verification (if enabled):** If the user account has TOTP 2FA enabled, the login flow pauses after credential verification. The client displays a TOTP input screen. The user enters the 6-digit code from their authenticator app (or a backup code). The server verifies the TOTP code using the stored secret. On success, the full token pair is issued. On failure, authentication is rejected with a 401 error.

**Action:** In the Behavioral Principles paragraph, find:
> "Friction Reduction: Streamlined registration (3 fields only) and **7-day token expiry** eliminate barriers to consistent usage"

Replace with:
> "Friction Reduction: Streamlined registration and silent token refresh (via 30-day refresh tokens) eliminate repeated login prompts during normal use"

---

## Revision 33 — §4.5.1 Registration: Fix Password Requirement and Remove Phone Number

**Action:** In §4.5.1 Registration Process Variant step 3 (Client-Side Validation), find:
> Password strength requirements (minimum 8 characters, **alphanumeric**)

Replace with:
> Password strength requirements: minimum 8 characters, at least one uppercase letter, at least one lowercase letter, at least one special character (symbol)

**Action:** In step 2 (Information Entry), find the field list:
> - Full name
> - Email address
> - Phone number (optional)
> - Password
> - Password confirmation

Remove "Phone number (optional)" — the USERS table has no phone column, and the registration form does not collect a phone number. The field list should be:
> - Full name
> - Email address
> - Password
> - Password confirmation

Also update the registration flowchart (Figure 4.5.1.2) if it shows "- Phone" as a collected field — remove that entry from the "User Enters:" box.

---

## Revision 34 — §4.5.2 Expense Entry Process: Fix Category List, Remove Per-Action XP, Remove Offline Error Handling

**Action:** In §4.5.2 Process Flow step 3 (Category Selection), find:
> User selects from visual category grid **(Food & Dining, Transport, Education, Gaming, Shopping, More)**

Replace with:
> User selects from category dropdown: 11 expense categories (Food & Dining, Transportation, Shopping, Entertainment, Bills & Utilities, Healthcare, Education, Personal Care, Travel, Gifts & Donations, Others) or 7 income categories (Salary, Freelance, Investment Returns, Allowance, Bonus, Gifts Received, Other Income), displayed based on the selected transaction type

**Action:** In §4.5.2 Backend Processing step 9, find:
> Awards experience points for daily logging (**+10 XP**)

Delete this bullet entirely. XP is not awarded for logging transactions. XP increases only when an achievement is unlocked.

**Action:** In the expense entry flowchart (Figure 4.5.2.1), find the process step:
> **Award +10 XP for Logging**

Remove this step box from the flowchart. The actual backend processing does not include a direct XP award on transaction creation. The "Evaluate Achievement Criteria" step that follows it remains correct.

**Action:** In §4.5.2 Error Handling, find:
> **Network timeout:** Save transaction locally, sync when connection restored

Replace with:
> **Network timeout:** Display retry option with error message; the application requires an active internet connection for transaction creation

**Action:** In §4.5.2 Behavioral Principles, find:
> "Immediate Gratification: **Instant XP rewards** and visual budget updates address present bias by making future benefits feel present"

Replace with:
> "Immediate Gratification: Visual budget updates and achievement notifications (when criteria are met) provide immediate positive reinforcement, addressing present bias identified in Chapter 2"

---

## Revision 35 — §4.2.2 Add Missing Screens to Interface Design Overview

**Action:** In §4.2.2 (Interface Design), after screen 10 (Achievement), add a brief note acknowledging additional implemented screens not detailed with full wireframe mockups:

> **Additional Implemented Screens (not detailed above):**
>
> - **Recurring Transactions Screen** — lists all recurring transaction templates with status, next execution date, and a toggle to pause/resume. Users create templates via the Add Recurring Transaction screen specifying name, type, category, amount, and frequency (daily, weekly, monthly, yearly).
>
> - **Financial Insights Screen** — displays a circular financial health score (0–100) calculated from four pillars (savings rate, budget adherence, tracking consistency, goal progress), a monthly income/expense/savings summary, and 4–6 insight cards with plain-language recommendations.
>
> - **Security Settings Screen** — provides access to 2FA setup, backup codes display, and session management. Users can enable or disable TOTP two-factor authentication and regenerate backup codes from this screen.
>
> - **Goals Screen** — allows users to create and track financial goals with a target amount, deadline, and progress indicator.

---

---

## SUMMARY TABLE

| # | Location | Issue | Severity |
|---|----------|-------|----------|
| 1 | §4.7.2 JWT code | `expires_delta=timedelta(days=7)` — actual: 1-hour access / 30-day refresh | High |
| 2 | §4.7.2 JWT Security Features | "7-Day Expiry" bullet — wrong | High |
| 3 | §4.8.1 Process Design summary | "7-day token expiry" — wrong | High |
| 4 | §4.7.1 Encryption at Rest | `DataEncryption`/Fernet class — does not exist in codebase | High |
| 5 | §4.7.6 Current Limitations | "Single-Factor Authentication...2FA planned for future" — 2FA IS implemented | High |
| 6 | §4.7.2 Password Requirements | "Cannot reuse last 3 passwords", "No dictionary words", "Cannot match email" — not implemented | High |
| 7 | §4.7.2 Rate Limiting | `flask_limiter` code — not installed or implemented | High |
| 8 | §4.7.2 Account Lockout | `check_failed_login_attempts` — does not exist | High |
| 9 | §4.6.3 XP Algorithm | `award_experience_points` per-action function — does not exist | High |
| 10 | §4.6.3 XP Algorithm | `MAX_LEVEL = 20` cap — no hard cap in actual code | High |
| 11 | §4.6.3 XP Algorithm | Level-based feature unlock table — completely fabricated | High |
| 12 | §4.5.5 Gamification | "Personal progress focus (not competitive leaderboards)" — leaderboard IS implemented | High |
| 13 | §4.6.5 Streak Algorithm | `award_experience_points(user_id, 'streak_bonus')` call — function does not exist | Medium |
| 14 | §4.6.5 Streak Algorithm | `UPDATE USERS SET CurrentStreak` — actual: HABITSTREAKS table | Medium |
| 15 | §4.6.1 Categorisation | Only 5 categories listed, includes "Gaming" — actual: 11 expense categories, no Gaming | High |
| 16 | §4.6.1 Categorisation | "User correction learning improves accuracy" — not implemented | Medium |
| 17 | §4.5.4 Investment Entry | 3–4 investment types shown — actual: 10 types | High |
| 18 | §4.3 Data Architecture | "Eight core tables" — actual: 14 tables | Medium |
| 19 | §4.4.5 API Endpoints | Table shows ~18 endpoints — actual: 52 | High |
| 20 | §4.5/§4.6 | Offline mode and SQLite local cache references — not implemented | Medium |
| 21 | §4.8.2 NFR004 | "automated backups, and offline synchronization" — neither implemented | Medium |
| 22 | §4.8.2 NFR003 | "AES-256 encryption" — not implemented at application layer | High |
| 23 | §4.8.1 Algorithm Design | "user pattern learning" for categorisation — not implemented | Medium |
| 24 | §4.5/§4.6 | Recurring transactions — fully implemented, not mentioned anywhere | Medium |
| 25 | §4.5 | Financial Insights screen — implemented, not mentioned | Medium |
| 26 | §4.7.2 | 2FA implementation — not described in authentication section | High |
| 27 | §4.8 Chapter Summary | Too long, AI self-evaluation style, contains 7-day JWT/AES-256/offline errors | Medium |
| 28 | §4.2.2 Achievement Gamification Elements | "Progressive leveling (1-20)", per-action XP list (+10/+50/+5), "level unlocks features", "Learning achievements" — all wrong | High |
| 29 | §4.2.2 Achievement Design Justification | "Rather than competitive leaderboards" — leaderboard IS implemented | High |
| 30 | §4.2.2.9 Add Investment | "Three visual cards (Stock, Fund, Bond)" — actual: 10 asset types | High |
| 31 | §4.2.2.9 Add Investment | "Malaysian-specific autocomplete database" for asset names — not implemented | Medium |
| 32 | §4.3.2 ERD | Caption says "Complete ERD" but shows only 8/14 tables; GOALS, RECURRINGTRANSACTIONS, USERSETTINGS, TWOFACTORAUTHS, BACKUPCODES, SECURITYLOGS missing | High |
| 33 | §4.3.4 Schema | Only 8 tables defined; 6 additional tables not included | High |
| 34 | §4.4.3 Code | JWT code snippet shows `timedelta(days=7)` with "7-day expiry" comment | High |
| 35 | §4.4.4 Auth Service | "Creates signed tokens with 7-day expiry" | High |
| 36 | §4.4.4 Financial Service | "Applies keyword matching and **machine learning**" — ML not implemented | Medium |
| 37 | §4.4.4 Gamification Service | "Experience Point Calculation: Awards XP based on activity type" — XP comes from achievements only | High |
| 38 | §4.4.4 Presentation Layer | "Caching mechanism for offline functionality" + "Provide offline data access" — not implemented | Medium |
| 39 | §4.4.7 Layer 2 Security | "Rate limiting on authentication endpoints" — not implemented | High |
| 40 | §4.4.7 Layer 3 Security | "AES-256 encryption for sensitive fields at rest" — not implemented | High |
| 41 | §4.4.7 Layer 2 Security | "JWT token authentication with 7-day expiry" | High |
| 42 | §4.4.7 Reliability | "Flutter local database (SQLite) enables expense entry without connectivity" — SQLite not used | High |
| 43 | §4.5.1 Login Flow step 5 | "JWT token with 7-day expiry" — another instance | High |
| 44 | §4.5.1 Login Flow | Missing 2FA TOTP verification step for 2FA-enabled accounts | High |
| 45 | §4.5.1 Registration | "Password strength: minimum 8 characters, alphanumeric" — wrong, symbol required | Medium |
| 46 | §4.5.1 Registration | "Phone number (optional)" collected at registration — USERS table has no phone column | Medium |
| 47 | §4.5.1 Behavioral Principles | "7-day token expiry" as friction reduction claim | Medium |
| 48 | §4.5.2 Category Selection | "Gaming" in category grid (Food, Transport, Education, **Gaming**, Shopping, More) | High |
| 49 | §4.5.2 Backend Processing | "Awards experience points for daily logging (+10 XP)" — not implemented | High |
| 50 | §4.5.2 Flowchart Fig 4.5.2.1 | "Award +10 XP for Logging" step box — should be removed | High |
| 51 | §4.5.2 Error Handling | "Network timeout: Save transaction locally, sync when connection restored" — offline not implemented | Medium |
| 52 | §4.5.2 Behavioral Principles | "Instant XP rewards" — XP not awarded on transaction logging | Medium |
| 53 | §4.2.2 | Missing screen designs: Recurring Transactions, Financial Insights, Security Settings/2FA, Goals | Medium |

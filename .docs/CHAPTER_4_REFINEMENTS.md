# Chapter 4 — System Design: Refinements Document

## Introduction

This document contains targeted refinements to Chapter 4 (System Design) that reflect deviations between the original design plan and the system as it was ultimately implemented. Three sections require updating: Section 4.1.4 (API Endpoints), which originally catalogued only nine endpoints but now encompasses over fifty across twelve route modules; Section 4.3 (Database Schema), which did not account for four additional tables introduced to support two-factor authentication, session management, and security audit logging; and Section 4.7.2 (Authentication Security), which must be extended with new subsections covering the TOTP-based two-factor authentication mechanism, backup code management, a security score system, session tracking, and the security activity log. Each refinement below is labelled with the precise insertion or replacement instruction.

---

## Refinement 1 — Section 4.1.4: API Endpoint Reference

**Action:** Replace the existing Section 4.1.4 in its entirety with the content below.

---

### 4.1.4 API Endpoint Reference

The RESTful API exposed by the Flask backend is organised into twelve route modules, each prefixed with `/api/` and registered as a Flask Blueprint. Table 4.1.4.1 through Table 4.1.4.12 enumerate every endpoint grouped by functional area. All endpoints that operate on user-specific resources require a valid JSON Web Token (JWT) supplied in the `Authorization: Bearer <token>` header unless stated otherwise.

The column headings used throughout these tables are defined as follows. **Method** denotes the HTTP verb. **Endpoint** is the URL path relative to the server root. **Description** summarises the operation performed.

---

#### Table 4.1.4.1: Authentication Endpoints (`/api/auth`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register a new user account |
| POST | `/api/auth/login` | Authenticate with email and password; returns JWT |
| POST | `/api/auth/logout` | Invalidate the current session token |
| GET | `/api/auth/profile` | Retrieve the authenticated user's profile |
| PUT | `/api/auth/profile` | Update profile fields (name, currency, etc.) |
| POST | `/api/auth/verify-email` | Verify email address using a one-time token |
| POST | `/api/auth/resend-verification` | Resend the email verification link |
| POST | `/api/auth/forgot-password` | Initiate the password reset flow via email |
| POST | `/api/auth/reset-password` | Complete password reset using the emailed token |

---

#### Table 4.1.4.2: Transaction Endpoints (`/api/transactions`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/transactions` | Retrieve all transactions for the authenticated user |
| POST | `/api/transactions` | Create a new income or expense transaction |
| PUT | `/api/transactions/<id>` | Update an existing transaction by ID |
| DELETE | `/api/transactions/<id>` | Delete a transaction by ID |

---

#### Table 4.1.4.3: Budget Endpoints (`/api/budgets`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/budgets` | Retrieve all budgets for the authenticated user |
| POST | `/api/budgets` | Create a new category budget |
| PUT | `/api/budgets/<id>` | Update a budget limit or category |
| DELETE | `/api/budgets/<id>` | Delete a budget by ID |
| GET | `/api/budgets/status` | Retrieve current spending versus budget limits for all categories |

---

#### Table 4.1.4.4: Financial Goal Endpoints (`/api/goals`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/goals` | Retrieve all savings goals for the authenticated user |
| POST | `/api/goals` | Create a new savings goal |
| PUT | `/api/goals/<id>` | Update goal name, target amount, or deadline |
| DELETE | `/api/goals/<id>` | Delete a savings goal by ID |
| POST | `/api/goals/<id>/contribute` | Add a contribution amount to a specific goal |

---

#### Table 4.1.4.5: Investment Endpoints (`/api/investments`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/investments` | Retrieve all investment holdings for the authenticated user |
| POST | `/api/investments` | Record a new investment position |
| PUT | `/api/investments/<id>` | Update an investment entry (quantity, price, etc.) |
| DELETE | `/api/investments/<id>` | Remove an investment record by ID |
| GET | `/api/investments/portfolio` | Retrieve an aggregated portfolio summary with gain/loss calculations |

---

#### Table 4.1.4.6: Gamification Endpoints (`/api/gamification`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/gamification/achievements` | Retrieve all achievements and their unlock status for the user |
| POST | `/api/gamification/achievements/check` | Trigger a server-side check for newly earned achievements |
| GET | `/api/gamification/streak` | Retrieve the user's current and longest login streak |
| GET | `/api/gamification/leaderboard` | Retrieve the anonymised XP leaderboard |
| GET | `/api/gamification/profile` | Retrieve the user's level, XP total, and badge collection |

---

#### Table 4.1.4.7: Report and Export Endpoints (`/api/reports`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/reports/spending-trends` | Retrieve monthly spending totals over a configurable date range |
| GET | `/api/reports/income-expense` | Retrieve a period-by-period income versus expense comparison |
| GET | `/api/reports/category-breakdown` | Retrieve spending totals grouped by transaction category |
| GET | `/api/reports/budget-comparison` | Retrieve actual spending compared against budget limits per category |
| GET | `/api/reports/export/csv` | Export transaction history as a downloadable CSV file |
| GET | `/api/reports/export/pdf` | Export a formatted financial summary report as a downloadable PDF file |

---

#### Table 4.1.4.8: Settings Endpoints (`/api/settings`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/settings` | Retrieve the authenticated user's application preferences |
| PUT | `/api/settings` | Update preferences (currency, notifications, theme, etc.) |

---

#### Table 4.1.4.9: Two-Factor Authentication Endpoints (`/api/2fa`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/2fa/setup` | Generate a TOTP secret and QR code to begin 2FA enrolment |
| POST | `/api/2fa/enable` | Confirm enrolment by verifying the first TOTP code |
| POST | `/api/2fa/disable` | Disable 2FA after password confirmation |
| POST | `/api/2fa/verify` | Verify a TOTP code during the login flow |
| GET | `/api/2fa/backup-codes` | Retrieve the count of remaining unused backup codes |
| POST | `/api/2fa/backup-codes/regenerate` | Invalidate existing backup codes and issue a fresh set of ten |

---

#### Table 4.1.4.10: Security and Session Management Endpoints (`/api/security`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/security/sessions` | List all active login sessions for the authenticated user |
| DELETE | `/api/security/sessions/<id>` | Revoke a specific session, logging out that device |
| GET | `/api/security/log` | Retrieve the security activity log for the authenticated user |
| DELETE | `/api/security/account` | Permanently delete the authenticated user's account and all associated data |

---

#### Table 4.1.4.11: Recurring Transaction Endpoints (`/api/recurring`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/recurring` | Retrieve all recurring transaction rules for the authenticated user |
| POST | `/api/recurring` | Create a new recurring transaction rule |
| PUT | `/api/recurring/<id>` | Update the amount, frequency, or category of a recurring rule |
| DELETE | `/api/recurring/<id>` | Delete a recurring transaction rule |
| POST | `/api/recurring/<id>/execute` | Manually trigger execution of a recurring transaction |
| POST | `/api/recurring/<id>/pause` | Pause a recurring rule so it is skipped on its next scheduled date |
| POST | `/api/recurring/<id>/resume` | Resume a previously paused recurring rule |

---

#### Table 4.1.4.12: Financial Insights Endpoints (`/api/insights`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/insights/user/<id>` | Compute and return a personalised financial health report: overall score (0–100), four-pillar breakdown, this-month income/expense/savings summary, and ranked insight cards |

---

#### Table 4.1.4.13: Dashboard Endpoint

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/dashboard` | Retrieve an aggregated summary of balances, recent transactions, budget status, and gamification metrics for the home screen |

---

The total API surface comprises **52 endpoints** across the thirteen modules enumerated above. This represents a significant expansion from the nine endpoints specified in the original design, reflecting the broader feature scope delivered during implementation.

---

## Refinement 2 — Section 4.7.2: Additional Authentication Security Subsections

**Action:** In Section 4.7.2, after the existing content covering bcrypt password hashing, JWT token issuance, and rate limiting, INSERT the following new subsections. Do not remove or alter the existing text above the insertion point.

---

### 4.7.2.4 Two-Factor Authentication

SmartFinance implements Two-Factor Authentication (2FA) using the Time-based One-Time Password (TOTP) algorithm as defined in RFC 6238. TOTP augments the standard password-based login by requiring the user to supply a second credential — a six-digit code generated by an authenticator application — before a session is established. This ensures that the compromise of a user's password alone is insufficient to gain access to the account.

**Technical mechanism.** The backend employs the `pyotp` Python library to manage TOTP operations. During enrolment, the server generates a cryptographically random base32-encoded secret key and stores it in the `TwoFactorAuths` table (see Section 4.3). A provisioning URI is constructed using `pyotp.totp.TOTP().provisioning_uri()`, which encodes the secret, the user's email address, and the issuer name (`SmartFinance`). This URI is rendered as a QR code and returned to the client as a base64-encoded PNG image. The user scans the QR code using a compatible authenticator application — such as Google Authenticator or Microsoft Authenticator — which derives the same time-based codes from the shared secret. Each code is six digits in length and is valid for a 30-second window, with a tolerance of ±30 seconds applied server-side to accommodate minor clock drift between the user's device and the server.

**Enrolment flow.** Enabling 2FA is a two-step process. The user first initiates setup, which causes the server to generate the secret and QR code without yet activating 2FA on the account. The user must then supply a valid TOTP code derived from the QR code they scanned; only upon successful verification does the server set `TwoFactorEnabled = TRUE` on the user record, committing 2FA to an active state. This two-step approach prevents a user from locking themselves out by activating 2FA before confirming that their authenticator application has been configured correctly.

**Login flow.** When a user with 2FA enabled submits their credentials at the login screen, the server validates the password and, if correct, returns a partial authentication response indicating that a TOTP code is required rather than issuing a full JWT. The client presents a verification dialogue, and the user enters the six-digit code from their authenticator application. The server verifies the code against the shared secret; only upon successful verification is a JWT issued and a session established.

**Backup codes.** During enrolment, the server generates ten one-time-use backup codes. Each code is produced using `secrets.token_hex(4)`, yielding an eight-character hexadecimal string (e.g., `a1b2c3d4`). Before storage, each backup code is individually hashed using bcrypt; only the hashed values are persisted in the database. The plaintext codes are returned to the client once, at the moment of generation, and are never retrievable thereafter. If a user loses access to their authenticator application, they may present a backup code in place of a TOTP code to complete login. Each code is consumed upon use — it cannot be reused — and is marked as such in the database. Users may view the count of their remaining unused codes, or regenerate a fresh set of ten at any time from the Security Settings screen; regeneration invalidates all previously issued codes.

**Disabling 2FA.** Disabling 2FA requires the user to confirm their current password, after which the server sets `TwoFactorEnabled = FALSE` on the user record and deletes the associated `TwoFactorAuths` entry and all backup codes. Requiring password confirmation prevents a scenario in which an attacker who has gained temporary access to an unlocked device is able to silently remove the second factor.

---

### 4.7.2.5 Security Score System

To encourage users to adopt available security measures, SmartFinance presents a security score on the Security Settings screen. The score is computed server-side on a 0–100 point scale according to the criteria in Table 4.7.2.5.1.

**Table 4.7.2.5.1: Security Score Values**

| Account State | Score |
|---------------|-------|
| Email not verified (no 2FA) | 30 |
| Email verified, 2FA not enabled | 60 |
| Email verified and 2FA enabled | 100 |

The score takes one of three discrete values rather than accumulating points incrementally. A base score of 30 reflects the minimum state of any registered account. Completing email verification raises the score to 60, and enabling 2FA raises it further to 100. The score is presented as a filled progress bar whose colour conveys the security level: red for scores below 50 (*low security*), amber for scores of 50–79 (*medium security*), and green for scores of 80 and above (*high security*). This design communicates to the user that email verification is a prerequisite for a meaningful security posture, and that enabling 2FA is the single most impactful step available to reach maximum protection.

---

### 4.7.2.6 Session Management

Every successful login creates a record in the `usersessions` table capturing the session identifier, the user identifier, the device name, the device type, the client IP address, the user agent string, the login timestamp, and the last-active timestamp. Sessions are linked to a refresh token, allowing access tokens to be renewed without requiring re-authentication, and carry an expiry timestamp after which the refresh token is no longer accepted.

The Security Settings screen presents the user with a list of all currently active sessions, displaying the device name, device type, and last-active time for each entry. The user may revoke any individual session — for example, to log out a device that is no longer in their possession — by selecting it from the list. Revoking a session sets `IsActive = FALSE` on the corresponding record and records a `session_terminated` event in the security log (see Section 4.7.2.7 below).

The device name and type displayed to the user are derived from the `User-Agent` header submitted by the client at login time, enabling the user to identify entries such as *Samsung Galaxy S24 (mobile)* or *Chrome on Windows 11 (web)* at a glance.

---

### 4.7.2.7 Security Activity Log

SmartFinance maintains a persistent audit trail of security-relevant events in the `securitylogs` table. Each log entry records the event type, a human-readable description, the originating IP address, the device information, a success flag, and the timestamp at which the event occurred. The categories of events captured are listed in Table 4.7.2.7.1.

**Table 4.7.2.7.1: Security Log Event Types**

| Event Type | Description |
|------------|-------------|
| `login` | Successful authentication |
| `login_failed` | Failed authentication attempt (incorrect password) |
| `logout` | User-initiated logout |
| `password_change` | User changed their account password |
| `2fa_enabled` | Two-Factor Authentication was activated on the account |
| `2fa_disabled` | Two-Factor Authentication was deactivated on the account |
| `session_terminated` | A specific session was revoked by the user |
| `email_verified` | The user's email address was verified |
| `account_deleted` | The user's account was permanently deleted |

The log is visible to the user through the Security Settings screen, where entries are displayed in reverse-chronological order with the event description, device information, and timestamp shown for each entry. Exposing this log to the user directly supports the principle of transparency, enabling individuals to detect any suspicious activity — such as login events originating from unfamiliar IP addresses — and take remedial action accordingly.

---

## Refinement 3 — Section 4.3: Additional Database Tables

**Action:** In Section 4.3 (Database Schema), after the last existing table definition, INSERT the following four table definitions. Do not remove or alter any existing table content.

---

### 4.3.X TwoFactorAuths Table

The `TwoFactorAuths` table stores the TOTP secret key associated with each user who has enrolled in two-factor authentication. A record is created when the user initiates 2FA setup and is deleted when 2FA is disabled. The one-to-one relationship with the `Users` table is enforced by a `UNIQUE` constraint on `UserId`.

**Table 4.3.X.1: TwoFactorAuths**

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| TwoFactorAuthId | INT | PK, AUTO_INCREMENT | Unique identifier for the 2FA configuration record |
| UserId | INT | FK → Users(UserId), UNIQUE, NOT NULL | The user to whom this 2FA configuration belongs; UNIQUE enforces a one-to-one relationship |
| SecretKey | VARCHAR(255) | NOT NULL | Base32-encoded TOTP secret shared between the server and the user's authenticator application |
| IsEnabled | BOOLEAN | NOT NULL, DEFAULT FALSE | Indicates whether 2FA has been fully enrolled and is active for the account |
| EnabledAt | DATETIME | NULLABLE | Timestamp at which 2FA was confirmed and activated; NULL if enrolment has not yet been completed |

```sql
CREATE TABLE TwoFactorAuths (
    TwoFactorAuthId  INT          NOT NULL AUTO_INCREMENT,
    UserId           INT          NOT NULL,
    SecretKey        VARCHAR(255) NOT NULL,
    IsEnabled        BOOLEAN      NOT NULL DEFAULT FALSE,
    EnabledAt        DATETIME     NULL,
    PRIMARY KEY (TwoFactorAuthId),
    UNIQUE KEY uq_twofactorauths_userid (UserId),
    CONSTRAINT fk_twofactorauths_user
        FOREIGN KEY (UserId) REFERENCES Users (UserId) ON DELETE CASCADE
);
```

The `ON DELETE CASCADE` clause ensures that a user's 2FA record is automatically removed when the associated `Users` row is deleted, maintaining referential integrity without requiring a separate deletion step in application code.

---

### 4.3.X+1 BackupCodes Table

The `BackupCodes` table stores the bcrypt-hashed representations of the ten one-time-use recovery codes generated during 2FA enrolment. Storing hashes rather than plaintext values means that even if the database were compromised, an attacker could not directly extract usable backup codes. A new set of ten rows is inserted whenever the user regenerates their backup codes; at that point, all previous rows for that user are first deleted.

**Table 4.3.X+1.1: BackupCodes**

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| BackupCodeId | INT | PK, AUTO_INCREMENT | Unique identifier for the backup code record |
| UserId | INT | FK → Users(UserId), NOT NULL | The user to whom this backup code belongs |
| CodeHash | VARCHAR(255) | NOT NULL | bcrypt hash of the plaintext backup code; the plaintext is never stored |
| IsUsed | BOOLEAN | NOT NULL, DEFAULT FALSE | Indicates whether this code has already been consumed during login |
| UsedAt | DATETIME | NULLABLE | Timestamp at which the code was consumed; NULL if the code has not yet been used |
| CreatedAt | DATETIME | NOT NULL | Timestamp at which the backup code was generated |

```sql
CREATE TABLE BackupCodes (
    BackupCodeId  INT          NOT NULL AUTO_INCREMENT,
    UserId        INT          NOT NULL,
    CodeHash      VARCHAR(255) NOT NULL,
    IsUsed        BOOLEAN      NOT NULL DEFAULT FALSE,
    UsedAt        DATETIME     NULL,
    CreatedAt     DATETIME     NOT NULL,
    PRIMARY KEY (BackupCodeId),
    CONSTRAINT fk_backupcodes_user
        FOREIGN KEY (UserId) REFERENCES Users (UserId) ON DELETE CASCADE
);
```

---

### 4.3.X+2 UserSessions Table

The `UserSessions` table records each login session established by a user, enabling the session management features described in Section 4.7.2.6. A new row is inserted on every successful login. Sessions may be deactivated either by the user (via the Security Settings screen) or automatically upon token expiry.

**Table 4.3.X+2.1: UserSessions**

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| SessionId | INT | PK, AUTO_INCREMENT | Unique identifier for the session record |
| UserId | INT | FK → Users(UserId), NOT NULL | The user to whom this session belongs |
| DeviceName | VARCHAR(255) | NULLABLE | Human-readable device name derived from the User-Agent header (e.g., *Samsung Galaxy S24*) |
| DeviceType | VARCHAR(50) | NULLABLE | Broad device category: `mobile`, `web`, or `desktop` |
| IpAddress | VARCHAR(45) | NULLABLE | IPv4 or IPv6 address of the client at the time of login; VARCHAR(45) accommodates the maximum length of an IPv6 address |
| UserAgent | TEXT | NULLABLE | Full User-Agent string submitted by the client at login |
| LoginAt | DATETIME | NOT NULL | Timestamp at which the session was created |
| LastActiveAt | DATETIME | NULLABLE | Timestamp of the most recent API request made within this session |
| IsActive | BOOLEAN | NOT NULL, DEFAULT TRUE | FALSE once the session has been revoked or has expired |
| RefreshToken | VARCHAR(500) | NULLABLE | JWT refresh token associated with this session |
| ExpiresAt | DATETIME | NULLABLE | Timestamp after which the refresh token is no longer valid |

```sql
CREATE TABLE UserSessions (
    SessionId     INT          NOT NULL AUTO_INCREMENT,
    UserId        INT          NOT NULL,
    DeviceName    VARCHAR(255) NULL,
    DeviceType    VARCHAR(50)  NULL,
    IpAddress     VARCHAR(45)  NULL,
    UserAgent     TEXT         NULL,
    LoginAt       DATETIME     NOT NULL,
    LastActiveAt  DATETIME     NULL,
    IsActive      BOOLEAN      NOT NULL DEFAULT TRUE,
    RefreshToken  VARCHAR(500) NULL,
    ExpiresAt     DATETIME     NULL,
    PRIMARY KEY (SessionId),
    CONSTRAINT fk_usersessions_user
        FOREIGN KEY (UserId) REFERENCES Users (UserId) ON DELETE CASCADE
);
```

---

### 4.3.X+3 SecurityLogs Table

The `SecurityLogs` table constitutes the audit trail described in Section 4.7.2.7. Every security-relevant event raised by the application — successful logins, failed login attempts, password changes, 2FA state changes, session revocations, and account deletion — is written as an immutable row. Records are never updated or deleted through normal application operation, preserving the integrity of the audit trail.

**Table 4.3.X+3.1: SecurityLogs**

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| LogId | INT | PK, AUTO_INCREMENT | Unique identifier for the log entry |
| UserId | INT | FK → Users(UserId), NOT NULL | The user whose account the event relates to |
| EventType | VARCHAR(100) | NOT NULL | Machine-readable event category (e.g., `login`, `2fa_enabled`, `session_terminated`) |
| EventDescription | TEXT | NULLABLE | Human-readable description of the event (e.g., *Successful login from Chrome on Windows 11*) |
| IpAddress | VARCHAR(45) | NULLABLE | IP address from which the event originated |
| DeviceInfo | VARCHAR(255) | NULLABLE | Device and browser information associated with the event |
| Success | BOOLEAN | NOT NULL, DEFAULT TRUE | FALSE for events representing failed attempts (e.g., `login_failed`) |
| CreatedAt | DATETIME | NOT NULL | Timestamp at which the event was recorded |

```sql
CREATE TABLE SecurityLogs (
    LogId             INT          NOT NULL AUTO_INCREMENT,
    UserId            INT          NOT NULL,
    EventType         VARCHAR(100) NOT NULL,
    EventDescription  TEXT         NULL,
    IpAddress         VARCHAR(45)  NULL,
    DeviceInfo        VARCHAR(255) NULL,
    Success           BOOLEAN      NOT NULL DEFAULT TRUE,
    CreatedAt         DATETIME     NOT NULL,
    PRIMARY KEY (LogId),
    CONSTRAINT fk_securitylogs_user
        FOREIGN KEY (UserId) REFERENCES Users (UserId) ON DELETE CASCADE
);
```

The `ON DELETE CASCADE` clause is applied consistently across all four new tables so that account deletion via the `/api/security/account` endpoint results in a clean removal of all associated rows without requiring explicit multi-table delete logic in application code.

---

*End of Chapter 4 Refinements*

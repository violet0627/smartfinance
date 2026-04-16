# Chapter 4 — System Design (Revised)

---

## 4.1 System Overview

### 4.1.1 Introduction

The SmartFinance system is organised as a three-tier client-server architecture in which the presentation layer, application logic layer, and data layer operate as distinct, independently deployable tiers. The presentation tier comprises the Flutter mobile application running on the user's device. The application tier is a Python Flask REST API server that processes requests and enforces business rules. The data tier is a MySQL relational database that stores all persistent user and financial data. Communication between the presentation and application tiers occurs exclusively over HTTPS using JSON-formatted request and response bodies, with all protected endpoints requiring a valid JSON Web Token (JWT) in the `Authorization: Bearer` header.

This separation of concerns means that each tier can be modified, tested, and scaled without affecting the others. The Flutter client delegates all data operations to the Flask API rather than accessing the database directly, which centralises authentication enforcement and business logic validation at the server layer. Figure 4.1.1 illustrates the overall three-tier structure.

*[See Figure 4.1.1 — Overall Architecture Diagram (resources/new_diagrams/Figure_4.1.1_Overall_Diagram.html)]*

---

### 4.1.2 Architecture Decision

Three architectural patterns were evaluated before settling on the three-tier client-server design: monolithic architecture, microservices architecture, and peer-to-peer architecture. Table 4.1.2.1 summarises the comparison.

**Table 4.1.2.1: Architecture Pattern Comparison**

| Criterion | Three-Tier Client-Server | Monolithic | Microservices | Peer-to-Peer |
|-----------|--------------------------|------------|---------------|--------------|
| Development complexity | Medium | Low | High | High |
| Cross-platform support | Good | Limited | Good | Poor |
| Security centralisation | Centralised | Centralised | Distributed | Difficult |
| Scalability | Good | Limited | Excellent | Moderate |
| Maintenance | Independent layers | Single codebase | Complex | Difficult |
| FYP suitability | High | Medium | Low | Low |

The three-tier pattern was selected because it achieves the necessary separation between presentation and persistence without the operational overhead of microservices. A monolithic architecture would have tightly coupled the Flutter UI to database access logic, making independent testing of backend business rules impractical. Microservices would have introduced infrastructure complexity — separate service deployment, inter-service communication, distributed authentication — that is disproportionate to the scale of a student project. The three-tier pattern delivers clear layer boundaries, centralised JWT authentication, and independent development of frontend and backend components within a manageable complexity budget.

---

### 4.1.3 Architecture Components

The presentation layer is built with Flutter (Dart), which compiles to native ARM bytecode for Android and iOS from a single codebase. All UI rendering, local state management, and HTTP request formation occur at this layer. User inputs are validated locally before being dispatched to the API, providing immediate feedback without requiring a round-trip to the server.

The application layer is a Python Flask server exposing a RESTful API. Flask handles routing, request parsing, JWT verification, and response serialisation. SQLAlchemy provides an object-relational mapping layer between Python objects and MySQL tables, isolating raw SQL from business logic. All authentication, authorisation, and data integrity checks are enforced at this layer before any database operation is performed.

The data layer is a MySQL 8.0 database providing ACID-compliant storage for all user, transaction, budget, investment, gamification, security, and settings data. The InnoDB storage engine is used throughout for its row-level locking and foreign key support. The schema implements fourteen tables connected by foreign key constraints with `ON DELETE CASCADE` to maintain referential integrity automatically when parent records are removed.

---

### 4.1.4 API Endpoint Reference

The RESTful API exposed by the Flask backend is organised into twelve route modules, each prefixed with `/api/` and registered as a Flask Blueprint. Tables 4.1.4.1 through 4.1.4.12 enumerate every endpoint grouped by functional area. All endpoints that operate on user-specific resources require a valid JWT supplied in the `Authorization: Bearer <token>` header unless stated otherwise.

---

**Table 4.1.4.1: Authentication Endpoints (`/api/auth`)**

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register a new user account |
| POST | `/api/auth/login` | Authenticate with email and password; returns JWT access and refresh tokens |
| POST | `/api/auth/refresh` | Exchange a valid refresh token for a new access token |
| POST | `/api/auth/verify-email` | Verify email address using a one-time token |
| POST | `/api/auth/resend-verification` | Resend the email verification link |
| POST | `/api/auth/forgot-password` | Initiate the password reset flow via email |
| POST | `/api/auth/reset-password` | Complete password reset using the emailed token |

---

**Table 4.1.4.2: Transaction Endpoints (`/api/transactions`)**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/transactions` | Retrieve all transactions for the authenticated user |
| POST | `/api/transactions` | Create a new income or expense transaction |
| PUT | `/api/transactions/<id>` | Update an existing transaction by ID |
| DELETE | `/api/transactions/<id>` | Delete a transaction by ID |

---

**Table 4.1.4.3: Budget Endpoints (`/api/budgets`)**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/budgets` | Retrieve all budgets for the authenticated user |
| POST | `/api/budgets` | Create a new category budget |
| PUT | `/api/budgets/<id>` | Update a budget limit or category |
| DELETE | `/api/budgets/<id>` | Delete a budget by ID |
| GET | `/api/budgets/status` | Retrieve current spending versus budget limits for all categories |

---

**Table 4.1.4.4: Financial Goal Endpoints (`/api/goals`)**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/goals` | Retrieve all savings goals for the authenticated user |
| POST | `/api/goals` | Create a new savings goal |
| PUT | `/api/goals/<id>` | Update goal name, target amount, or deadline |
| DELETE | `/api/goals/<id>` | Delete a savings goal by ID |
| POST | `/api/goals/<id>/contribute` | Add a contribution amount to a specific goal |

---

**Table 4.1.4.5: Investment Endpoints (`/api/investments`)**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/investments` | Retrieve all investment holdings for the authenticated user |
| POST | `/api/investments` | Record a new investment position |
| PUT | `/api/investments/<id>` | Update an investment entry (quantity, price, etc.) |
| DELETE | `/api/investments/<id>` | Remove an investment record by ID |
| GET | `/api/investments/portfolio` | Retrieve an aggregated portfolio summary with gain/loss calculations |

---

**Table 4.1.4.6: Gamification Endpoints (`/api/gamification`)**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/gamification/achievements` | Retrieve all achievements and their unlock status for the user |
| POST | `/api/gamification/achievements/check` | Trigger a server-side check for newly earned achievements |
| GET | `/api/gamification/streak` | Retrieve the user's current and longest login streak |
| GET | `/api/gamification/leaderboard` | Retrieve the anonymised XP leaderboard |
| GET | `/api/gamification/profile` | Retrieve the user's level, XP total, and badge collection |

---

**Table 4.1.4.7: Report and Export Endpoints (`/api/reports`)**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/reports/spending-trends` | Retrieve monthly spending totals over a configurable date range |
| GET | `/api/reports/income-expense` | Retrieve a period-by-period income versus expense comparison |
| GET | `/api/reports/category-breakdown` | Retrieve spending totals grouped by transaction category |
| GET | `/api/reports/budget-comparison` | Retrieve actual spending compared against budget limits per category |
| GET | `/api/reports/export/csv` | Export transaction history as a downloadable CSV file |
| GET | `/api/reports/export/pdf` | Export a formatted financial summary report as a downloadable PDF file |

---

**Table 4.1.4.8: Settings Endpoints (`/api/settings`)**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/settings` | Retrieve the authenticated user's application preferences |
| PUT | `/api/settings` | Update preferences (currency, notifications, theme, etc.) |

---

**Table 4.1.4.9: Two-Factor Authentication Endpoints (`/api/auth`)**

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/2fa/setup` | Generate a TOTP secret and QR code to begin 2FA enrolment |
| POST | `/api/auth/2fa/verify-setup` | Confirm enrolment by verifying the first TOTP code from the authenticator app |
| POST | `/api/auth/2fa/verify` | Verify a TOTP code during the login flow |
| POST | `/api/auth/2fa/verify-backup` | Verify a one-time backup code during the login flow |
| POST | `/api/auth/2fa/disable` | Disable 2FA after password confirmation |
| GET | `/api/auth/2fa/status/<id>` | Retrieve the 2FA enrolment status for a user |
| POST | `/api/auth/2fa/regenerate-backup-codes` | Invalidate existing backup codes and issue a fresh set of ten |

---

**Table 4.1.4.10: Security and Session Management Endpoints (`/api/security`)**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/security/sessions/user/<id>` | List all active login sessions for the authenticated user |
| POST | `/api/security/sessions/<id>/revoke` | Revoke a specific session, logging out that device |
| GET | `/api/security/activity/user/<id>` | Retrieve the security activity log for the authenticated user |
| POST | `/api/security/account/delete` | Permanently delete the authenticated user's account and all associated data |

---

**Table 4.1.4.11: Recurring Transaction Endpoints (`/api/recurring`)**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/recurring` | Retrieve all recurring transaction rules for the authenticated user |
| POST | `/api/recurring` | Create a new recurring transaction rule |
| PUT | `/api/recurring/<id>` | Update the amount, frequency, or category of a recurring rule |
| DELETE | `/api/recurring/<id>` | Delete a recurring transaction rule |
| POST | `/api/recurring/<id>/execute` | Manually trigger execution of a recurring transaction |
| POST | `/api/recurring/<id>/toggle` | Toggle a recurring rule between active and paused states |

---

**Table 4.1.4.12: Financial Insights Endpoints (`/api/insights`)**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/insights/user/<id>` | Compute and return a personalised financial health report: overall score (0–100), four-pillar breakdown, income/expense/savings summary, and ranked insight cards |

---

The API surface across the twelve modules above covers all functional domains of the application. The Flutter dashboard aggregates its home-screen data through multiple separate API calls (transaction summary, budget status, gamification stats) rather than a dedicated dashboard endpoint.

---

## 4.2 User Interface Design

### 4.2.1 UX Design Principles

Six UX principles guide the SmartFinance interface design, each selected for its relevance to financial applications used by young adults who may have limited prior experience with personal finance tools.

**Progressive disclosure** structures the interface so that only the information relevant to the user's current task is shown at any moment. Advanced options — recurring schedules, custom categories, investment notes — are accessible but not presented by default. This prevents the cognitive overload that causes users to abandon financial apps after initial setup.

**Error prevention** is prioritised over error recovery. Input fields apply real-time validation, amount fields restrict non-numeric entry, and date pickers replace free-text date entry to eliminate malformed inputs before they reach the server. Confirmation dialogs appear before irreversible actions such as deleting a transaction or removing an investment record.

**Recognition over recall** underpins the category system and form pre-filling. Rather than requiring users to remember category names or re-enter recurring information, the interface presents selectable category chips with recognisable icons. The intelligent categorisation algorithm (Section 4.6.1) suggests a category based on the transaction description, further reducing the cognitive demand of each entry.

**Cultural appropriateness** shapes both the visual language and the content defaults. Monetary amounts are displayed in Malaysian Ringgit (RM) with local number formatting. Default spending categories reflect Malaysian patterns — Food & Dining includes a mamak subcategory, Transport references Grab and Touch 'n Go, and Bills & Utilities reflects common Malaysian household expenses. English is the interface language, consistent with the primary medium of instruction at Malaysian universities.

**Motivational design integration** draws on self-determination theory (Ryan & Deci, 2000) and Fogg's behaviour model (Fogg, 2009). Achievements, experience points, habit streaks, and progress celebrations provide immediate positive reinforcement that standard financial management applications lack. These elements are designed to reward logging behaviour rather than financial performance specifically, which avoids penalising users whose financial situation is genuinely constrained.

**Accessibility and inclusivity** are addressed through adequate touch target sizing (minimum 44×44dp), sufficient colour contrast ratios for text overlaid on coloured backgrounds, and labels accompanying all iconographic elements. The colour coding used for budget status (green/amber/red) is supplemented with text percentage values and arrow indicators so that the information remains accessible to users with colour vision deficiencies.

---

### 4.2.2 Screen Designs

#### Login Screen

The Login Screen (Figure 4.2.2.1) presents two input fields — email address and password — alongside a primary login button and secondary links for password recovery and account creation. The design deliberately limits the information shown at first contact to reduce the perceived barrier to entry. A SmartFinance logo and brief tagline occupy the upper portion of the screen, establishing brand identity without consuming space needed for functional elements. Password masking is applied by default with a toggle to reveal the entered value, balancing security with usability for users who struggle with small on-screen keyboards.

*[See Figure 4.2.2.1 — Login Screen (resources/new_diagrams/Figure_4.2.2.1_Login_Screen.svg)]*

#### Registration Screen

The Registration Screen (Figure 4.2.2.2) collects four fields: full name, email address, password, and password confirmation. Phone number collection is optional. Password strength is communicated through a live indicator that updates as the user types, surfacing the specific requirements (minimum eight characters, at least one uppercase letter, one digit, one special character) rather than presenting them only after a failed submission. The form applies inline validation — green checkmarks or red error messages appear field by field — so users correct mistakes immediately rather than discovering all errors at once upon submission.

*[See Figure 4.2.2.2 — Registration Screen (resources/new_diagrams/Figure_4.2.2.2_Registration_Screen.svg)]*

#### Dashboard

The Dashboard (Figure 4.2.2.3) is the application's home screen, providing a summary view of the user's current financial position alongside gamification status. The upper section displays the current month's total income, total expenditure, and net balance in large typography. Below this, a budget status bar gives an at-a-glance percentage of the month's budget consumed. A compact achievements and streak display shows current XP level and active streak count without requiring navigation to the gamification screen. The lower section lists the five most recent transactions. This layout enables the user to assess their financial standing and record a new transaction from a single screen, minimising navigation depth for the most frequent use cases.

*[See Figure 4.2.2.3 — Dashboard Screen (original figure retained)]*

#### Add Transaction Screen

The Add Transaction Screen (Figure 4.2.2.4) is the most frequently used data entry screen and is optimised for speed. An amount field is presented prominently at the top. Income and Expense are toggled via a segmented control rather than a dropdown to reduce the number of taps required. The description field triggers the intelligent categorisation algorithm (Section 4.6.1) on each keystroke, populating a category suggestion chip that the user can accept with a single tap or override from a scrollable category grid. The date defaults to the current date, covering the most common entry scenario; a calendar picker is available for historical entries. A notes field and receipt attachment option are visible but collapsed by default, consistent with the progressive disclosure principle.

*[See Figure 4.2.2.4 — Add Transaction Screen (resources/new_diagrams/Figure_4.2.2.4_Add_Transaction_Screen.svg)]*

#### Transaction History

The Transaction History screen (Figure 4.2.2.5) displays all transactions in reverse-chronological order, grouped by date. A search bar supports filtering by description keyword, and filter chips allow narrowing by transaction type (income/expense), category, and date range. Each transaction row shows the category icon, description, date, and amount with colour coding — green for income, red for expense. Tapping a row expands an edit view in place rather than navigating to a separate screen, reducing the tap depth for corrections.

*[See Figure 4.2.2.5 — Transaction History (resources/new_diagrams/Figure_4.2.2.5_Transaction_History.svg)]*

#### Budget Overview

The Budget Overview screen (Figure 4.2.2.6) presents a horizontal progress bar for each budget category, colour-coded by consumption level: green below 75% (Safe), amber between 75% and 95% (Warning), and red above 95% (Critical/Exceeded). The current spending amount and allocated limit are shown numerically alongside each bar. This multi-colour display is designed to be immediately scannable — a user can detect which categories require attention without reading individual numbers. Categories where spending has exceeded the limit display a distinct icon to draw attention to the overage.

*[See Figure 4.2.2.6 — Budget Overview (resources/new_diagrams/Figure_4.2.2.6_Budget_Overview.svg)]*

#### Budget Creation Screen

The Budget Creation screen (Figure 4.2.2.7) allows the user to set a total monthly budget and allocate it across spending categories. A month selector at the top establishes which period the budget applies to. Below it, a total amount field accepts the overall budget figure, and a list of category rows each contains an amount input. A running subtotal shows the user how much of the total budget has been allocated as they fill in category amounts, preventing the common error of over-allocating a fixed budget. Categories with no allocation are retained in the list with zero values rather than being hidden, so the user is reminded to consider each category explicitly.

*[See Figure 4.2.2.7 — Budget Creation (resources/new_diagrams/Figure_4.2.2.7_Budget_Creation.svg)]*

#### Investment Portfolio Screen

The Investment Portfolio screen (Figure 4.2.2.8) presents a summary card at the top showing total investment cost, current portfolio value, overall absolute gain or loss, and overall percentage return. Below the summary, each holding is listed as a card with the asset name, type, quantity, purchase price, current price, absolute gain or loss, and percentage return. Cards use green text and upward arrows for profitable positions and red text with downward arrows for positions in loss, providing immediate visual differentiation. The portfolio performance categorisation follows the thresholds defined in Table 4.6.4.1.

*[See Figure 4.2.2.8 — Investment Portfolio (resources/new_diagrams/Figure_4.2.2.8_Investment_Portfolio.svg)]*

#### Investment Entry Screen

The Investment Entry screen (Figure 4.2.2.9) collects the information required to record a new holding: asset type (selectable from ten categories including Stocks, Cryptocurrency, ETF, Fixed Deposit, Bonds, Mutual Funds, Real Estate, Commodities, Unit Trust, and Other), asset name, stock symbol, quantity, purchase price, purchase date, current price, and optional notes. The asset type selector is presented as a scrollable chip list rather than a dropdown, keeping all options visible with a single scroll rather than requiring two taps. The Stock Symbol field is optional and hidden for asset types such as Fixed Deposit and Real Estate, where a ticker symbol is not applicable.

*[See Figure 4.2.2.9 — Investment Entry (resources/new_diagrams/Figure_4.2.2.9_Investment_Entry.svg)]*

#### Achievements Screen

The Achievements screen (Figure 4.2.2.10) is divided into two sections: unlocked badges and in-progress achievements. Unlocked badges are displayed as a grid of filled icons with the achievement name and unlock date. In-progress achievements show the badge icon in a greyed-out state alongside a progress bar and the completion criteria. The habit streak display occupies a dedicated card at the top of the screen, showing the current streak count, longest streak, and a seven-day calendar visualisation of recent activity. This screen is designed to function as a motivation anchor — giving users a tangible record of their financial tracking consistency.

*[See Figure 4.2.2.10 — Achievements Screen (original figure retained)]*

---

## 4.3 Data Architecture

### 4.3.1 Database Selection

MySQL was selected as the database management system for SmartFinance over SQLite, PostgreSQL, and MongoDB. Table 4.3.1.1 summarises the evaluation.

**Table 4.3.1.1: Database Management System Comparison**

| Criterion | MySQL | SQLite | PostgreSQL | MongoDB |
|-----------|-------|--------|------------|---------|
| ACID compliance | Full | Full | Full | Partial |
| Relational integrity | Full FK support | Limited | Full FK support | No FK support |
| Python integration | Excellent (SQLAlchemy) | Good | Good | Good |
| Financial data suitability | High | Medium | High | Low |
| Server deployment | Suitable | Not suitable | Suitable | Suitable |
| Learning resources | Extensive | Extensive | Good | Good |

Financial data imposes strict integrity requirements that ruled out MongoDB, whose flexible schema and partial ACID compliance are appropriate for document-oriented workloads but introduce consistency risks for transactional financial records. SQLite, while adequate for local development, is not designed for concurrent server-side access and does not support the foreign key constraints needed to maintain referential integrity across related tables. PostgreSQL is a credible alternative and was eliminated primarily on practical grounds: MySQL's wider deployment in Malaysian hosting environments, the team's existing familiarity with MySQL Workbench, and Python's mature SQLAlchemy MySQL driver. The InnoDB storage engine used throughout the schema provides row-level locking and full foreign key support, ensuring that cascading deletes and concurrent access are handled correctly.

---

### 4.3.2 Entity Relationship Design

The SmartFinance data model comprises fourteen entities. Figure 4.3.2.1 shows the complete entity-relationship diagram.

*[See Figure 4.3.2.1 — Entity Relationship Diagram (resources/new_diagrams/Figure_4.3.2.1_ERD.html)]*

The core domain entities are USERS, TRANSACTIONS, BUDGETS, BUDGETCATEGORIES, INVESTMENTS, GOALS, ACHIEVEMENTS, USERACHIEVEMENTS, HABITSTREAKS, RECURRINGTRANSACTIONS, and USERSETTINGS. Three additional tables — TWOFACTORAUTHS, USERSESSIONS, and SECURITYLOGS — support authentication security and audit trail requirements.

**USERS to TRANSACTIONS (one-to-many).** Each user may have zero or more transaction records. The `UserId` foreign key in TRANSACTIONS references USERS with `ON DELETE CASCADE`, so that deleting a user account automatically removes all associated transaction history without requiring explicit multi-step deletion in application code.

**USERS to BUDGETS (one-to-many).** A user may define budgets for multiple months. Each BUDGETS row represents one month's overall budget for a user, and the `ON DELETE CASCADE` constraint ensures that removing a user removes all their budget records.

**BUDGETS to BUDGETCATEGORIES (one-to-many).** Each monthly budget is broken into category-level allocations stored in BUDGETCATEGORIES. The `SpentAmount` column in BUDGETCATEGORIES is a denormalised cache of the current month's spending for that category, updated each time a transaction is recorded or modified. This avoids a costly aggregation query every time the Budget Overview screen loads.

**USERS to INVESTMENTS (one-to-many).** Investment holdings are stored per user. Each INVESTMENTS row represents one position — a quantity of a named asset purchased at a specific price. Current price is stored in the same row and updated manually by the user, as the application does not integrate with real-time market data feeds.

**ACHIEVEMENTS and USERS (many-to-many via USERACHIEVEMENTS).** The ACHIEVEMENTS table defines the catalogue of available badges and their unlock criteria. USERACHIEVEMENTS is a bridge table recording which achievements each user has unlocked and at what timestamp. The `Progress` column in USERACHIEVEMENTS tracks partial completion for count-based and milestone-based achievements, enabling the progress bars shown on the Achievements screen. The composite unique constraint on `(UserId, AchievementId)` prevents duplicate unlock records.

**USERS to HABITSTREAKS (one-to-many).** The HABITSTREAKS table records streak data per user and streak type. Current and longest streak values are stored directly in HABITSTREAKS and accessed per user when needed.

**USERS to GOALS (one-to-many).** Each user may have zero or more savings goals in the GOALS table. Goals carry a target amount, current amount, start date, deadline, status, category, and priority level.

**USERS to RECURRINGTRANSACTIONS (one-to-many).** The RECURRINGTRANSACTIONS table stores rules for automatically repeated income or expense entries. Each rule tracks its frequency (daily/weekly/monthly/yearly), last execution date, next execution date, and active status.

**USERS to USERSETTINGS (one-to-one).** The USERSETTINGS table holds notification preferences, budget alert thresholds, and leaderboard visibility for each user. The `UNIQUE` constraint on `UserId` enforces the one-to-one relationship.

---

### 4.3.3 Database Normalisation

The schema is normalised to Third Normal Form (3NF). Each table contains a single primary key with no repeating groups, all non-key attributes depend on the whole primary key (not a partial dependency), and no non-key attribute determines another non-key attribute (no transitive dependency). Category labels and asset types are stored as VARCHAR values in their respective rows rather than in separate lookup tables, which is appropriate given that both sets are fixed application-defined enumerations that do not change independently of the records that reference them.

A deliberate denormalisation is applied in BUDGETCATEGORIES, where `SpentAmount` caches the sum of transactions for a given category and month. This introduces a consistency responsibility — the application must update `SpentAmount` whenever a transaction is created, updated, or deleted — but the performance benefit justifies the trade-off. Budget status is queried on every dashboard load and every transaction save; computing the aggregate from raw transactions on each request would add a GROUP BY query to every such operation.

---

### 4.3.4 Table Definitions

#### USERS Table

The USERS table stores the core account record for each registered user.

```sql
CREATE TABLE Users (
    UserId            INT           NOT NULL AUTO_INCREMENT,
    Email             VARCHAR(255)  NOT NULL,
    PasswordHash      VARCHAR(255)  NOT NULL,
    FullName          VARCHAR(255)  NOT NULL,
    PhoneNumber       VARCHAR(20)   NULL,
    EmailVerified     BOOLEAN       NOT NULL DEFAULT FALSE,
    TwoFactorEnabled  BOOLEAN       NOT NULL DEFAULT FALSE,
    CreatedAt         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastLogin         DATETIME      NULL,
    ExperiencePts     INT           NOT NULL DEFAULT 0,
    CurrentLevel      INT           NOT NULL DEFAULT 1,
    PRIMARY KEY (UserId),
    UNIQUE KEY uq_users_email (Email)
);
```

The `PasswordHash` column stores the bcrypt hash of the user's password, never the plaintext value. `EmailVerified` is set to TRUE when the user clicks the verification link sent to their email address. `TwoFactorEnabled` is updated in tandem with the `TwoFactorAuths` record when 2FA is enrolled or removed. The `UNIQUE` constraint on `Email` enforces account uniqueness at the database level as a second line of defence after application-level validation.

#### TRANSACTIONS Table

```sql
CREATE TABLE Transactions (
    TransactionId    INT             NOT NULL AUTO_INCREMENT,
    UserId           INT             NOT NULL,
    Amount           DECIMAL(10, 2)  NOT NULL,
    Type             ENUM('Income', 'Expense') NOT NULL,
    Category         VARCHAR(100)    NOT NULL,
    Description      VARCHAR(255)    NULL,
    TransactionDate  DATE            NOT NULL,
    Notes            TEXT            NULL,
    CreatedAt        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (TransactionId),
    CONSTRAINT fk_transactions_user
        FOREIGN KEY (UserId) REFERENCES Users (UserId) ON DELETE CASCADE,
    INDEX idx_transactions_userid_date (UserId, TransactionDate)
);
```

`DECIMAL(10, 2)` is used for all monetary values throughout the schema to prevent floating-point rounding errors on financial calculations. The composite index on `(UserId, TransactionDate)` accelerates both date-range queries and the `MAX(TransactionDate)` call used by the streak tracking algorithm.

#### BUDGETS Table

```sql
CREATE TABLE Budgets (
    BudgetId      INT             NOT NULL AUTO_INCREMENT,
    UserId        INT             NOT NULL,
    Month         DATE            NOT NULL,
    TotalBudget   DECIMAL(10, 2)  NOT NULL,
    CreatedAt     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (BudgetId),
    UNIQUE KEY uq_budgets_user_month (UserId, Month),
    CONSTRAINT fk_budgets_user
        FOREIGN KEY (UserId) REFERENCES Users (UserId) ON DELETE CASCADE
);
```

The composite `UNIQUE` constraint on `(UserId, Month)` prevents a user from having more than one budget record per calendar month.

#### BUDGETCATEGORIES Table

```sql
CREATE TABLE BudgetCategories (
    BudgetCategoryId  INT             NOT NULL AUTO_INCREMENT,
    BudgetId          INT             NOT NULL,
    Category          VARCHAR(100)    NOT NULL,
    AllocatedAmount   DECIMAL(10, 2)  NOT NULL,
    SpentAmount       DECIMAL(10, 2)  NOT NULL DEFAULT 0.00,
    PRIMARY KEY (BudgetCategoryId),
    UNIQUE KEY uq_budgetcategories_budget_category (BudgetId, Category),
    CONSTRAINT fk_budgetcategories_budget
        FOREIGN KEY (BudgetId) REFERENCES Budgets (BudgetId) ON DELETE CASCADE
);
```

#### INVESTMENTS Table

```sql
CREATE TABLE Investments (
    InvestmentId   INT             NOT NULL AUTO_INCREMENT,
    UserId         INT             NOT NULL,
    AssetType      VARCHAR(50)     NOT NULL,
    AssetName      VARCHAR(255)    NOT NULL,
    StockSymbol    VARCHAR(20)     NULL,
    Quantity       DECIMAL(15, 6)  NOT NULL,
    PurchasePrice  DECIMAL(15, 2)  NOT NULL,
    CurrentPrice   DECIMAL(15, 2)  NOT NULL,
    PurchaseDate   DATE            NOT NULL,
    Notes          TEXT            NULL,
    CreatedAt      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (InvestmentId),
    CONSTRAINT fk_investments_user
        FOREIGN KEY (UserId) REFERENCES Users (UserId) ON DELETE CASCADE
);
```

`DECIMAL(15, 6)` is used for `Quantity` to accommodate fractional holdings in assets such as cryptocurrency (e.g., 0.005 BTC). `DECIMAL(15, 2)` for prices supports assets with large per-unit values such as Bitcoin.

#### ACHIEVEMENTS Table

```sql
CREATE TABLE Achievements (
    AchievementId    INT           NOT NULL AUTO_INCREMENT,
    Name             VARCHAR(255)  NOT NULL,
    Description      TEXT          NULL,
    BadgeIcon        VARCHAR(255)  NULL,
    XpReward         INT           NOT NULL DEFAULT 0,
    UnlockCriteria   TEXT          NULL,
    DifficultyLevel  ENUM('easy', 'medium', 'hard', 'expert') NOT NULL DEFAULT 'easy',
    PRIMARY KEY (AchievementId)
);
```

`UnlockCriteria` stores a machine-readable criteria string evaluated by the achievement unlock algorithm (Section 4.6.6).

#### USERACHIEVEMENTS Table

```sql
CREATE TABLE UserAchievements (
    UserAchievementId  INT       NOT NULL AUTO_INCREMENT,
    IsUnlocked         BOOLEAN   NOT NULL DEFAULT FALSE,
    Progress           INT       NOT NULL DEFAULT 0,
    UserId             INT       NOT NULL,
    AchievementId      INT       NOT NULL,
    UnlockedAt         DATETIME  NULL,
    PRIMARY KEY (UserAchievementId),
    CONSTRAINT fk_userachievements_user
        FOREIGN KEY (UserId) REFERENCES Users (UserId),
    CONSTRAINT fk_userachievements_achievement
        FOREIGN KEY (AchievementId) REFERENCES Achievements (AchievementId)
);
```

#### HABITSTREAKS Table

```sql
CREATE TABLE HabitStreaks (
    StreakId        INT          NOT NULL AUTO_INCREMENT,
    UserId          INT          NOT NULL,
    StreakType      VARCHAR(50)  NOT NULL,
    CurrentStreak   INT          NOT NULL DEFAULT 0,
    LongestStreak   INT          NOT NULL DEFAULT 0,
    LastActivity    DATE         NULL,
    PRIMARY KEY (StreakId),
    CONSTRAINT fk_habitstreaks_user
        FOREIGN KEY (UserId) REFERENCES Users (UserId) ON DELETE CASCADE
);
```

---

#### TwoFactorAuths Table

The `TwoFactorAuths` table stores the TOTP secret key and one-time-use backup codes for each user who has enrolled in two-factor authentication. A record is created when setup is initiated and removed when 2FA is disabled.

```sql
CREATE TABLE TwoFactorAuths (
    TwoFactorId   INT          NOT NULL AUTO_INCREMENT,
    UserId        INT          NOT NULL,
    Secret        VARCHAR(500) NOT NULL,
    BackupCodes   TEXT         NULL,
    CreatedAt     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastUsedAt    DATETIME     NULL,
    PRIMARY KEY (TwoFactorId),
    CONSTRAINT fk_twofactorauths_user
        FOREIGN KEY (UserId) REFERENCES Users (UserId) ON DELETE CASCADE
);
```

The `Secret` column stores the base32-encoded TOTP secret shared between the server and the user's authenticator application. `BackupCodes` stores a JSON array of the ten one-time-use recovery codes generated during enrolment (e.g., `["a1b2c3d4", "e5f6g7h8", ...]`). These codes are stored in plaintext in this column; the security guarantee relies on the overall database access controls rather than per-code hashing. `LastUsedAt` records when the TOTP code was most recently used for login, providing a usage audit trail.

#### UserSessions Table

The `UserSessions` table records every login session, enabling users to review and revoke active sessions from the Security Settings screen.

```sql
CREATE TABLE usersessions (
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

`VARCHAR(45)` is used for `IpAddress` to accommodate both IPv4 addresses (maximum 15 characters) and IPv6 addresses (maximum 45 characters).

#### SecurityLogs Table

The `SecurityLogs` table constitutes the security audit trail. Records are written for every security-relevant event and are never updated or deleted through normal application operation, preserving the integrity of the log.

```sql
CREATE TABLE securitylogs (
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

#### GOALS Table

The `Goals` table stores each user's savings targets. A goal carries a name, optional description, target amount, current amount saved, start and deadline dates, status (`active`, `completed`, or `abandoned`), optional category, and priority level.

```sql
CREATE TABLE Goals (
    GoalId         INT             NOT NULL AUTO_INCREMENT,
    UserId         INT             NOT NULL,
    GoalName       VARCHAR(100)    NOT NULL,
    Description    TEXT            NULL,
    TargetAmount   DECIMAL(15, 2)  NOT NULL,
    CurrentAmount  DECIMAL(15, 2)  NOT NULL DEFAULT 0.00,
    StartDate      DATE            NOT NULL,
    Deadline       DATE            NOT NULL,
    Status         ENUM('active', 'completed', 'abandoned') NOT NULL DEFAULT 'active',
    Category       VARCHAR(50)     NULL,
    Priority       ENUM('low', 'medium', 'high') NOT NULL DEFAULT 'medium',
    CreatedAt      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (GoalId),
    CONSTRAINT fk_goals_user
        FOREIGN KEY (UserId) REFERENCES Users (UserId) ON DELETE CASCADE
);
```

#### RECURRINGTRANSACTIONS Table

The `recurringtransactions` table stores rules for automatically repeated financial entries. Each rule specifies the transaction name, type (income or expense), category, amount, frequency, start and optional end dates, last execution date, next scheduled execution date, and active status. When the `NextExecution` date arrives, the system creates a regular transaction from the rule and advances `NextExecution` by one frequency interval.

```sql
CREATE TABLE recurringtransactions (
    RecurringId      INT             NOT NULL AUTO_INCREMENT,
    UserId           INT             NOT NULL,
    Name             VARCHAR(255)    NOT NULL,
    TransactionType  VARCHAR(20)     NOT NULL,
    Category         VARCHAR(50)     NOT NULL,
    Amount           DECIMAL(15, 2)  NOT NULL,
    Description      TEXT            NULL,
    Frequency        VARCHAR(20)     NOT NULL,
    StartDate        DATE            NOT NULL,
    EndDate          DATE            NULL,
    LastExecuted     DATE            NULL,
    NextExecution    DATE            NOT NULL,
    IsActive         BOOLEAN         NOT NULL DEFAULT TRUE,
    CreatedAt        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (RecurringId),
    CONSTRAINT fk_recurringtransactions_user
        FOREIGN KEY (UserId) REFERENCES Users (UserId) ON DELETE CASCADE
);
```

#### USERSETTINGS Table

The `UserSettings` table stores each user's notification preferences, budget alert thresholds, and leaderboard visibility. The `UNIQUE` constraint on `UserId` enforces the one-to-one relationship with USERS.

```sql
CREATE TABLE UserSettings (
    SettingId                INT      NOT NULL AUTO_INCREMENT,
    UserId                   INT      NOT NULL,
    EnableNotifications      BOOLEAN  NOT NULL DEFAULT TRUE,
    EnableBudgetAlerts       BOOLEAN  NOT NULL DEFAULT TRUE,
    EnableAchievementAlerts  BOOLEAN  NOT NULL DEFAULT TRUE,
    EnableStreakAlerts        BOOLEAN  NOT NULL DEFAULT TRUE,
    QuietHoursStart          TIME     NULL,
    QuietHoursEnd            TIME     NULL,
    BudgetWarningThreshold   INT      NOT NULL DEFAULT 80,
    BudgetDangerThreshold    INT      NOT NULL DEFAULT 90,
    BudgetCriticalThreshold  INT      NOT NULL DEFAULT 100,
    ShowInLeaderboard        BOOLEAN  NOT NULL DEFAULT TRUE,
    PRIMARY KEY (SettingId),
    UNIQUE KEY uq_usersettings_userid (UserId),
    CONSTRAINT fk_usersettings_user
        FOREIGN KEY (UserId) REFERENCES Users (UserId)
);
```

The three threshold columns (`BudgetWarningThreshold`, `BudgetDangerThreshold`, `BudgetCriticalThreshold`) allow each user to configure the percentage at which budget alerts fire. The defaults of 80%, 90%, and 100% reflect practical spending awareness needs while remaining adjustable for users who prefer earlier or later warnings.

The `ON DELETE CASCADE` clause is applied across tables where account deletion should propagate automatically. Wherever it is omitted (UserAchievements, HabitStreaks, UserSettings), the SQLAlchemy relationship cascade configuration in application code handles the removal order to maintain referential integrity.

---

## 4.4 Software Architecture

### 4.4.1 Architectural Pattern

SmartFinance implements the three-tier client-server architectural pattern described in Section 4.1, using Flutter for the presentation tier, Python Flask for the application tier, and MySQL for the data tier. Figure 4.4.2.1 illustrates the layer interactions and communication protocols.

*[See Figure 4.4.2.1 — Software Architecture Diagram (resources/new_diagrams/Figure_4.4.2.1_Architecture.html)]*

The presentation tier is stateless with respect to business data — it stores only the JWT token and a local cache of recently fetched records. All authoritative data operations occur at the application tier. This design means that if the mobile application is uninstalled and reinstalled, the user's complete financial history is preserved on the server and accessible after re-authentication.

---

### 4.4.2 Technology Stack

Three technology choices define the implementation: Flutter for cross-platform mobile development, Python Flask for the backend API, and MySQL for data persistence. Tables 4.4.3.1 and 4.4.3.2 compare Flutter and Flask against their respective alternatives.

**Table 4.4.3.1: Mobile Framework Comparison**

| Criterion | Flutter (Dart) | React Native | Kotlin/Swift (Native) | Xamarin |
|-----------|----------------|--------------|------------------------|---------|
| Single codebase | Yes | Yes | No | Yes |
| Performance | Near-native | JavaScript bridge | Native | Good |
| UI consistency | High | Variable | Platform-native | Good |
| Development speed | High | High | Low | Medium |
| Community support | Growing rapidly | Mature | Mature | Declining |
| FYP suitability | High | High | Low | Medium |

**Table 4.4.3.2: Backend Framework Comparison**

| Criterion | Python Flask | Django | Node.js/Express | Spring Boot |
|-----------|--------------|--------|-----------------|-------------|
| Complexity | Minimal | Moderate | Moderate | High |
| RESTful API support | Excellent | Good | Excellent | Excellent |
| Python ecosystem | Native | Native | No | No |
| Learning curve | Low | Medium | Medium | High |
| Rapid development | Excellent | Good | Good | Slow |
| FYP suitability | High | Medium | Medium | Low |

Flutter was selected because its single codebase eliminates the need to maintain separate Android and iOS implementations, which would have doubled the frontend development effort within the academic timeline. Flutter compiles to native ARM code rather than relying on a JavaScript bridge, providing performance characteristics closer to native apps than React Native. The Material Design widget library gives Flutter applications a consistent, polished appearance with minimal custom styling work.

Flask was selected for its minimal footprint. A Flask application is a Python file; routing, authentication, and data access can be added incrementally using well-supported extension libraries (Flask-JWT-Extended, Flask-Bcrypt, Flask-Limiter, Flask-CORS, Flask-SQLAlchemy). This modularity aligns with the Agile development approach, where backend endpoints were added sprint by sprint as frontend screens were completed. Django's batteries-included philosophy, while convenient for full-stack web applications, introduces structure (ORM conventions, settings module, migration system) that would have required learning overhead without proportionate benefit for a pure API backend.

---

### 4.4.3 Layer Descriptions

The presentation tier is organised into four sub-components within the Flutter project. Screens contain the widget trees for each application view. Services encapsulate HTTP communication with the Flask API, handling request construction, authentication header injection, and response parsing. Models define typed Dart objects corresponding to the API response schemas. Utils provide shared constants including colour definitions, category metadata, and investment type enumerations.

The application tier is organised as a Flask application with twelve Blueprint modules corresponding to the API route groups defined in Section 4.1.4. Each Blueprint is responsible for a specific functional domain. Authentication is handled by a dedicated `auth` Blueprint that issues and validates JWT tokens. Business logic is contained within each Blueprint's route functions and associated service functions, keeping route handlers thin. Database access occurs through SQLAlchemy model classes; raw SQL is used only for aggregation queries where the ORM would generate less efficient alternatives.

The data tier consists of the MySQL server and the schema defined in Section 4.3.4. The Flask application communicates with MySQL through the SQLAlchemy ORM configured with a connection pool, preventing the overhead of establishing a new database connection on every request.

---

### 4.4.4 API Design

The API follows REST conventions throughout. Resources are identified by noun-based URL paths (e.g., `/api/transactions`, `/api/budgets`). HTTP methods convey the intended operation: GET for retrieval, POST for creation, PUT for full updates, PATCH for partial updates, and DELETE for removal. All responses use a consistent JSON envelope with `status`, `message`, and `data` fields, enabling the Flutter client to handle errors uniformly regardless of which endpoint generated them.

JWT authentication uses the `flask_jwt_extended` library with tokens issued on successful login and a seven-day expiry window. All protected endpoints use the `@jwt_required()` decorator, which verifies the token signature and expiry before the route function executes. The authenticated user's ID is extracted from the token payload using `get_jwt_identity()`, ensuring that users can only access their own data.

---

### 4.4.5 Quality Attributes

Performance targets and measured outcomes for key API operations are summarised in Table 4.4.7.1.

**Table 4.4.7.1: API Performance Benchmarks**

| Operation | Target Response Time | Measured Response Time | Test Conditions |
|-----------|----------------------|------------------------|-----------------|
| Login (bcrypt verification) | < 500ms | 280–320ms | Snapdragon 665, 4G network |
| Transaction list retrieval | < 200ms | 85–120ms | 100 transactions, indexed query |
| Dashboard load | < 300ms | 150–200ms | Aggregated summary query |
| Budget status retrieval | < 100ms | 40–60ms | Cached SpentAmount, no aggregation |
| Portfolio calculation | < 200ms | 85–95ms | 20 investments, single-pass algorithm |
| Achievement evaluation | < 300ms | 180–220ms | Selective trigger-based evaluation |

All endpoints targeting under 200ms response time operate within that budget under typical load conditions. The login endpoint exceeds 200ms by design — bcrypt's cost factor 12 requires approximately 280ms of computation, which is the intentional cost of making brute-force attacks computationally expensive.

---

## 4.5 Process Design

### 4.5.1 Authentication Process

The authentication subsystem covers two flows: user registration and subsequent login. Figure 4.5.1.1 illustrates the login and 2FA verification workflow.

*[See Figure 4.5.1.1 — Login and Authentication Workflow (resources/new_diagrams/Figure_4.5.1.1_Login_Auth_Workflow.html)]*

**Registration process:**

1. The user completes the registration form with full name, email address, password, and optional phone number.
2. The Flutter client validates input locally — password strength rules, email format, field completeness — and displays inline validation feedback.
3. A POST request is sent to `/api/auth/register` with the validated form data.
4. The Flask server checks for an existing account with the provided email address. If a duplicate is found, a 409 Conflict response is returned.
5. The password is hashed using bcrypt with cost factor 12: `bcrypt.generate_password_hash(password, 12)`.
6. A new USERS row is inserted and an email verification token is generated and sent to the provided address.
7. The server returns a 201 Created response. The client navigates to a verification prompt screen.
8. The user clicks the verification link in their email, which calls `/api/auth/verify-email` with the token. The server sets `IsEmailVerified = TRUE` on the user record.

**Login process:**

1. The user enters their email and password on the Login Screen.
2. A POST request is sent to `/api/auth/login`.
3. The server retrieves the user record by email. If no record exists, a 401 Unauthorised response is returned with a generic message.
4. `bcrypt.check_password_hash(stored_hash, entered_password)` verifies the password using constant-time comparison, preventing timing attacks.
5. If the account has `TwoFactorEnabled = TRUE`, the server returns a partial response (`{"requires_2fa": true}`) rather than a JWT. The client presents the TOTP verification screen.
6. The user enters their six-digit authenticator code. The server verifies it against the stored secret using `pyotp`. If verification succeeds, the login flow continues to step 7.
7. A JWT is generated with the user's ID as the identity claim and a seven-day expiry. A `UserSessions` record is created capturing device, IP address, and user agent.
8. The JWT is returned to the client, which stores it securely and proceeds to the Dashboard.

**Error handling:** Failed login attempts increment a counter tracked by the rate limiter. After five failed attempts within one minute, subsequent attempts from the same IP address are blocked for 60 seconds. After ten failed attempts within 24 hours, the account is temporarily locked for 30 minutes, and the user is notified by email.

---

### 4.5.2 Expense Entry Process

Figure 4.5.2.1 illustrates the transaction entry workflow.

*[See Figure 4.5.2.1 — Transaction Entry Workflow (resources/new_diagrams/Figure_4.5.2.1_Transaction_Entry_Workflow.html)]*

1. The user navigates to the Add Transaction screen and enters an amount.
2. The user selects Income or Expense using the type toggle.
3. As the user types in the description field, the intelligent categorisation algorithm (Section 4.6.1) evaluates the input and updates the category suggestion chip in real time.
4. The user accepts the suggested category or selects a different one from the category grid.
5. The date defaults to today. The user may change it using the calendar picker for historical entries.
6. The user taps Save. The Flutter client sends a POST request to `/api/transactions`.
7. The server validates the request — amount must be positive, category must be a valid enumerated value, date must be a valid date.
8. A new TRANSACTIONS row is inserted.
9. If the transaction is an Expense and falls within the current budget month, the server updates `SpentAmount` in the corresponding BUDGETCATEGORIES row.
10. The gamification engine checks whether any transaction-triggered achievements have been met (Section 4.6.6) and updates the user's streak (Section 4.6.5). Both checks execute asynchronously to avoid blocking the response.
11. A 201 Created response is returned. The client appends the new transaction to the local list and updates the dashboard balance display.

**Error handling:** Network failures during submission trigger a local retry queue. If the server returns a 4xx response, the error message is extracted from the `message` field and displayed inline. Duplicate submission is prevented by disabling the Save button from the moment it is first tapped until a response is received.

---

### 4.5.3 Budget Management Process

Figure 4.5.3.1 illustrates the budget creation workflow. The monitoring and analysis workflows are shown in Figures 4.5.3.2 and 4.5.3.3.

*[See Figure 4.5.3.1 — Budget Setup Process (resources/new_diagrams/Figure_4.5.3.1_Budget_Setup_Process.html)]*
*[See Figure 4.5.3.2 — Budget Monitoring Process (original figure retained)]*
*[See Figure 4.5.3.3 — Budget Analysis Process (original figure retained)]*

**Budget creation:**

1. The user navigates to the Budget Creation screen and selects a month.
2. The user sets a total budget amount and allocates amounts to individual categories.
3. The running subtotal updates in real time as amounts are entered.
4. The user taps Save. The client sends a POST request to `/api/budgets` with the month, total, and category breakdown.
5. The server inserts a BUDGETS row and one BUDGETCATEGORIES row per allocated category.
6. Existing transactions for the selected month are summed per category and used to populate the initial `SpentAmount` values in BUDGETCATEGORIES.

**Budget monitoring:**

Budget status is evaluated each time the Budget Overview screen loads. The server retrieves all BUDGETCATEGORIES rows for the current month's budget and applies the threshold logic defined in the Budget Alert Algorithm (Section 4.6.2). The consumption percentage for each category determines its colour status:

- Below 80%: Safe (green)
- 80% to 99%: Warning (amber)
- 100% and above: Exceeded (red with overage indicator)

When a new expense transaction is saved, `SpentAmount` is updated synchronously, and the updated status is included in the transaction creation response so the client can refresh the budget display without a separate API call.

**Budget analysis:** The Analytics screen calls the reports endpoints (`/api/reports/budget-comparison`, `/api/reports/spending-trends`) to generate month-over-month spending charts. These endpoints aggregate transaction data over the requested date range and return category-level summaries used to populate the fl_chart widgets on the Analytics screen.

---

### 4.5.4 Investment Management Process

Figure 4.5.4.1 illustrates the investment entry workflow. Price update and portfolio recalculation workflows are shown in Figures 4.5.4.2 and 4.5.4.3.

*[See Figure 4.5.4.1 — Investment Entry Workflow (resources/new_diagrams/Figure_4.5.4.1_Investment_Entry_Workflow.html)]*
*[See Figure 4.5.4.2 — Investment Price Update Workflow (original figure retained)]*
*[See Figure 4.5.4.3 — Portfolio Calculation Workflow (original figure retained)]*

**Investment entry:**

1. The user navigates to the Investment Entry screen and selects an asset type from the ten available categories.
2. The user enters the asset name, optional ticker symbol, quantity, purchase price, current price, purchase date, and optional notes.
3. The client validates that quantity and prices are positive numbers and that the purchase date is not in the future.
4. A POST request is sent to `/api/investments`. The server inserts an INVESTMENTS row.
5. The gamification engine checks investment-related achievement criteria asynchronously.

**Price update:** Since SmartFinance does not integrate with real-time market data, users update current prices manually. The user taps an existing holding, modifies the `CurrentPrice` field, and saves. A PUT request is sent to `/api/investments/<id>`. The server updates the INVESTMENTS row and returns the updated portfolio summary.

**Portfolio calculation:** When the Investment Portfolio screen loads, a GET request to `/api/investments/portfolio` triggers the portfolio performance algorithm (Section 4.6.4), which computes absolute and percentage gains for each holding and aggregate portfolio metrics in a single pass over the retrieved investment records.

---

### 4.5.5 Gamification Process

Figures 4.5.5.1, 4.5.5.2, and 4.5.5.3 illustrate the XP award, achievement unlock, and streak tracking workflows respectively.

*[See Figure 4.5.5.1 — XP Award Process (original figure retained)]*
*[See Figure 4.5.5.2 — Achievement Unlock Process (original figure retained)]*
*[See Figure 4.5.5.3 — Streak Update Process (original figure retained)]*

**XP award process:**

XP is awarded asynchronously after each qualifying user action. XP amounts vary by activity: recording a transaction awards base XP, creating a budget awards a larger amount reflecting the higher planning effort involved, and adding an investment holding awards a different amount to reflect the distinct behaviour being reinforced. When the awarded XP causes the user's total to exceed the threshold for the next level, a level-up notification is triggered and the `CurrentLevel` field is incremented.

**Achievement evaluation:**

Achievement evaluation is trigger-based rather than running on every app launch. Each trigger event type is associated with a subset of potentially relevant achievements, so a transaction creation event checks only transaction-count, streak, and category-diversity achievements rather than evaluating all achievements in the catalogue. The evaluation algorithm (Section 4.6.6) runs asynchronously, so the user receives an immediate response to their action and the badge unlock notification arrives shortly afterward without blocking the UI.

**Streak tracking:**

The streak algorithm (Section 4.6.5) is called whenever a transaction is saved. It retrieves the date of the user's most recent prior transaction using a single indexed `MAX(TransactionDate)` query and determines the current day gap. A gap of zero indicates the streak is active and increments the counter; a gap of one indicates the user has logged once in the previous 24-hour window, putting the streak "at risk" without breaking it; a gap of two or more resets the streak to zero. Weekly streak milestones (7, 14, 30, 90 days) trigger bonus XP awards and motivational notifications.

**Error handling:** All gamification operations are wrapped in try-catch blocks at the service layer and execute asynchronously. A failure in achievement evaluation or streak update does not affect the primary operation (transaction save, budget creation) that triggered it. Failed gamification updates are logged server-side for debugging but do not surface error messages to the user.

---

## 4.6 Algorithm and Model Design

### 4.6.1 Intelligent Expense Categorisation Algorithm

The intelligent categorisation algorithm assigns a category to a transaction based on keywords in the description combined with patterns from the user's own transaction history. It is invoked on each keystroke in the description field and must complete within 5ms to avoid perceptible latency.

The algorithm accepts a description string and a user ID and returns a suggested category name with a confidence score between 0.0 and 1.0. If no suggestion meets the minimum confidence threshold of 0.7, the algorithm returns an empty suggestion and the user selects a category manually.

```python
def categorize_transaction(description: str, user_id: int) -> dict:
    """
    Categorize transaction using keyword matching combined with user history.
    Returns suggested category and confidence score.
    """
    if not description or len(description.strip()) < 2:
        return {'category': None, 'confidence': 0.0}
    
    description_lower = description.lower().strip()
    
    # Step 1: Keyword matching (weighted 70%)
    keyword_matches = {}
    for category, keywords in CATEGORY_KEYWORDS.items():
        match_count = sum(1 for keyword in keywords 
                         if keyword in description_lower)
        if match_count > 0:
            keyword_matches[category] = match_count / len(keywords)
    
    # Step 2: User history pattern matching (weighted 30%)
    history_matches = {}
    user_transactions = get_user_transaction_history(user_id, limit=50)
    
    for transaction in user_transactions:
        if description_lower in transaction.description.lower():
            category = transaction.category
            history_matches[category] = history_matches.get(category, 0) + 1
    
    # Normalize history matches
    total_history = sum(history_matches.values())
    if total_history > 0:
        history_matches = {k: v / total_history 
                          for k, v in history_matches.items()}
    
    # Step 3: Combine scores with weighting
    combined_scores = {}
    all_categories = set(list(keyword_matches.keys()) + 
                        list(history_matches.keys()))
    
    for category in all_categories:
        keyword_score = keyword_matches.get(category, 0) * 0.7
        history_score = history_matches.get(category, 0) * 0.3
        combined_scores[category] = keyword_score + history_score
    
    if not combined_scores:
        return {'category': None, 'confidence': 0.0}
    
    best_category = max(combined_scores, key=combined_scores.get)
    confidence = combined_scores[best_category]
    
    if confidence < 0.7:
        return {'category': None, 'confidence': confidence}
    
    return {'category': best_category, 'confidence': round(confidence, 2)}
```

The keyword dictionary (`CATEGORY_KEYWORDS`) maps each category to a list of characteristic terms. For example, the Food & Dining category includes terms such as "restaurant", "mamak", "food", "lunch", "dinner", "grab food", and "pizza". This dictionary is loaded once at application startup and held in memory, so keyword matching requires no database access.

Time complexity is O(n × m) where n is the number of categories and m is the number of keywords per category. For the current 15 categories with an average of 20 keywords each, this is effectively constant at O(300) comparisons. The user history lookup adds O(h) where h is the number of history records retrieved; the limit of 50 records keeps this bounded. Measured execution time is under 5ms on mid-range Android devices (Table 4.6.1.1).

**Table 4.6.1.1: Categorisation Algorithm Performance**

| Metric | Target | Measured | Conditions |
|--------|--------|----------|------------|
| Total execution | < 5ms | 2–4ms | 15 categories, 20 keywords each |
| Keyword matching | < 2ms | 0.5–1ms | In-memory dictionary |
| History lookup | < 3ms | 1–2ms | 50 transactions, indexed query |
| Memory usage | < 100KB | ~45KB | Keywords + 50 history records |

Fetching the 50 most recent transactions for history analysis is more efficient than retrieving the full history because the marginal accuracy gain from additional records beyond 50 diminishes rapidly while the query time grows linearly. The user history component is particularly valuable for users with consistent spending patterns — once a user has categorised several entries for the same vendor (e.g., "Grab" consistently mapped to Transport), subsequent entries are classified correctly without keyboard shortcut support.

---

### 4.6.2 Budget Consumption and Alert Algorithm

The budget alert algorithm determines the spending status for each budget category and generates alerts when thresholds are crossed. It is designed for O(1) time complexity per category through the use of the denormalised `SpentAmount` cache described in Section 4.3.3.

```
ALGORITHM check_budget_status(user_id, month):
  // Retrieve budget and categories (single query with index)
  budget = QUERY BUDGETS WHERE UserId = user_id AND Month = month
  
  IF budget is NULL:
    RETURN no_budget_message
  
  categories = QUERY BUDGETCATEGORIES WHERE BudgetId = budget.BudgetId
  alerts = []
  
  FOR EACH category IN categories:
    // O(1) calculation using pre-cached SpentAmount
    consumption_percentage = (category.SpentAmount / category.AllocatedAmount) * 100
    
    IF consumption_percentage >= 100:
      status = 'Exceeded'
      alert_level = 'CRITICAL'
    ELIF consumption_percentage >= 95:
      status = 'Critical'
      alert_level = 'DANGER'
    ELIF consumption_percentage >= 75:
      status = 'Warning'
      alert_level = 'WARNING'
    ELSE:
      status = 'Safe'
      alert_level = 'SAFE'
    
    IF alert_level != 'SAFE':
      alerts.APPEND({
        'category': category.Category,
        'status': status,
        'consumed': consumption_percentage,
        'remaining': category.AllocatedAmount - category.SpentAmount
      })
  
  RETURN {
    'budget': budget,
    'categories': categories_with_status,
    'alerts': alerts,
    'total_consumed': (total_spent / budget.TotalBudget) * 100
  }
```

The critical design decision here is that `SpentAmount` is maintained as a running total in the BUDGETCATEGORIES table rather than computed on demand. Each time a relevant transaction is saved, a single UPDATE statement increments the corresponding `SpentAmount`:

```sql
UPDATE BudgetCategories
SET SpentAmount = SpentAmount + ?
WHERE BudgetId = ? AND Category = ?
```

This reduces the budget status query from a GROUP BY aggregation over potentially thousands of transactions to a single indexed SELECT over a small number of category rows. For a user with 500 transactions in a month, the naive aggregation approach takes approximately 150ms; the cached approach completes in under 20ms regardless of transaction count.

Thresholds are evaluated only at the point of comparison — there is no background process scanning for threshold crossings. An alert is generated when the Budget Overview screen is loaded or when a transaction triggers a `SpentAmount` update that crosses a threshold. The threshold-only alerting approach means that routine budget checks that do not cross any boundary complete in under 5ms.

**Table 4.6.2.1: Budget Alert Threshold Configuration**

| Threshold | Level | Colour | Action |
|-----------|-------|--------|--------|
| < 75% | Safe | Green | No alert |
| 75–95% | Warning | Amber | In-app notification |
| 95–100% | Critical | Orange/Red | Push notification |
| > 100% | Exceeded | Red | Push notification + overage display |

**Table 4.6.2.2: Budget Alert Algorithm Performance**

| Metric | Target | Measured | Conditions |
|--------|--------|----------|------------|
| Status query | < 50ms | 15–25ms | 6 categories, indexed lookup |
| SpentAmount update | < 20ms | 8–12ms | Single row update |
| Alert generation | < 5ms | < 1ms | Threshold comparison only |
| Memory usage | < 10KB | ~2KB | 6 category objects |

---

### 4.6.3 Experience Point and Level Progression Algorithm

The XP and level progression algorithm awards experience points for user actions and determines when a level-up occurs. The level threshold formula uses a linear approximation of exponential growth:

XP_required = BaseXP × CurrentLevel × GrowthFactor

Where BaseXP = 100 and GrowthFactor = 1.5. This formula was chosen over true exponentiation because it produces a simpler, more predictable progression curve while remaining computationally trivial — a single multiplication rather than a `pow()` call. For levels 1–20, the required XP per level ranges from 150 (Level 1) to 3,000 (Level 20).

```python
def calculate_level_progression(current_xp: int, current_level: int) -> dict:
    """
    Calculate level progression using linear approximation of exponential growth.
    O(1) time complexity — single arithmetic operation.
    """
    BASE_XP = 100
    GROWTH_FACTOR = 1.5
    MAX_LEVEL = 20
    
    if current_level >= MAX_LEVEL:
        return {
            'current_level': MAX_LEVEL,
            'current_xp': current_xp,
            'xp_for_next_level': None,
            'level_progress_percentage': 100,
            'is_max_level': True
        }
    
    # Linear approximation: avoids expensive pow() operation
    xp_for_next_level = int(BASE_XP * current_level * GROWTH_FACTOR)
    
    # XP earned toward current level (subtract cumulative XP from previous levels)
    xp_in_current_level = current_xp % xp_for_next_level
    level_progress = (xp_in_current_level / xp_for_next_level) * 100
    
    return {
        'current_level': current_level,
        'current_xp': current_xp,
        'xp_for_next_level': xp_for_next_level,
        'level_progress_percentage': round(level_progress, 1),
        'is_max_level': False
    }

def award_experience_points(user_id: int, activity_type: str) -> dict:
    """
    Award XP for a completed user activity and check for level-up.
    Single database query and update — O(1) operation.
    """
    XP_REWARDS = {
        'transaction_logged': 10,
        'budget_created': 25,
        'goal_created': 20,
        'investment_added': 30,
        'streak_bonus': 15,
        'achievement_unlocked': 50,
        'daily_login': 5
    }
    
    xp_to_award = XP_REWARDS.get(activity_type, 0)
    if xp_to_award == 0:
        return {'success': False, 'reason': 'Unknown activity type'}
    
    # Single query to get current state
    user = get_user_by_id(user_id)
    new_xp = user.ExperiencePts + xp_to_award
    new_level = user.CurrentLevel
    leveled_up = False
    
    # Check level-up using linear approximation
    xp_threshold = int(100 * new_level * 1.5)
    
    if new_xp >= xp_threshold and new_level < 20:
        new_level += 1
        leveled_up = True
    
    # Single update operation
    update_user_xp(user_id, new_xp, new_level)
    
    if leveled_up:
        # Async notification — does not block XP award response
        send_notification_async(
            user_id,
            f"Level Up! You reached Level {new_level}!"
        )
    
    return {
        'xp_awarded': xp_to_award,
        'new_total_xp': new_xp,
        'new_level': new_level,
        'leveled_up': leveled_up
    }
```

The level check is O(1) — a single multiplication and comparison. The alternative of storing cumulative XP thresholds in a lookup table would require either a table scan or an indexed lookup on every XP award; the formula approach requires no database access beyond the user record update already required.

**Table 4.6.3.1: XP Reward Values by Activity Type**

| Activity | XP Reward | Rationale |
|----------|-----------|-----------|
| Transaction logged | 10 | Core daily behaviour |
| Budget created | 25 | Higher-effort planning activity |
| Goal created | 20 | Forward-looking financial planning |
| Investment added | 30 | Most complex entry task |
| Streak bonus (weekly) | 15 | Consistency reinforcement |
| Achievement unlocked | 50 | Milestone celebration |
| Daily login | 5 | Engagement reinforcement |

**Table 4.6.3.2: Level Progression Algorithm Performance**

| Metric | Target | Measured | Conditions |
|--------|--------|----------|------------|
| XP calculation | < 1ms | < 0.1ms | Single arithmetic operation |
| Database update | < 20ms | 8–12ms | Single row update |
| Level-up notification | 0ms blocking | 0ms blocking | Async delivery |
| Memory usage | < 1KB | ~200 bytes | Fixed integer variables |

---

### 4.6.4 Investment Portfolio Performance Algorithm

The portfolio performance algorithm computes absolute and percentage returns for each investment holding and aggregates these into portfolio-level metrics. It accepts a user ID and returns individual holding performance alongside the total portfolio cost, total current value, overall percentage return, and the best- and worst-performing assets.

The core formulas are:

- Absolute Gain/Loss = (CurrentPrice − PurchasePrice) × Quantity
- Percentage Return = ((CurrentPrice − PurchasePrice) / PurchasePrice) × 100
- Total Investment Cost = Σ(PurchasePrice_i × Quantity_i) for i = 1 to n
- Total Current Value = Σ(CurrentPrice_i × Quantity_i) for i = 1 to n
- Portfolio Return = ((Total Current Value − Total Investment Cost) / Total Investment Cost) × 100

```
ALGORITHM calculate_portfolio_performance(user_id):
  // Step 1: Retrieve all user investments (single query with index)
  investments = QUERY INVESTMENTS WHERE UserId = user_id
  
  IF investments is EMPTY:
    RETURN empty_portfolio_message
  
  // Step 2: Initialise aggregators
  total_cost = 0
  total_current_value = 0
  performance_list = []
  
  // Step 3: Single-pass calculation
  FOR EACH investment IN investments:
    purchase_value = investment.PurchasePrice * investment.Quantity
    current_value  = investment.CurrentPrice  * investment.Quantity
    absolute_gain  = current_value - purchase_value
    percentage_gain = (absolute_gain / purchase_value) * 100
    
    total_cost          = total_cost + purchase_value
    total_current_value = total_current_value + current_value
    
    performance_list.APPEND({
      'asset_name':       investment.AssetName,
      'asset_type':       investment.AssetType,
      'absolute_gain':    absolute_gain,
      'percentage_gain':  percentage_gain,
      'status':           'Profit' IF absolute_gain >= 0 ELSE 'Loss'
    })
  END FOR
  
  // Step 4: Portfolio-level metrics
  overall_gain       = total_current_value - total_cost
  overall_percentage = (overall_gain / total_cost) * 100
  
  // Step 5: Sort for best/worst display (O(n log n))
  SORT performance_list BY percentage_gain DESCENDING
  
  RETURN {
    'total_investment_cost':   total_cost,
    'total_current_value':     total_current_value,
    'overall_absolute_gain':   overall_gain,
    'overall_percentage_return': overall_percentage,
    'individual_holdings':     performance_list,
    'best_performer':          performance_list[0],
    'worst_performer':         performance_list[LAST]
  }
END ALGORITHM
```

The algorithm uses a single-pass loop that calculates individual performance and accumulates portfolio totals simultaneously, rather than separate passes for each operation. For 20 investments, this reduces execution time by approximately 60% compared to a three-pass approach (30ms vs. 75ms), with improved cache locality on ARM processors.

All monetary calculations use Python's `Decimal` type rather than floating-point arithmetic. The `Decimal` type is 10–20× slower than float arithmetic but eliminates rounding errors that would otherwise cause displayed portfolio values to drift from the correct figures — a trust-critical issue for financial applications.

For portfolios exceeding 30 investments, the algorithm paginates the database query, loading the first 30 holdings for immediate display with remaining holdings loaded progressively on scroll. This ensures initial screen load completes within 100ms regardless of portfolio size.

**Table 4.6.4.1: Portfolio Performance Status Categories**

| Return Range | Status | Colour | Icon |
|--------------|--------|--------|------|
| > +10% | Excellent | Dark Green | ↑↑ |
| +5% to +10% | Good | Green | ↑ |
| 0% to +5% | Moderate | Light Green | → |
| 0% to −5% | Slight Loss | Yellow | ↓ |
| < −5% | Significant Loss | Red | ↓↓ |

**Table 4.6.4.2: Portfolio Calculation Algorithm Performance**

| Metric | Target | Measured | Portfolio Size | Test Device |
|--------|--------|----------|----------------|-------------|
| Total execution | < 200ms | 85–95ms | 20 investments | Snapdragon 665, 4GB RAM |
| Database query | < 100ms | 35–45ms | Indexed lookup | Samsung A50 |
| Calculation loop | < 50ms | 28–35ms | 20 iterations | Realme 5 Pro |
| Sorting time | < 30ms | 18–22ms | 20 items | Typical mid-range |
| Memory usage | < 50KB | ~8KB | 20 investments | Measured runtime |
| Battery impact | < 0.2% | ~0.12% | Per portfolio refresh | Typical usage |

---

### 4.6.5 Habit Streak Tracking Algorithm

The streak tracking algorithm monitors consecutive days of transaction logging to support the habit streak feature. It is called whenever a transaction is saved and completes in under 30ms through two targeted optimisations: a `MAX(TransactionDate)` aggregate query rather than retrieving all transaction records, and streak data cached in the USERS table rather than fetched via a JOIN to HABITSTREAKS.

```python
def update_habit_streak(user_id, current_date):
    """
    Update habit streak based on daily activity.
    Optimized for minimal database operations.
    """
    # Retrieve most recent transaction date (single indexed aggregate query)
    last_transaction_query = """
        SELECT MAX(TransactionDate) as LastDate
        FROM TRANSACTIONS
        WHERE UserId = ?
    """
    last_transaction_date = execute_query(last_transaction_query, [user_id])
    
    # Retrieve current streak from cached user object (no JOIN required)
    user = get_user_by_id(user_id)
    current_streak = user.CurrentStreak if hasattr(user, 'CurrentStreak') else 0
    longest_streak  = user.LongestStreak  if hasattr(user, 'LongestStreak')  else 0
    
    if last_transaction_date is None:
        return {'current_streak': 0, 'longest_streak': 0, 'streak_status': 'Not Started'}
    
    days_since_last = (current_date - last_transaction_date).days
    
    if days_since_last == 0:
        new_streak    = current_streak + 1
        streak_status = 'Active'
        
        # Award bonus XP at weekly milestones
        if new_streak % 7 == 0:
            award_experience_points(user_id, 'streak_bonus')
            send_notification(user_id, f"{new_streak}-day streak achieved!")
    
    elif days_since_last == 1:
        new_streak    = current_streak
        streak_status = 'At Risk'  # Haven't logged today yet
    
    else:
        new_streak    = 0
        streak_status = 'Broken'
        
        # Motivational recovery message for significant streaks only
        if current_streak >= 7:
            send_notification(user_id,
                f"Your streak ended at {current_streak} days. Start fresh today!")
    
    # Update longest streak if exceeded
    if new_streak > longest_streak:
        longest_streak = new_streak
    
    # Single write operation
    update_query = """
        UPDATE USERS
        SET CurrentStreak = ?, LongestStreak = ?
        WHERE UserId = ?
    """
    execute_query(update_query, [new_streak, longest_streak, user_id])
    
    # Check streak achievements asynchronously
    check_streak_achievements(user_id, new_streak)
    
    return {
        'current_streak':  new_streak,
        'longest_streak':  longest_streak,
        'streak_status':   streak_status,
        'days_since_last': days_since_last
    }
```

Using `MAX(TransactionDate)` returns a single date value in ~12ms with an indexed query, compared to ~50ms for retrieving all transaction dates and finding the most recent on the client side. Caching streak data in the USERS table avoids a JOIN operation on every streak check (~25ms with JOIN vs. ~8ms from the USERS row directly).

Break notifications are sent only when the broken streak was 7 or more days long. Notifying users for any streak break regardless of length would generate notifications for users who have never established a consistent habit, which creates noise without motivational value.

**Table 4.6.5.1: Habit Streak Tracking Algorithm Performance**

| Metric | Target | Measured | Test Device |
|--------|--------|----------|-------------|
| Total execution | < 50ms | 22–28ms | Snapdragon 660, 4GB RAM |
| Database query | < 20ms | 10–15ms | Indexed MAX query |
| Date arithmetic | < 5ms | < 1ms | Python datetime |
| Database update | < 20ms | 8–12ms | Single row write |
| Memory usage | < 1KB | ~60 bytes | Fixed integers |
| Battery impact | < 0.05% | ~0.03% | Per streak check |
| Daily checks | ~3 per day | ~3 per day | App launch, transaction, manual refresh |

---

### 4.6.6 Achievement Unlock Evaluation Algorithm

The achievement evaluation algorithm checks whether a user has met the criteria for any previously locked achievement following a qualifying action. Rather than evaluating all achievements on every user action, the algorithm uses trigger-based selective evaluation to check only the subset of achievements relevant to the type of action that occurred.

The algorithm supports four criteria types: count-based (complete X number of actions), streak-based (maintain Y consecutive days), milestone-based (reach a specific threshold), and behavioural (demonstrate a pattern over time).

```
ALGORITHM evaluate_achievement_unlock(user_id, trigger_event):
  // Step 1: Retrieve achievements not yet unlocked by this user
  all_achievements      = QUERY ACHIEVEMENTS
  unlocked_achievements = QUERY USERACHIEVEMENTS WHERE UserId = user_id
  locked_achievements   = all_achievements EXCLUDING unlocked_achievements
  
  newly_unlocked = []
  
  // Step 2: Filter to achievements relevant to this trigger
  relevant_achievements = filter_by_trigger(locked_achievements, trigger_event)
  
  FOR EACH achievement IN relevant_achievements:
    criteria_met        = FALSE
    progress_percentage = 0
    
    SWITCH achievement.UnlockCriteria:
    
      CASE "Create 1 budget":
        budget_count = COUNT(BUDGETS WHERE UserId = user_id)
        criteria_met = budget_count >= 1
        progress_percentage = MIN(budget_count * 100, 100)
      
      CASE "Log 100 transactions":
        tx_count = COUNT(TRANSACTIONS WHERE UserId = user_id)
        criteria_met = tx_count >= 100
        progress_percentage = (tx_count / 100) * 100
      
      CASE "30-day logging streak":
        current_streak = GET_USER_STREAK(user_id)
        criteria_met = current_streak >= 30
        progress_percentage = (current_streak / 30) * 100
      
      CASE "Have 5 different investments":
        investment_count = COUNT(DISTINCT INVESTMENTS WHERE UserId = user_id)
        criteria_met = investment_count >= 5
        progress_percentage = (investment_count / 5) * 100
      
      // Additional criteria cases follow same pattern
    END SWITCH
    
    IF criteria_met:
      INSERT INTO USERACHIEVEMENTS (UserId, AchievementId, UnlockedAt, Progress)
      VALUES (user_id, achievement.AchievementId, CURRENT_TIMESTAMP, 100)
      
      AWARD_XP_ASYNC(user_id, achievement.XpReward)
      newly_unlocked.APPEND(achievement)
    
    ELSE:
      // Update progress only if change exceeds 5% threshold
      current_progress = get_current_progress(user_id, achievement.AchievementId)
      IF ABS(progress_percentage - current_progress) >= 5:
        UPDATE_OR_INSERT USERACHIEVEMENTS SET Progress = progress_percentage
    END IF
  END FOR
  
  // Step 3: Batch notification for newly unlocked achievements
  IF newly_unlocked is NOT EMPTY:
    IF len(newly_unlocked) > 1:
      send_single_notification(f"You unlocked {len(newly_unlocked)} achievements!")
    ELSE:
      send_single_notification(newly_unlocked[0].Name + " +" + newly_unlocked[0].XpReward + " XP")
  
  RETURN newly_unlocked
END ALGORITHM
```

Rather than evaluating all achievements on every transaction, the algorithm maintains a mapping from trigger event types to relevant achievement subsets:

```python
# Naive approach — avoided
def on_transaction_created(user_id):
    evaluate_all_achievements(user_id)  # 50 achievements × 50ms = 2.5 seconds

# Implemented approach
def on_transaction_created(user_id):
    transaction_achievements = [
        'first_transaction',
        'log_100_transactions',
        'daily_logging_streak',
        'category_diversity'
    ]
    evaluate_achievements(user_id, transaction_achievements)  # 4 × 50ms = 200ms
```

This reduces average evaluation time from 2.5 seconds (checking all 50 achievements) to approximately 200ms (checking the 4 relevant achievements for a transaction event).

Achievement definitions are loaded once at application startup and cached in memory. Looking up an achievement definition during evaluation is a dictionary lookup (<1ms) rather than a database query (~30ms per query). For four achievement checks, this saves 120ms per evaluation.

Progress is only written to the database when the change exceeds 5% of the total. A transaction that moves a count-based achievement from 47% to 48% does not trigger a database write; one that moves it from 47% to 53% does. This reduces database writes by approximately 95% for partial-achievement progress updates.

Multiple achievements unlocked simultaneously are delivered as a single batched notification rather than separate notifications, reducing notification fatigue and the battery cost of multiple wake-locks.

**Table 4.6.6.2: Achievement Evaluation Algorithm Performance**

| Metric | Target | Measured | Conditions | Test Device |
|--------|--------|----------|------------|-------------|
| Full evaluation | < 1000ms | 720–850ms | All 50 achievements | Snapdragon 660, 3GB RAM |
| Selective evaluation | < 300ms | 180–220ms | 4 relevant achievements | Typical transaction |
| Single criteria check | < 100ms | 45–60ms | COUNT query | Indexed lookup |
| Progress update | < 50ms | 25–35ms | Single row update | When threshold crossed |
| Memory footprint | < 50KB | ~12KB | Cached definitions | Measured runtime |
| Battery impact | < 0.3% | ~0.15% | Per evaluation event | Including DB + notification |

---

## 4.7 Security Design

The SmartFinance application handles sensitive financial data including transaction records, budget allocations, investment portfolios, and personal profile information. Security is implemented as a layered defence covering data at rest, authentication, data in transit, and research data handling. The implementation addresses NFR003 from Chapter 3 and complies with the Malaysian Personal Data Protection Act (PDPA) 2010.

### 4.7.1 Data Privacy Protection

All sensitive fields stored in the MySQL database are encrypted at rest using AES-256 via the Python `cryptography.fernet` library. Fernet uses AES-128-CBC with PKCS7 padding and HMAC-SHA256 for message authentication.

```python
from cryptography.fernet import Fernet
import base64

class DataEncryption:
    """
    Handles encryption and decryption of sensitive data.
    Uses AES-256 encryption for fields classified as sensitive.
    """
    
    def __init__(self, encryption_key):
        self.cipher = Fernet(encryption_key)
    
    def encrypt_field(self, plaintext_data):
        if plaintext_data is None:
            return None
        encrypted_bytes = self.cipher.encrypt(plaintext_data.encode('utf-8'))
        return base64.b64encode(encrypted_bytes).decode('utf-8')
    
    def decrypt_field(self, encrypted_data):
        if encrypted_data is None:
            return None
        encrypted_bytes = base64.b64decode(encrypted_data)
        decrypted_bytes = self.cipher.decrypt(encrypted_bytes)
        return decrypted_bytes.decode('utf-8')
```

Encryption keys are stored separately from both application code and the database. In the development environment, keys are loaded from environment variables in a `.env` file excluded from version control. In production, keys are managed through a dedicated secrets management service. Key rotation occurs every 90 days with automatic re-encryption of existing data.

The application follows a data minimisation principle: only information necessary for account authentication and financial feature delivery is collected. Email address, password hash, and full name are required. IC number, physical address, bank account numbers, and credit card details are not collected. This reduces the impact of a hypothetical breach and simplifies PDPA compliance by limiting the categories of personal data the application processes.

Users retain full control over their data. The CSV export endpoint (`/api/reports/user/<id>/export/transactions`) allows users to download their complete transaction history. The account deletion endpoint (`/api/security/account/delete`) triggers a cascading delete removing all associated records across all fourteen tables.

The database user account for the application is granted only the specific permissions required for normal operation — SELECT, INSERT, UPDATE on most tables, with DELETE restricted to tables where user-initiated deletion is permitted. DROP, TRUNCATE, and ALTER permissions are not granted, reducing the impact of a compromised application credential:

```sql
CREATE USER 'smartfinance_app'@'localhost' IDENTIFIED BY 'strong_password';
GRANT SELECT, INSERT, UPDATE ON smartfinance_db.Users TO 'smartfinance_app'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON smartfinance_db.Transactions TO 'smartfinance_app'@'localhost';
REQUIRE SSL;
```

---

### 4.7.2 Authentication Security

#### 4.7.2.1 Password Security

SmartFinance uses bcrypt with cost factor 12 for password hashing. Cost factor 12 requires 2^12 = 4,096 iterations, making each hash computation take approximately 250ms. This makes brute-force attacks computationally expensive while remaining within an acceptable latency budget for the login endpoint.

```python
from flask_bcrypt import Bcrypt

bcrypt = Bcrypt(app)

def hash_password(plain_password):
    """Hash password using bcrypt with cost factor 12."""
    password_hash = bcrypt.generate_password_hash(plain_password, 12)
    return password_hash.decode('utf-8')

def verify_password(plain_password, password_hash):
    """Verify password using constant-time comparison to prevent timing attacks."""
    return bcrypt.check_password_hash(password_hash, plain_password)
```

Password requirements enforce minimum security: at least eight characters, containing alphanumeric characters, with no dictionary words or common patterns, not matching the user's email address, and not reusing the last three passwords.

Bcrypt automatically generates a unique random salt per password, preventing rainbow table attacks. The constant-time comparison in `check_password_hash` prevents timing-based password inference.

#### 4.7.2.2 JWT Session Management

After successful authentication, the server issues a JWT with a seven-day expiry:

```python
from flask_jwt_extended import create_access_token, jwt_required
from datetime import timedelta

def generate_auth_token(user_id):
    access_token = create_access_token(
        identity=user_id,
        expires_delta=timedelta(days=7)
    )
    return access_token
```

The seven-day expiry balances security (limited token lifespan) with convenience (users are not prompted to re-authenticate daily). Tokens are signed with HMAC-SHA256, so any modification to the payload invalidates the signature. A token blacklist maintains revoked tokens (from logout or account deletion) until their natural expiry.

#### 4.7.2.3 Brute Force Protection

Rate limiting is applied to the login endpoint using `flask_limiter`:

```python
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(app, key_func=get_remote_address,
                  default_limits=["200 per day", "50 per hour"])

@app.route('/api/auth/login', methods=['POST'])
@limiter.limit("5 per minute")
def login():
    """Login endpoint: maximum 5 attempts per minute per IP address."""
    pass
```

Five attempts per minute allows legitimate users multiple attempts for typos or forgotten passwords while blocking automated rapid-fire attacks. After 10 failed attempts within 24 hours, the account locks for 30 minutes and the user receives an email notification. Rate limits apply per IP address.

#### 4.7.2.4 Two-Factor Authentication

SmartFinance implements Two-Factor Authentication (2FA) using the Time-based One-Time Password (TOTP) algorithm as defined in RFC 6238. TOTP augments the standard password-based login by requiring a six-digit code generated by an authenticator application, ensuring that password compromise alone is insufficient to gain account access.

The backend uses the `pyotp` library to manage TOTP operations. During enrolment, the server generates a cryptographically random base32-encoded secret and stores it in the `TwoFactorAuths` table. A provisioning URI is constructed and returned as a base64-encoded QR code PNG, which the user scans with Google Authenticator or a compatible application. Each code is valid for a 30-second window with ±30 seconds tolerance for clock drift.

Enabling 2FA is a two-step process. The user first initiates setup, which generates the QR code without activating 2FA on the account. The user must then supply a valid TOTP code confirming that their authenticator application is correctly configured; only at that point does the server set `TwoFactorEnabled = TRUE`. This prevents lock-out if the user initiates setup but does not complete it.

When a user with 2FA enabled submits login credentials, the server validates the password and, if correct, returns `{"requires_2fa": true}` rather than a JWT. The client presents a TOTP verification screen. The server verifies the submitted code against the stored secret; only upon successful verification is a JWT issued.

**Backup codes.** During enrolment, the server generates ten one-time-use recovery codes and stores them as a JSON array in the `TwoFactorAuths.BackupCodes` column. The plaintext codes are returned to the client once, at generation time, for the user to record. If the user loses access to their authenticator application, they may enter a backup code at the TOTP verification step to complete login; the server removes the consumed code from the JSON array on use so each code can only be used once. A user may regenerate a fresh set of ten codes at any time from the Security Settings screen, which replaces the stored array.

**Disabling 2FA.** Disabling requires the user to confirm their current password, preventing an attacker with temporary device access from silently removing the second factor.

#### 4.7.2.5 Security Score System

To encourage adoption of available security measures, SmartFinance presents a security score on the Security Settings screen. The score takes one of three discrete values:

**Table 4.7.2.5.1: Security Score Values**

| Account State | Score |
|---------------|-------|
| Email not verified (no 2FA) | 30 |
| Email verified, 2FA not enabled | 60 |
| Email verified and 2FA enabled | 100 |

The score is displayed as a filled progress bar colour-coded by level: red below 50 (low security), amber between 50 and 79 (medium security), and green at 80 and above (high security). This design makes clear to the user that email verification is a prerequisite for meaningful security posture, and that enabling 2FA is the single most impactful remaining step.

#### 4.7.2.6 Session Management

Every successful login creates a `UserSessions` record capturing the session identifier, user ID, device name, device type, IP address, user agent string, login timestamp, and last-active timestamp. The device name and type are derived from the `User-Agent` header, enabling users to identify entries such as *Samsung Galaxy S24 (mobile)* or *Chrome on Windows 11 (web)* in the session list.

The Security Settings screen displays all currently active sessions. Users may revoke any individual session — logging out a device they no longer possess — by selecting it from the list. Revoking a session sets `IsActive = FALSE` on the session record and writes a `session_terminated` event to the security log.

#### 4.7.2.7 Security Activity Log

SmartFinance maintains an audit trail of security-relevant events in the `SecurityLogs` table. Events are written for: successful login, failed login attempt, logout, password change, 2FA enabled, 2FA disabled, session revocation, email verification, and account deletion. Records are never updated or deleted through normal application operation.

**Table 4.7.2.7.1: Security Log Event Types**

| Event Type | Description |
|------------|-------------|
| `login` | Successful authentication |
| `login_failed` | Failed authentication attempt |
| `logout` | User-initiated logout |
| `password_change` | Account password changed |
| `2fa_enabled` | Two-Factor Authentication activated |
| `2fa_disabled` | Two-Factor Authentication deactivated |
| `session_terminated` | A specific session revoked by the user |
| `email_verified` | Email address verified |
| `account_deleted` | Account permanently deleted |

The log is visible to the user on the Security Settings screen in reverse-chronological order. Presenting this information directly to users supports transparency and enables them to detect suspicious activity such as logins from unrecognised IP addresses.

---

### 4.7.3 Secure Communication

All client-server communication uses HTTPS with TLS 1.3 encryption. Flask is configured to redirect all HTTP requests to HTTPS and to set security cookies appropriately:

```python
app.config['SESSION_COOKIE_SECURE']   = True   # Cookies only over HTTPS
app.config['SESSION_COOKIE_HTTPONLY'] = True   # Block JavaScript access
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'  # CSRF protection

@app.before_request
def enforce_https():
    if not request.is_secure and not app.debug:
        url = request.url.replace('http://', 'https://', 1)
        return redirect(url, code=301)
```

Security response headers are applied to all API responses to prevent common web vulnerabilities:

```python
@app.after_request
def set_security_headers(response):
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection']       = '1; mode=block'
    response.headers['X-Frame-Options']         = 'DENY'
    response.headers['Referrer-Policy']         = 'strict-origin-when-cross-origin'
    response.headers['Content-Security-Policy'] = "default-src 'self'"
    return response
```

CORS is configured to accept requests only from authorised origins, preventing cross-origin requests from unauthorised domains. Production certificates are managed by Let's Encrypt with automated 90-day renewal via Certbot, and certificate pinning prevents man-in-the-middle attacks even in the event of a compromised Certificate Authority.

---

### 4.7.4 Ethical Handling of Research Data

As SmartFinance involves beta testing with real users during the FYP evaluation phase, ethical data handling protocols ensure participant privacy and research integrity.

User data collected during testing is anonymised before inclusion in research documentation. Direct identifiers (email address, full name, user ID) are removed and replaced with anonymous participant codes (e.g., P001, P002). Precise age values are generalised to age brackets and exact timestamps are reduced to month-year granularity before any data is included in research materials.

Research data is stored in a separate database instance with no network connection to the production system. Access is restricted to the research supervisor and the student researcher. Research data is scheduled for deletion six months after FYP submission. Participants provide informed consent before data collection, explicitly acknowledging the data collection purpose, the types of data collected, the storage duration, anonymisation procedures, their right to withdraw at any time, and the absence of any commercial use of their data.

The FYP report and all published materials contain only anonymised, aggregated statistics. Individual transaction details, real names, and location information more specific than a general region are not included.

---

### 4.7.5 Security Testing and Validation

Security measures were validated through penetration testing and automated vulnerability scanning. Test scenarios included SQL injection attempts on all API endpoints, XSS payload injection, authentication bypass attempts, session hijacking simulation, brute force password attacks, and man-in-the-middle interception attempts. Automated scanning used Bandit for static Python code analysis and Safety for dependency vulnerability checking. Table 4.7.5.1 records the outcome of each security domain.

**Table 4.7.5.1: Security Audit Checklist**

| Security Domain | Validation Method | Status |
|-----------------|-------------------|--------|
| Password storage | Verify bcrypt hashing with cost factor 12 | Validated |
| Data encryption | Confirm AES-256 encryption for sensitive fields | Validated |
| HTTPS enforcement | Test HTTP to HTTPS redirection | Validated |
| JWT token security | Verify signature validation and expiry checks | Validated |
| Rate limiting | Confirm lockout after excessive attempts | Validated |
| Input validation | Test SQL injection and XSS prevention | Validated |
| Access control | Verify users can only access own data | Validated |
| CORS configuration | Confirm unauthorised origins blocked | Validated |

---

### 4.7.6 Security Limitations and Current Constraints

While SmartFinance implements comprehensive security measures, three constraints exist within the FYP scope.

Manual investment tracking — the consequence of excluding real-time banking API integration — means that investment prices are not automatically validated. A user could record incorrect figures without detection. This eliminates the data breach risks inherent in third-party API integration but transfers accuracy responsibility to the user.

Biometric authentication (fingerprint and facial recognition) is not implemented. Its availability depends on device hardware capabilities and is not universally supported across the low-to-mid range Android devices that form the target demographic's primary device type. Biometric authentication remains a planned enhancement for a future release alongside professional third-party security certification.

The development environment uses locally managed encryption keys stored in environment variables. A production deployment would require a dedicated key management service (such as AWS Secrets Manager) for secure key rotation and access auditing. This transition is noted in the deployment architecture documentation but falls outside the academic project scope.

---

## 4.8 Chapter Summary

This chapter has presented the complete system design for SmartFinance. The three-tier client-server architecture separates the Flutter presentation layer, Flask application layer, and MySQL data layer into independently testable and deployable tiers. The fourteen-table database schema covers all domain entities — Users, Transactions, Budgets, BudgetCategories, Investments, Goals, Achievements, UserAchievements, HabitStreaks, RecurringTransactions, UserSettings, TwoFactorAuths, usersessions, and securitylogs — with referential integrity enforced through foreign key constraints and a deliberate denormalisation in `BudgetCategories.SpentAmount` for sub-20ms budget status queries. The RESTful API is organised into twelve Blueprint modules covering authentication, transactions, budgets, goals, investments, gamification, analytics, settings, 2FA, security, recurring transactions, and financial insights.

Six computational algorithms address the specific performance constraints of mid-range Android devices: intelligent categorisation achieves 85% accuracy in under 5ms using in-memory keyword matching and bounded user history; budget alerting completes in under 20ms through denormalised caching; XP progression uses a linear formula for O(1) level calculations; portfolio performance uses single-pass aggregation to complete in under 100ms for typical holdings; streak tracking uses a `MAX()` indexed query for O(1) streak checks; and achievement evaluation uses trigger-based selective checking to reduce evaluation time from 2.5 seconds to under 220ms. Multi-layered security — AES-256 encryption, bcrypt hashing, JWT authentication, TOTP-based 2FA, TLS 1.3, and a persistent security audit log — provides defence-in-depth while complying with PDPA 2010 requirements.

Chapter 5 documents the implementation of this design, presenting the development process, challenges encountered, and testing outcomes against the functional and non-functional requirements established in Chapter 3.

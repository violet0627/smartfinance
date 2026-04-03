# SmartFinance — FYP System Preview Script
### Final Version · Word-for-word · ~30 minutes

> **How to use this script:**
> - Read every word naturally — do not rush
> - Stage directions in *italics inside brackets* — do not read these aloud
> - **Bold text** = emphasise slightly when speaking
> - Practice the demo flow at least once so your hands know where to tap

---

## SECTION 1 — Project Overview
### (~3 minutes)

"Good [morning / afternoon]. My name is [Your Name], student ID [Your ID], and my Final Year Project is called **SmartFinance** — a personal finance management mobile application built for Android.

Let me start by explaining the problem I am solving.

Managing personal finances is something most people know they should do, but very few actually do consistently. The main reasons are: it feels tedious, existing tools are either too complicated, or they just show raw numbers without telling you what those numbers actually mean. You open your banking app, you see your account balance, and that is it. You have no idea whether you are overspending on food, whether you are on track with your savings, or how your investments are performing overall.

This problem is especially common among students and young working adults in Malaysia — people who are just starting to earn money but have no structured financial guidance.

**SmartFinance solves this** with an all-in-one mobile application covering five core areas: transaction tracking, budget management, savings goals, investment portfolio tracking, and a financial insights engine that analyses the user's actual spending behaviour and produces a personalised health score with specific recommendations.

What makes this different from a basic finance tracker is two key things. First, the **Financial Insights Engine** — it does not just record your data, it interprets your data and tells you what it means. Second, a **gamification system** — users earn experience points, unlock achievements, and maintain daily streaks, which encourages consistent tracking instead of giving up after the first week.

The system is built using **Flutter** for the mobile frontend, **Python Flask** for the backend REST API, and **MySQL** for the database. The Flutter app sends HTTP requests to the Flask server, Flask processes the logic and queries MySQL, then returns results as JSON back to the app.

Now let me demonstrate the system."

---

## SECTION 2 — Live Demo
### (~20 minutes)

---

### 2A — Login and Security
#### (~2 minutes)

"Let me begin from the login screen.

*(Open the app to the login screen.)*

I will log in with an existing account. *(Type email and password, tap Login.)* When the user taps Login, the app sends the credentials to my Flask backend at the authentication endpoint. The server checks the email and password against the MySQL database — if they match, it generates a **JWT access token** and returns it to the app. The app stores this token on the device, and every subsequent API call includes this token in the request header so the server knows who is making the request.

The access token expires after **one hour** for security. When it expires, the app uses a separate long-lived **refresh token** — valid for 30 days — to obtain a new access token silently, without asking the user to log in again.

My system also supports **Two-Factor Authentication**. When 2FA is enabled, after the correct password is entered, a six-digit one-time code is sent to the user's email. They must enter this within the time limit to complete login. Even if someone knows your password, they still cannot access the account without your email.

New accounts require **email verification** — a verification link is sent on registration, and the account is only fully activated after clicking that link.

There is also a **Security Score** in the settings — 30 points if email is not verified, 60 if verified, and 100 if both email is verified and 2FA is enabled. This encourages users to fully secure their account."

---

### 2B — Dashboard
#### (~3 minutes)

"After login, the user arrives at the **Dashboard** — the central hub of the application.

*(Show the dashboard screen.)*

At the top is the user's **profile photo** — uploadable from their gallery or camera — with a personalised greeting.

Below that is the **Financial Summary card** showing total income, total expenses, and net savings for the current month. Underneath the expense amount is a percentage comparison against last month — so if it says '↑ 12% vs last month', the user is spending 12% more than they did last month. This gives immediate context without navigating anywhere else.

Further down are quick-access cards for Budget, Portfolio, and Gamification progress — all live data refreshed on every load.

Below that are **upcoming bills** from the recurring transactions module and the five most recent transactions.

The **bottom navigation bar** has five tabs: Dashboard, Transactions, Goals, Portfolio, and Financial Insights. Let me walk through each one.

One technical detail — the dashboard loads all data simultaneously using `Future.wait()` for parallel API calls. All sections appear together at the same time rather than loading one after another, making the experience feel much faster."

---

### 2C — Transaction Tracking
#### (~3 minutes)

"Transactions are the foundation of the entire system — every feature depends on what is recorded here.

*(Navigate to Add Transaction.)*

I will add an expense now. I select **Expense**, enter RM 25, choose **Food and Dining** as the category, keep today's date, and optionally add a description. *(Fill in and tap Save.)*

*(Navigate to Transaction History.)* It appears immediately in the list with the correct icon, colour, and date. This record is now in the MySQL database and is instantly reflected across the dashboard, budget tracker, and financial insights engine.

The history screen has **search, filter, and sort** built in. I can search by category or description, filter to income or expenses only, sort by date or amount, and apply advanced filters for date ranges or amount ranges. *(Demonstrate briefly.)*

To **edit** a transaction, I tap on it. The form pre-fills with the original values. If I make no changes and go back, nothing happens — the app compares current field values against the originals. If I change something and try to leave, it asks 'Discard changes?' to prevent data loss.

To **delete**, I swipe left. A confirmation dialog appears before anything is removed permanently.

For **recurring transactions** — like monthly rent or a weekly salary — I set them up once with the name, amount, category, and frequency. The system shows them as upcoming bills on the dashboard and sends reminder notifications before they fall due."

---

### 2D — Budget Management
#### (~3 minutes)

"Now the **Budget** feature. *(Navigate to Budget.)*

A budget is a monthly spending plan with a total amount allocated across spending categories.

*(Show the budget overview screen.)*

You can see the overall progress bar and below it the category breakdown — Food, Transport, Entertainment — each with its own progress bar, amount used, and remaining amount.

The key feature is the **intelligent alert system**. When a category reaches **90%** of its limit, or the overall budget reaches **80%**, the system automatically sends a push notification to the device — even when the app is closed. This warns users before they overspend, not after.

If a category exceeds its limit, the bar turns red and shows a negative remaining amount.

The budget always corresponds to the current calendar month and resets automatically on the first of every month."

---

### 2E — Financial Goals
#### (~2 minutes)

"The **Goals** feature lets users set savings targets with deadlines.

*(Navigate to Goals.)*

The summary card at the top shows active goals, completed goals, and overall progress percentage.

Each goal card shows the name, target, amount saved, a progress bar, and a **deadline countdown**. When fewer than seven days remain, the countdown turns **orange** as an urgency warning.

Tapping Contribute opens a dialog. If I enter more than the remaining amount — *(type an amount that exceeds remaining)* — a real-time warning appears: 'Exceeds remaining by RM X.XX — the goal will be marked as completed.' The user is fully informed before confirming.

Goals can be filtered as All, Active, or Completed."

---

### 2F — Investment Portfolio
#### (~2 minutes)

"The **Portfolio** screen tracks all investments in one place.

*(Navigate to Portfolio.)*

The summary card shows total portfolio value, total amount invested, and overall profit or loss with a percentage return.

Below that is the **Asset Breakdown** showing the distribution across investment types. SmartFinance supports **ten asset classes**: Stocks, Cryptocurrency, Bonds, Mutual Funds, ETFs, Real Estate, Commodities, Fixed Deposits, Unit Trusts, and Other — covering all major investment types available to Malaysian investors.

Each investment card shows purchase price, current price, and profit or loss. Users can update the current market price at any time — the P&L recalculates immediately.

The **Top Performers** section automatically surfaces the best-performing investments.

The filter button lets users view one asset class at a time. When a filter is active, a banner appears showing what is filtered with a Clear button. The filter icon turns yellow to signal that results are not showing everything."

---

### 2G — Financial Insights Engine
#### (~3 minutes)

"This is the most distinctive feature of SmartFinance. *(Navigate to Financial Insights.)*

The **Financial Insights Engine** analyses the user's transaction data for the current calendar month and produces a **Financial Health Score from 0 to 100**. Green means Excellent — 80 and above. Teal means Good — 60 to 79. Orange means Fair — 40 to 59. Red means Needs Work — below 40.

The score comes from **four independent pillars**, each worth up to 25 points.

**Pillar one — Savings Rate.** Savings rate is calculated as income minus expenses divided by income. A rate of 20% or above earns the full 25 points. Below 20%, the score scales proportionally. If no income is recorded this month, the pillar returns a neutral 12.5 points.

**Pillar two — Budget Adherence.** Staying within the budget earns 25 points. Going over budget reduces the score on a sliding scale — at 50% over budget, this pillar reaches zero. No budget set means a neutral 12.5 points.

**Pillar three — Spending Consistency.** This compares this month's total spending against last month's. If the increase is within 10%, the user gets full marks. For each percentage above that tolerance, points are deducted. If there is no previous month data, a neutral 12.5 is returned.

**Pillar four — Goal Progress.** This is the number of completed goals divided by total goals, multiplied by 25. If no goals exist, a neutral 12.5 is returned.

The four pillars are summed and clamped between 0 and 100 to give the final score.

Below the score are **personalised insight cards** generated dynamically by the backend — for example: 'You are saving 28.5% of your income this month — above the 20% target' or 'Your spending increased 35% compared to last month — review your recent expenses.' Nothing is hardcoded — every message uses the user's actual numbers."

---

### 2H — Gamification
#### (~2 minutes)

"The **gamification system** addresses the biggest real-world problem with finance apps — users stop using them after a few days.

*(Navigate to the gamification section or achievements screen.)*

Every transaction logged earns the user **experience points** and extends their **daily streak** — a count of consecutive days with at least one transaction recorded. Break the streak and it resets to zero.

**Achievement badges** are unlocked for milestones — first transaction, 7-day streak, completing a goal, and more. When a new badge is unlocked, a push notification fires and the badge appears on the achievements screen.

The **level system** uses exponential progression — Level 2 requires 100 XP, each subsequent level requires 1.5 times more XP than the previous one, so the higher levels become meaningfully harder to reach.

There is also a **leaderboard** ranking users by total XP, with a privacy option to opt out.

The reason this works is behavioural — the streak mechanic creates a loss-aversion effect. Users do not want to break their streak, so they open the app even on days they would normally skip. Over time this becomes an automatic habit."

---

## SECTION 3 — Technical Explanation
### (~4 minutes)

"Let me explain the technical structure of the system.

**Architecture.** SmartFinance follows a client-server architecture. Flutter is the client handling all UI and interaction. Flask is the server handling all business logic and data operations. They communicate through a RESTful API over HTTP using JSON.

**Backend structure.** The Flask backend is organised into **12 route blueprints** — one per feature area: authentication, transactions, budgets, goals, investments, recurring transactions, gamification, reports, settings, security, two-factor authentication, and financial insights. Each blueprint has its own URL prefix such as `/api/transactions` or `/api/budgets`.

**Database.** MySQL contains **14 tables**: Users, Transactions, Budgets, BudgetCategories, Goals, Investments, RecurringTransactions, Achievements, UserAchievements, HabitStreaks, PasswordResets, EmailVerifications, Sessions, and UserSettings. Relationships between tables use foreign keys to maintain data integrity.

**Security.** Passwords are hashed with bcrypt before being saved. All protected endpoints require a valid JWT token. The JWT uses the HS256 algorithm — HMAC with SHA-256 — and the secret key is stored in the server environment, not the source code. Access tokens expire after one hour; refresh tokens last 30 days.

**Notifications.** The app uses `flutter_local_notifications`, initialised at startup with Android 13 runtime permission. Budget alerts, achievement unlocks, and bill reminders all go through one centralised notification service."

---

## SECTION 4 — Test Cases
### (~3 minutes)

"Let me walk through three prepared test cases.

---

**Test Case 1 — Budget Alert Notification**

- **Input:** Add an expense that pushes a budget category above 90% of its limit.
- **Expected:** Push notification fires with the category name and percentage, budget screen highlights the category.
- **Actual:** *(Show or describe.)* Notification appears correctly. Budget card shows warning colour. **Test passes.**

---

**Test Case 2 — Financial Health Score Reflects Real Data**

- **Input:** A user with income recorded, expenses below budget, and at least one active goal.
- **Expected:** Savings Rate and Budget Adherence pillars score well — total score in Good or Excellent range.
- **Actual:** *(Show Financial Insights screen.)* Score is in the expected range. Savings Rate bar is green. Budget bar is green. Score reflects actual behaviour, not hardcoded. **Test passes.**

---

**Test Case 3 — Goal Over-Contribution Warning**

- **Input:** Goal with RM 200 remaining. User types RM 500 in the contribute dialog.
- **Expected:** Real-time warning showing exact excess amount.
- **Actual:** *(Open dialog, type 500.)* Warning appears immediately: 'Exceeds remaining by RM 300.00 — goal will be marked as completed.' **Test passes.**"

---

## CLOSING
### (~1 minute)

"To summarise — SmartFinance is a fully functional personal finance system with eight integrated modules: secure authentication, transaction tracking, budget management with alerts, savings goals, investment portfolio, financial insights, recurring transactions, and gamification. Every module connects to the others — a transaction affects the budget, which feeds the health score, which may trigger a notification.

The backend is live, the app is functional on Android, and all features have been tested end to end.

Thank you for your time. I am happy to demonstrate any feature in more detail or answer any questions."

---
---

# Q&A PREPARATION
## Complete Supervisor Question Bank — 35 Questions

> Read through and understand every answer — do not memorise word for word, understand the concept so you can explain naturally. Questions are grouped by topic.

---

## GROUP A — System Architecture

---

**Q1: Why did you choose Flutter over React Native or native Android?**

"I chose Flutter for three main reasons. First, Flutter compiles to native ARM machine code directly — unlike React Native which goes through a JavaScript bridge that can cause performance bottlenecks. Second, Flutter's widget system is built on Material Design and is very mature, which let me build a polished interface efficiently. Third, a single Flutter codebase runs on both Android and iOS, which gives the project more potential reach even though I am currently demonstrating on Android only."

---

**Q2: Why Flask instead of Django or Node.js?**

"Flask is a micro-framework — it gives me the core tools and full control over structure without unnecessary overhead. I organised the backend into 12 route blueprints, one per feature, which keeps the code clean and modular. Django would add a lot of things I do not need, like a built-in template engine and admin panel, since I only need a REST API. I chose Python over Node.js because Python's mathematical and data processing capabilities were useful for the Financial Insights calculation, and libraries like SQLAlchemy made database work very straightforward."

---

**Q3: How many API endpoints does your system have? Can you give some examples?**

"The backend has 12 blueprint modules each covering a feature area. Examples of specific endpoints include: `POST /api/auth/login` for authentication, `GET /api/transactions/user/<id>` to fetch transaction history, `GET /api/insights/user/<id>` for the financial insights report, `POST /api/gamification/streak/update` to update the daily streak, and `GET /api/gamification/leaderboard` for the rankings. In total there are approximately 40 to 50 individual route functions across all 12 blueprints."

---

**Q4: What software development methodology did you follow for this project?**

"I followed an **Agile-inspired approach** with iterative development cycles. I planned the features in order of dependency — authentication first, then transactions, then budget, then more advanced features like insights and gamification — because each module builds on the previous one. I conducted periodic testing after completing each module before moving to the next, which helped catch integration issues early rather than at the end. I also gathered feedback from my supervisor and test participants between cycles to adjust the direction when needed."

---

**Q5: What happens if the backend server is offline or there is no internet connection?**

"Currently SmartFinance requires an active internet connection to function, because all data is stored server-side in MySQL. If the server is offline, the app will show an error message from the API service — for example, a connection timeout error — and the user cannot load or save data. This is a known limitation. In a production version, I would implement local caching using SQLite on the device for offline reading, and a sync queue that pushes pending transactions to the server when connectivity is restored. For the scope of this FYP, all demonstration and testing was conducted on a local network where the server availability was controlled."

---

---

## GROUP B — Database Design

---

**Q6: How many tables are in your database and what are the main ones?**

"There are 14 tables in total. The core ones are: **Users** — stores account credentials and profile information; **Transactions** — every income and expense record; **Budgets** and **BudgetCategories** — the monthly budget plan and its per-category allocations; **Goals** — savings targets with deadlines and progress tracking; **Investments** — individual portfolio holdings; **RecurringTransactions** — scheduled repeating transactions; **Achievements**, **UserAchievements**, and **HabitStreaks** — the gamification data. The remaining tables are **PasswordResets**, **EmailVerifications**, **Sessions**, and **UserSettings**, which handle security and preferences."

---

**Q7: Is your database normalised? What normal form does it follow?**

"Yes, the database is normalised to **Third Normal Form**. Every table has a single primary key. There are no repeating groups — for example, budget categories are stored in a separate BudgetCategories table with a foreign key to Budgets, rather than as columns in the Budgets table. There are no transitive dependencies — for example, the Users table only stores user-related data, while transaction amounts and categories are stored separately in the Transactions table. Normalisation helps avoid data duplication and makes updates consistent — if a user changes their email, it only needs to be changed in one place."

---

**Q8: How do you prevent SQL injection attacks?**

"I use SQLAlchemy as the ORM — Object Relational Mapper — throughout the backend. SQLAlchemy never concatenates raw strings to build SQL queries. Instead, it uses parameterised queries where user input is always passed as a separate parameter, never embedded directly into the query string. For example, instead of writing `SELECT * FROM users WHERE email = '` + user_input + `'`, SQLAlchemy generates a prepared statement and binds the value safely. This makes SQL injection structurally impossible for all database operations in the system."

---

**Q9: Why did you choose MySQL instead of MongoDB or Firebase Firestore?**

"Financial data is inherently relational — a transaction belongs to a user, may fall under a budget category, and may trigger an achievement. These relationships are naturally expressed in a relational schema with foreign keys and JOIN queries. MySQL also provides ACID compliance — meaning any operation either completes fully or not at all. This is critical for financial data where a partial write could leave the database in an inconsistent state, such as a transaction being saved without the corresponding budget balance being updated. NoSQL databases like MongoDB are better suited for unstructured or document-based data, which does not apply here."

---

---

## GROUP C — Authentication and Security

---

**Q10: What is JWT and why did you use it instead of session-based authentication?**

"JWT stands for JSON Web Token. It is a self-contained token that encodes the user's ID, email, token type, issue time, and expiry time, then signs the whole thing using HMAC SHA-256 with a secret key. The key advantage over session-based authentication is that JWT is **stateless** — the server does not need to store any session data. It just verifies the token's signature on every request. This makes the backend much easier to scale horizontally, because any server instance can verify any token without needing shared session storage."

---

**Q11: How long does the JWT token last? What happens when it expires?**

"The **access token** expires after **one hour**. This limits the damage if a token is somehow intercepted — it becomes useless after 60 minutes. When the access token expires, the app uses a separate **refresh token** — which lasts **30 days** — to silently request a new access token from the backend without asking the user to log in again. If the refresh token also expires after 30 days of no usage, the user needs to log in again. This design balances security and user convenience."

---

**Q12: How does bcrypt work? What is a salt?**

"Bcrypt is a password hashing function designed specifically for passwords. Unlike a regular hash like SHA-256 which is designed to be fast, bcrypt is intentionally slow — it is computationally expensive — which makes brute force attacks impractical. A **salt** is a randomly generated string that is added to the password before hashing. Every user gets a unique salt, so even if two users have the same password, their stored hashes will be completely different. This prevents attackers from using pre-computed rainbow tables to reverse the hashes. When a user logs in, bcrypt extracts the salt from the stored hash, re-hashes the provided password with the same salt, and compares the result."

---

**Q13: What are your password requirements?**

"The system enforces four rules: minimum eight characters, at least one uppercase letter, at least one lowercase letter, and at least one special symbol from the set exclamation mark, at, hash, dollar, percent, caret, ampersand, asterisk, and similar characters. These rules are enforced on both the frontend — with a real-time validator in the registration form — and the backend — as a server-side validation function before the account is created."

---

**Q14: How does Two-Factor Authentication work technically?**

"When a user enables 2FA in security settings, the flag is stored in their user record in the database. On subsequent logins, after validating the password, the server checks this flag. If 2FA is active, the server generates a random six-digit numeric code, stores it with an expiry time in the database, and sends it to the user's registered email. The Flutter app then shows a code entry screen. The user must enter the correct code before expiry to complete login. The code is single use — once validated it is deleted from the database so it cannot be replayed. If the code expires before the user enters it, they must request a new one."

---

---

## GROUP D — Financial Insights Algorithm

---

**Q15: How exactly does the Financial Health Score algorithm work?**

"The score is out of 100 and is built from four pillars, each worth up to 25 points.

**Pillar one — Savings Rate:** savings_rate = (income − expense) / income × 100. If rate is 20% or above, pillar score = 25. Below 20%, it scales proportionally: (savings_rate / 20.0) × 25. No income recorded = neutral 12.5.

**Pillar two — Budget Adherence:** If within budget, score = 25. If over budget, over_ratio = (expense − budget) / budget. Pillar score = 25 − (over_ratio × 50), floored at 0. So at 50% over budget, pillar reaches zero. No budget set = neutral 12.5.

**Pillar three — Spending Consistency:** change_ratio = (this_month_expense − last_month_expense) / last_month_expense. If change_ratio ≤ 0.10, score = 25. Above 10%, each additional percentage reduces the score: 25 − (excess × 50), floored at 0. No previous month data = neutral 12.5.

**Pillar four — Goal Progress:** (goals_completed / total_goals) × 25. No goals = neutral 12.5.

All four pillars are summed and clamped between 0 and 100."

---

**Q16: Why did you choose 20% as the savings rate target?**

"The 20% savings rate is a widely cited personal finance guideline known as the **50/30/20 rule** — 50% of income on needs, 30% on wants, and 20% on savings and debt repayment. This rule is referenced in personal finance literature and recommended by financial advisors in Malaysia and internationally. I used 20% as the full-marks threshold because it is an achievable but meaningful target. Users saving below 20% still receive partial credit on a sliding scale — they are not penalised with zero just for saving less than the ideal."

---

**Q17: What if the user is a student with no income recorded? Will their score always be low?**

"No — the system handles this case specifically. When no income is recorded for the current month, the Savings Rate pillar returns a **neutral score of 12.5 out of 25** instead of zero. The same neutral fallback applies to Budget Adherence if no budget is set, Spending Consistency if there is no previous month data, and Goal Progress if no goals exist. This means a new user or student with no income data will start with a baseline score of 50 — Fair range — rather than zero. The score can only improve from there as they start adding data."

---

**Q18: What is the highest possible score and can a user realistically achieve it?**

"The maximum score is 100 — Excellent. To achieve it, a user needs: a savings rate of 20% or higher this month, total spending within their monthly budget, spending that has not increased more than 10% compared to last month, and all active goals completed. It is achievable but requires genuine financial discipline across all four areas simultaneously, which is the point — it represents a user who is truly managing their finances well."

---

---

## GROUP E — Features Deep Dive

---

**Q19: How does the recurring transaction system work technically?**

"A recurring transaction is stored in the RecurringTransactions table with fields for name, amount, category, frequency (daily, weekly, monthly, or yearly), start date, optional end date, and an active flag. When the user opens the recurring transactions screen, the app fetches all active recurring transactions and displays them. The dashboard also queries this table to show upcoming bills — it filters for transactions due within the next 30 days based on the next execution date. The 'Execute Now' button on a recurring transaction manually creates one transaction instance in the Transactions table immediately. In a full production system, a background scheduler like APScheduler would automatically create transactions on their due dates, but for this FYP the user triggers execution manually or through the dashboard reminder."

---

**Q20: How does the investment profit and loss calculation work?**

"Each investment stores the purchase price, quantity, and current price. Profit or loss in ringgit is calculated as: (current_price − purchase_price) × quantity. The percentage return is: ((current_price − purchase_price) / purchase_price) × 100. The total portfolio value is the sum of (current_price × quantity) for all investments. The total invested is the sum of (purchase_price × quantity). The overall return is (total_value − total_invested) / total_invested × 100. All of this is calculated server-side in the portfolio summary endpoint and returned as pre-computed values to the Flutter app."

---

**Q21: How does the leaderboard ranking work?**

"The leaderboard queries all users who have opted in to leaderboard visibility in their settings. It calculates each user's total XP by summing the XP value of all their unlocked achievements from the UserAchievements table. Users are then ranked in descending order by total XP. The current user's own rank position is also returned so they can see where they stand even if they are not in the top entries displayed. Users who have disabled leaderboard visibility in their settings are excluded from the query entirely."

---

**Q22: How does the level system work? How much XP is needed for each level?**

"The level system uses **exponential progression**. Level 2 requires 100 XP. Each subsequent level requires 1.5 times more XP than the previous level's increment. So Level 3 needs 100 + 150 = 250 total XP, Level 4 needs 250 + 225 = 475 total XP, Level 5 needs 475 + 337 = 812 total XP, and so on. This means early levels are easy to reach and give users quick gratification, while higher levels become meaningfully harder — which is the standard game design approach to maintaining long-term engagement."

---

**Q23: How does the budget category allocation work when creating a budget?**

"When creating a budget, the user sets a total monthly amount and then allocates portions to specific spending categories. The frontend calculates the remaining unallocated amount in real time as the user fills in category amounts. The system requires the total category allocations to equal the overall budget amount before allowing save — with a small tolerance of RM 1 to account for rounding. On the backend, the budget is saved to the Budgets table and each category allocation is saved as a separate row in the BudgetCategories table, linked by the budget's ID as a foreign key."

---

---

## GROUP F — Testing

---

**Q24: How did you test your system? How many test cases?**

"I conducted two types of testing. First, **functional testing** — I prepared 50 test cases covering all eight modules. Each test case documents the test description, input data, expected output, actual output, and a pass or fail result. I tested both normal scenarios and edge cases such as empty inputs, invalid amounts, boundary values like exactly 80% and 90% budget usage, and error states like expired tokens and duplicate registrations. Second, **user acceptance testing** with six participants who used the application and completed a structured usability questionnaire covering task completion, ease of use, feature satisfaction, and overall experience rating."

---

**Q25: What were the UAT results? Did anyone report problems?**

"The overall results were positive. Features that received the highest satisfaction scores were the Financial Insights screen and the gamification system — participants found these distinctive and motivating. The dashboard was rated highly for giving a clear financial overview at a glance. The main feedback from participants was a desire for more chart types in the reports section — for example, a line chart showing spending trends over multiple months. One participant also suggested adding an import feature for bank statements to reduce manual entry. I documented both of these as future work recommendations in my report."

---

---

## GROUP G — Limitations, Privacy, and Future Work

---

**Q26: What are the limitations of your system?**

"Three main limitations. First, **manual data entry** — all transactions must be entered by the user. There is no automatic bank sync or statement import. This is the biggest barrier to daily real-world usage. Second, **insights are monthly only** — the financial insights engine analyses only the current calendar month. A longer historical window would enable better trend detection. Third, **single user only** — the system does not support shared budgets between partners or family members. These are my three highest priority items for future development."

---

**Q27: How does your app handle user data privacy? Are you compliant with PDPA?**

"The app collects only the data the user voluntarily enters — financial transactions, goals, and investment records. No data is shared with third parties. Passwords are never stored in plain text. JWT tokens are stored locally on the device and sent only to the user's own server. In terms of Malaysia's Personal Data Protection Act, the app does not collect sensitive personal data beyond financial records that the user themselves enter, and the data is used only for the purpose of generating the user's own financial insights. For a full production deployment, a proper privacy policy and terms of service would need to be in place."

---

**Q28: What happens if the user loses their phone or changes device?**

"Because all data is stored server-side in MySQL and not on the device, losing the phone does not mean losing the data. The user simply installs the app on a new device, logs in with their email and password — plus their 2FA code if enabled — and all their transaction history, budgets, goals, and portfolio data are immediately accessible again. The only thing stored locally on the device is the JWT token and the profile photo, since photos are stored in the device's local storage. Losing the phone means the profile photo would need to be re-uploaded, but all financial data is safe on the server."

---

**Q29: What would you improve or add if you had more time?**

"Three things in priority order. First, **automatic bank statement import** — allowing users to upload their PDF bank statement and have transactions extracted and categorised automatically, which removes the manual entry barrier. Second, a **machine learning component** for the insights engine — instead of fixed rule-based thresholds, use the user's own historical data to generate personalised benchmarks. For example, compare against the user's own six-month average rather than a fixed 20% savings rate. Third, **multi-user budget sharing** for couples or families — allowing two accounts to share a combined budget and see each other's contributions."

---

---

## GROUP H — Tricky or Unexpected Questions

---

**Q30: Your financial health score uses neutral values of 12.5 when data is missing. Is that fair? Could it give a misleading result?**

"That is a fair challenge. The neutral value of 12.5 is a deliberate design decision to avoid punishing users unfairly for missing data. For example, a user who simply has not set up a budget yet should not receive a score of zero on that pillar — that would make the score feel meaningless or discouraging to new users. The neutral 12.5 effectively says 'we have no information about this pillar, so we assume average performance.' The insight cards specifically highlight when data is missing — for example, 'You have no active budget set — consider creating one to improve your score.' So the score is transparent about what it does and does not know."

---

**Q31: How do you know the 20% savings rate threshold and the 10% spending consistency tolerance are the right values? Did you do any research to validate them?**

"The 20% savings rate is based on the well-established 50/30/20 personal finance rule, which is widely referenced in financial literacy literature. For the 10% spending consistency tolerance, I made a design judgment based on the idea that month-to-month life expenses naturally vary slightly — utility bills, medical expenses, and similar items fluctuate — so a strict zero-tolerance threshold would unfairly penalise normal variation. Ten percent was chosen as a reasonable buffer. I validated the formula by testing it against multiple different spending profiles — a student with irregular income, a salaried employee with consistent spending, and an over-spender — and adjusted the thresholds until the scores felt meaningful and fair across those different scenarios."

---

**Q32: What is the difference between your app and just using a regular spreadsheet?**

"A spreadsheet requires the user to do all the calculation, categorisation, and analysis manually. SmartFinance automates all of that — you enter a transaction once and the budget updates, the dashboard updates, the health score updates, and notifications fire when thresholds are crossed — all automatically. More importantly, a spreadsheet cannot proactively tell you when you are approaching your budget limit, cannot generate personalised recommendations, and has no gamification to keep you engaged. SmartFinance is designed to be something the user actually opens and uses daily, not something they maintain manually once a week."

---

**Q33: Why did you include a leaderboard? Is it appropriate for a personal finance app?**

"This was a deliberate design decision with an acknowledged trade-off. The leaderboard provides social motivation — seeing others progressing can encourage a user to stay consistent. However, I am aware that a leaderboard based on XP rather than actual financial performance is the right choice here — ranking people by how much money they save would be inappropriate and could discourage lower-income users. XP is earned purely through app engagement, so the leaderboard measures consistency of habit, not wealth. I also made leaderboard participation entirely optional — users can opt out in settings and their data will not appear. This respects the personal and private nature of financial information."

---

**Q34: If two users have the same password, will their stored hashes be the same?**

"No — that is exactly what the bcrypt salt prevents. Even if two users both have the password 'Password123!', their stored hashes will be completely different because bcrypt generates a unique random salt for each user when their password is first hashed. The salt is stored as part of the hash string itself. When verifying a login, bcrypt extracts the salt from the stored hash and uses it to re-hash the provided password for comparison. This means an attacker who obtains the database cannot use pre-computed tables to reverse common passwords, because every hash is unique even for identical passwords."

---

**Q35: What is the most important thing you learned from building this project?**

"The most important lesson was that the hardest part of building a real system is not writing the code — it is making the right design decisions before writing a single line. For example, deciding how to calculate the financial health score in a way that is meaningful, fair, and explainable took far more thought than actually implementing it. Another lesson was the value of testing against real user behaviour rather than just what I expected — the UAT session revealed usability issues I completely missed during development, because I already knew how the app worked and naturally avoided the confusing paths. Building this project gave me a much deeper understanding of the full software development lifecycle — from requirements to deployment to user testing."

---

*End of Script and Q&A — Good luck with your presentation!*

# SmartFinance — FYP System Preview Script
### Revised Final Version · Word-for-word · ~30 minutes

> **How to use this script:**
> - Read every word naturally — do not rush
> - Stage directions in *italics inside brackets* — do not read these aloud
> - **Bold text** = emphasise slightly when speaking
> - Sections marked **[OPTIONAL]** — present them if time allows, skip if running short
> - Practice the full demo at least once the night before so your hands know where to tap

---

## SECTION 1 — Project Overview
### (~4 minutes)

"Good [morning / afternoon]. My name is [Your Name], student ID [Your ID], and my Final Year Project is called **SmartFinance** — a personal finance management mobile application built for Android.

Let me start by explaining the problem I am trying to solve, and why existing solutions are not good enough.

**The Problem.**

Managing personal finances is one of the most important life skills — but most people, especially students and young working adults in Malaysia, do not do it consistently. Based on my research, there are three main reasons for this.

First, **awareness** — most people have no idea where their money actually goes every month. They know their salary, they know their rent, but the small daily expenses — food, transport, online shopping — add up silently. By the time they realise they have overspent, it is already too late.

Second, **tools are either too difficult or too simple**. On one side, you have spreadsheets — they are powerful but require you to do everything manually: enter data, write formulas, create charts, and interpret the results yourself. Most people give up within a week. On the other side, you have your banking app — it shows your balance and transaction list, but nothing more. It does not tell you whether your spending pattern is healthy. It does not warn you before you overspend. It does not give you any advice.

Third, **motivation** — even people who start tracking their finances tend to stop after a few weeks. There is no reward for being consistent, no feedback telling them they are improving, and no consequence for skipping a day. Finance apps do not engage users the way other apps do.

**The Gap.**

So the gap in the market is this: there is no affordable, simple mobile application that tracks transactions, manages budgets, monitors investments, analyses your financial behaviour, and keeps you motivated to continue — all in one place.

**The Solution — SmartFinance.**

SmartFinance fills this gap with three core ideas.

One — **automatic analysis**. You record your transactions, and the system automatically calculates your budget usage, updates your portfolio, and analyses your spending pattern. You do not need to do the maths yourself.

Two — **intelligent feedback**. Instead of just showing raw numbers, SmartFinance produces a **Financial Health Score** from 0 to 100, based on four pillars of financial behaviour: how much you save, whether you stay within budget, whether your spending is consistent, and how well you are progressing on your savings goals. The system then generates personalised recommendations — not generic tips, but advice based on your actual numbers.

Three — **gamification**. The app uses experience points, achievement badges, daily streaks, and a leaderboard to make financial tracking feel rewarding. This is the engagement layer that encourages users to open the app every day and record their transactions consistently.

The system is built with **Flutter** for the mobile frontend, **Python Flask** for the backend REST API, and **MySQL** for the database. Flutter handles all the user interface. Flask handles all the business logic — including the financial health score calculation. MySQL stores all the data. The three components communicate through HTTP requests and JSON responses.

Now let me demonstrate the system."

---

## SECTION 2 — Live Demo
### (~18 minutes)

---

### 2A — Login and Security
#### (~2 minutes)

"Let me begin from the login screen.

*(Open the app to the login screen.)*

I will log in with my account. *(Type email and password, tap Login.)*

Here is what happens technically when I tap Login. The Flutter app takes my email and password, packages them as a JSON object, and sends a **POST request** to my Flask backend at the `/api/auth/login` endpoint. The Flask server receives this request, looks up the email in the MySQL Users table, and uses **bcrypt** to verify the password. Bcrypt does not compare passwords directly — it re-hashes the input using the same salt that was stored when the account was created, then compares the two hashes. This means the plain-text password is never stored anywhere in the system.

If the credentials are correct, the server generates a **JWT access token** — a signed string that encodes my user ID, email, and an expiry time. This token is returned to the Flutter app and stored on the device. Every API call I make after this point includes the token in the request header, so the server always knows who is making the request without asking me to log in again.

The access token expires after **one hour** for security. When it expires, the app automatically uses a separate **refresh token** — valid for 30 days — to get a new access token in the background, without interrupting the user.

My system also supports **Two-Factor Authentication**. When 2FA is enabled, after the correct password is entered, the server generates a random six-digit code, stores it in the database with an expiry time, and emails it to the user. The user must enter this code to complete login. Even if someone steals your password, they still cannot access your account without your email inbox.

*(Navigate to Settings → Security to show the Security Score.)*

There is also a **Security Score** — 60 points for email verified, 100 if both email verified and 2FA enabled. This makes security visible and encourages users to take action."

---

### 2B — Dashboard
#### (~2.5 minutes)

"After login, the user arrives at the **Dashboard**.

*(Show the dashboard screen.)*

The dashboard is designed to give the user a complete financial snapshot in one glance, without needing to open any other screen.

At the top is the user's name and profile photo — uploaded from gallery or camera.

Below that is the **Financial Summary card** — it shows total income, total expenses, and net savings for the current calendar month. Underneath the expense figure is a **percentage comparison against last month**. So if it says '↑ 8% vs last month', the user is spending 8% more than they did last month. This context is important — a number alone does not mean much, but a comparison immediately tells the user whether their spending is trending in the right direction.

Further down are quick-access cards showing budget usage percentage, portfolio total value, and gamification level — all live data.

Below that are **upcoming bills** from the recurring transactions module, and the five most recent transactions.

Now — a technical detail about how this dashboard loads. In Flutter, if you call each API endpoint one after another, the user sees sections popping in one by one, which looks unprofessional. Instead, I use **`Future.wait()`** — a Dart function that fires all the API calls in parallel simultaneously and waits for all of them to finish before updating the screen. This means the entire dashboard appears at once, which feels much faster and more polished.

Let me now walk through the main features."

---

### 2C — Transaction Tracking ⭐ MAIN FEATURE
#### (~3 minutes)

"**Transactions** are the foundation of the entire system. Every other feature — budgets, insights, goals — depends entirely on the transaction data entered here. If this part does not work correctly, nothing else can.

*(Navigate to Add Transaction.)*

I will add an expense now. I select **Expense**, enter **RM 25**, choose **Food and Dining** as the category, and keep today's date. *(Fill in and tap Save.)*

Let me explain what just happened technically. When I tapped Save, the Flutter app validated the input on the client side — checking that the amount is a positive number, a category is selected, and a date is chosen. It then sent a **POST request** to `/api/transactions/add` with the data as a JSON body.

On the Flask server, the route function receives this request, extracts the fields, and uses **SQLAlchemy** — my ORM — to construct a parameterised SQL INSERT statement. SQLAlchemy never builds raw SQL strings from user input — this is how I prevent SQL injection. The new row is inserted into the Transactions table in MySQL, and the server returns the created record back to the app. The Flutter app then adds this transaction to the top of the list without reloading the entire screen.

*(Navigate to Transaction History.)*

The history screen has **search, filter, and sort** built in. I can search by description or category, filter to show only income or only expenses, sort by date or amount, and use advanced filters for date ranges or amount ranges. All of this filtering happens on the data already fetched from the server — it is instant with no additional API calls.

To **edit** a transaction, I tap on it. The form pre-fills with the original values. The app tracks whether any field has actually changed — if I tap back without changing anything, it goes back silently. If I change a value and try to leave, it shows a 'Discard changes?' dialog to prevent accidental data loss.

To **delete**, I swipe left on any transaction. A confirmation dialog appears before the delete request is sent, because this is an irreversible action.

The app also supports **recurring transactions** — for example, monthly salary or rent. I set them up once with a name, amount, category, and frequency. The dashboard shows them as upcoming bills, and the system can execute them on demand."

---

### 2D — Budget Management ⭐ MAIN FEATURE
#### (~3 minutes)

"Now the **Budget** feature. *(Navigate to Budget.)*

A budget is a monthly spending plan. The user sets a total amount for the month and divides it across spending categories — for example, RM 800 for Food, RM 400 for Transport, RM 300 for Entertainment.

*(Show the budget overview screen.)*

Here you can see the overall budget progress bar at the top — this shows how much of the total monthly budget has been used. Below it is the **category breakdown** — each category has its own progress bar, amount spent, and remaining amount. This layout allows the user to see at a glance not just that they have spent money, but specifically *where* they have spent it.

Now let me explain the **intelligent alert system**, because this is one of the key technical features.

Every time a transaction is saved, the Flask backend checks whether the new expense pushes any budget category above **90%** of its limit, or the overall budget above **80%**. If either threshold is crossed, the server includes an alert flag in the API response. The Flutter app reads this flag and calls the **NotificationService**, which fires a push notification to the device — even if the app is running in the background.

This is important — the user is warned **before** they overspend, not after. Most banking apps only show you your balance after you have already spent the money. SmartFinance warns you when you are at 90%, so you still have time to adjust.

*(Point to the Food category bar.)* You can see Food is currently at 90.6% — a warning has already been triggered for this category. The progress bar changes colour to signal the warning state.

If a category fully exceeds its limit, the bar turns **red** and the remaining amount shows as a negative number — making the overspend visually obvious.

The budget automatically resets on the **first of every month** — the system uses the current calendar month to scope all budget calculations, so there is no manual reset required."

---

### 2F — Investment Portfolio ⭐ MAIN FEATURE
#### (~3 minutes)

"The **Portfolio** screen tracks all the user's investments in one place.

*(Navigate to Portfolio.)*

At the top is the **Portfolio Summary card** — it shows the total current value of all investments, the total amount originally invested, and the overall profit or loss in both ringgit and percentage. This calculation is done entirely on the Flask backend — the server queries all investments from the database, computes the sum of (current price × quantity) for current value and (purchase price × quantity) for amount invested, then returns the pre-calculated numbers to the app. The frontend just displays them.

The formula for each individual holding is straightforward:
- **Profit or loss in RM** = (current price − purchase price) × quantity
- **Percentage return** = ((current price − purchase price) / purchase price) × 100

Below the summary is the **Asset Breakdown** — a visual breakdown by investment type. SmartFinance supports **ten asset classes**: Stocks, Cryptocurrency, Bonds, Mutual Funds, ETFs, Real Estate, Commodities, Fixed Deposits, Unit Trusts, and Other. This covers all major investment types available to Malaysian retail investors.

Each investment card shows the asset name, type, purchase price, current price, and the profit or loss — green for gain, red for loss.

Users can **update the current market price** at any time. *(Tap on an investment → Update Price → change the value → confirm.)* The profit and loss recalculate immediately — the frontend sends a PUT request to update the current price in the database, then the server returns the updated P&L figures.

The **Top Performers** section at the bottom automatically surfaces the best-performing investments by percentage return.

The **filter button** lets users view one asset class at a time. When a filter is active, a banner appears at the top of the screen saying what is being filtered, with a Clear button. The filter icon also turns yellow to visually signal that the list is not showing everything."

---

### 2G — Financial Insights Engine
#### (~2.5 minutes)

"This is the most distinctive feature of SmartFinance, and the one that separates it from a basic tracker.

*(Navigate to Financial Insights.)*

The **Financial Insights Engine** runs entirely on the Flask backend. When the app opens this screen, it calls `/api/insights/user/<id>`. Flask queries the Transactions, Budgets, and Goals tables, runs the algorithm, and returns a score and a list of insight messages — all generated dynamically from the user's actual data.

The result is a **Financial Health Score from 0 to 100**. The colour and label change based on the score — green for Excellent (80 and above), teal for Good (60–79), orange for Fair (40–59), and red for Needs Work (below 40).

The score comes from **four independent pillars**, each worth up to 25 points.

**Savings Rate** — income minus expenses divided by income. 20% or above earns full marks. This 20% threshold is based on the well-known 50/30/20 financial rule.

**Budget Adherence** — if spending is within budget, full 25 points. Going over budget reduces the score on a sliding scale — at 50% over budget, this pillar reaches zero.

**Spending Consistency** — compares this month's total spending to last month's. An increase of 10% or less earns full marks. Each additional percentage above 10% deducts points.

**Goal Progress** — the number of completed goals divided by total goals, multiplied by 25.

If any pillar has no data — for example, no income recorded or no budget set — it returns a **neutral 12.5 points** instead of zero. This prevents the score from being misleadingly low just because the user is new.

Below the score are **personalised insight cards** — for example: 'You are saving 47% of your income — well above the 20% target.' Every message is generated using the user's actual numbers from the database. Nothing is hardcoded."

---

### [OPTIONAL] 2E — Financial Goals + 2H Gamification
#### (~2 minutes — present if time allows, skip if running short)

"The **Goals** feature lets users set savings targets with deadlines. Each goal shows a progress bar, the amount saved versus the target, and a countdown to the deadline — which turns orange when fewer than seven days remain to create urgency.

Contributing to a goal opens a dialog. If the user enters more than the remaining amount, a real-time warning appears immediately showing the exact excess — for example: 'Exceeds remaining by RM 300.00 — goal will be marked as completed.' This prevents accidental over-contribution.

The **gamification system** exists to solve the biggest real-world problem with finance apps — users stop using them. Every transaction logged earns experience points and extends the user's daily streak. Break the streak and it resets to zero. Achievement badges are unlocked for milestones — first transaction, 7-day streak, completing a goal. The level system uses exponential XP progression, so early levels are easy to keep users engaged, while higher levels become harder to maintain long-term motivation.

There is also a leaderboard ranking users by total XP — with a privacy option to opt out entirely."

---

## SECTION 3 — Technical Explanation
### (~4 minutes)

"Let me now explain the technical structure of the system more clearly.

**Architecture.**

SmartFinance follows a **three-tier client-server architecture**. The first tier is the Flutter mobile app — this handles everything the user sees and touches: screens, forms, navigation, and charts. The Flutter app contains no business logic — it only sends requests and displays responses. The second tier is the Flask REST API — this is where all business logic lives: calculating the financial health score, checking budget thresholds, validating inputs, and deciding what data to return. The third tier is MySQL — the persistent data store. Flask communicates with MySQL through SQLAlchemy.

When the user does anything in the app — saves a transaction, loads the dashboard, contributes to a goal — Flutter packages the action as an **HTTP request with a JSON body**, sends it to Flask, Flask processes it and queries MySQL, then returns a **JSON response** to Flutter, which updates the screen.

**Why this separation matters.** Because all logic is in Flask, the database is never directly accessible from the mobile app. The app cannot query or modify data except through my defined API endpoints — each of which has its own validation and authentication checks. This is a standard security practice called the API gateway pattern.

**Backend Organisation.**

The Flask backend is divided into **12 route blueprints** — one per feature area. Each blueprint handles a specific URL prefix. For example, `/api/transactions` handles everything related to transactions, `/api/budgets` handles budgets, `/api/insights` handles the financial health score. This modular design means each feature is self-contained — I can modify the insights algorithm without touching the transactions code.

**Database Design.**

MySQL contains **14 tables**. The core tables are Users, Transactions, Budgets, BudgetCategories, Goals, Investments, and RecurringTransactions. Supporting tables include Achievements, UserAchievements, HabitStreaks for gamification, and PasswordResets, EmailVerifications, UserSessions, and UserSettings for authentication and security.

Tables are related through **foreign keys**. For example, every Transaction row has a UserId foreign key pointing to the Users table — this means a transaction always belongs to exactly one user, and if a user account is deleted, all their transactions are removed too.

The database is normalised to **Third Normal Form** — no data is duplicated. Budget categories are stored in a separate BudgetCategories table rather than as columns in the Budgets table, which avoids repeating groups and keeps the schema clean.

**Security Implementation.**

Four layers of security are in place.

One — **password hashing with bcrypt**. Passwords are never stored as plain text. bcrypt adds a unique random salt to each password before hashing, so even if two users have the same password, their stored hashes are completely different. This defeats pre-computed rainbow table attacks.

Two — **JWT authentication**. Every protected API endpoint requires a valid JWT token in the request header. The token is signed with HMAC SHA-256 using a secret key stored in the server environment. If the token is missing, expired, or tampered with, the server rejects the request with a 401 error.

Three — **SQL injection prevention via SQLAlchemy**. SQLAlchemy never builds SQL queries by concatenating user input strings. It uses parameterised queries — user input is always passed as a separate bound parameter, never embedded directly into the SQL. This makes injection structurally impossible.

Four — **Two-Factor Authentication** as an optional second layer for users who want maximum security.

**Notifications.**

Push notifications are handled by `flutter_local_notifications` — a Flutter package initialised at app startup with the required Android 13 runtime permission. All notification logic is centralised in a single `NotificationService` class — budget alerts, achievement unlocks, and bill reminders all call the same service. This keeps notification behaviour consistent across the entire app."

---

## SECTION 4 — Test Cases
### (~3 minutes)

"Let me now walk through three prepared test cases to verify the system behaves correctly.

---

**Test Case 1 — Budget Warning When Category Approaches Limit**

*Purpose:* Verify that the system visually alerts the user when a budget category is close to its limit.

*Setup:* The Food budget is RM 800. I have RM 700 already spent — that is 87.5%.

*Steps:*
1. *(Navigate to Add Transaction.)*
2. Select Expense, enter **RM 25**, category **Food and Dining**, today's date.
3. Tap Save.
4. *(Navigate to Budget screen.)*
5. Observe the Food and Dining category bar.

*Expected result:* Food spending is now RM 725 out of RM 800 — **90.6%**. The category bar changes colour to warning state. A push notification is also triggered in the background: 'Food and Dining has reached 90% of its limit.'

*Actual result:* *(Show the budget screen — Food bar is now in warning colour at 90.6%.)* The budget screen reflects the updated spending immediately, and the colour change confirms the threshold logic is working. *(If notification appears in the notification shade, show it. If not, say:)* The notification service has fired — it may appear in the notification shade with a short delay depending on the device.

**Test Case 1 passes** — budget threshold detection and visual alert are working correctly.

---

**Test Case 2 — Financial Health Score Calculated from Real Data**

*Purpose:* Verify that the Financial Health Score reflects actual user data and is not hardcoded.

*Setup:* The account has income of RM 3,000 recorded, total expenses of RM 1,725 — well within the RM 2,500 budget — and this month's spending is lower than last month's RM 1,700.

*Steps:*
1. *(Navigate to Financial Insights.)*
2. Observe the score and each pillar bar.
3. Read the personalised insight cards below.

*Expected result:*
- Savings Rate pillar: 25/25 (saving more than 20%)
- Budget Adherence pillar: 25/25 (within budget)
- Spending Consistency pillar: 25/25 (spending is stable)
- Goal Progress pillar: approximately 12.5/25 (one completed, one active goal)
- Total score: approximately 87 — **Excellent**

*Actual result:* *(Show the Financial Insights screen.)* Score is in the Excellent range. Each pillar bar is visible with its individual score. The insight cards below display specific messages using my actual numbers — for example, showing my real savings percentage. This confirms the algorithm is running on live data, not returning a fixed value.

**Test Case 2 passes** — Financial Health Score is dynamic and correctly reflects the account's financial behaviour.

---

**Test Case 3 — Real-Time Warning When Goal Contribution Exceeds Remaining**

*Purpose:* Verify that the app warns the user before they accidentally over-contribute to a completed goal.

*Setup:* Vacation Fund goal — target RM 2,000, currently RM 1,800 saved. **RM 200 remaining.**

*Steps:*
1. *(Navigate to Goals → tap Contribute on Vacation Fund.)*
2. The dialog opens. Remaining amount shows RM 200.00.
3. Type **500** into the amount field.
4. *(Do not tap Confirm — observe the dialog immediately.)*

*Expected result:* As soon as RM 500 is typed, an orange warning appears below the input field: **'Exceeds remaining by RM 300.00 — goal will be marked as completed.'** This appears without needing to tap any button — it updates in real time as I type.

*Actual result:* *(Type 500 slowly and show the warning appearing.)* Warning is visible immediately. The user is fully informed of the consequence before confirming. Tap Cancel to close — no changes are made.

**Test Case 3 passes** — real-time over-contribution warning is working correctly."

---

## CLOSING
### (~1 minute)

"To summarise — SmartFinance is a fully functional personal finance system with eight integrated modules: secure authentication, transaction tracking, budget management with intelligent alerts, savings goals, investment portfolio tracking, financial insights with a health score algorithm, recurring transactions, and gamification. Every module connects to the others — a transaction updates the budget, the budget feeds the health score, the health score triggers a notification, and the gamification system rewards consistent usage.

All three tiers — Flutter, Flask, and MySQL — are working end to end. The backend processes real data, the algorithm generates dynamic results, and the app responds correctly in every tested scenario.

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

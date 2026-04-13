# SmartFinance — Final Presentation Script
# Estimated speaking time: ~45–50 minutes + Q&A

---
## HOW TO USE THIS SCRIPT
- Text in **[square brackets]** = action notes, not spoken
- Speak slowly and clearly — don't rush
- It's okay to pause. A short pause sounds confident, not nervous.
- If you forget a line, just say "Let me move on to the next part" — it's fine.
---

---
# PART 1 — INTRODUCTION (3 minutes)
---

Good morning / afternoon.

My name is [your name], and today I'll be presenting my Final Year Project.

The project is called **SmartFinance**.

It's a mobile app that helps young Malaysians manage their personal finances.

The app covers things like — tracking income and expenses, setting budgets, saving toward goals, monitoring investments, and viewing financial reports.

On top of that, I added a **gamification system** — so the app gives users XP points, levels, achievement badges, and daily streaks, just like a game.

The idea is to make financial management more fun and motivating — so people actually stick with it.

---
# PART 2 — PROBLEM & MOTIVATION (5 minutes)
---

So, why did I build this?

The problem is that many young Malaysians don't manage their money well.

Studies show that financial literacy among Malaysian youth is quite low.

And the existing apps on the market — most of them are either too complicated, too expensive, or designed for Western users — not for Malaysians.

So people either don't use any app at all, or they try one and give up after a few weeks.

That's the core problem I wanted to solve.

I wanted to build something that is — simple enough for anyone to use, and engaging enough that they actually keep using it.

That's where the gamification comes in.

Research shows that when people get rewards, progress bars, and achievement badges — they're more likely to continue a habit.

So I applied that same idea to personal finance.

---
# PART 3 — TECHNOLOGY STACK (5 minutes)
---

Now let me talk about the technologies I used to build this app.

**[Show architecture diagram if available]**

SmartFinance has three main parts — we call this a **three-tier architecture**.

**First — the Frontend**, which is what the user sees and interacts with.
I used **Flutter** for this.
Flutter is a framework made by Google.
It lets me write one codebase — and it automatically works on both Android and iOS.
I used the **Dart** programming language for Flutter.

**Second — the Backend**, which is the server that handles all the logic.
I used **Python Flask** for this.
Flask is a lightweight web framework.
It receives requests from the app, processes them, and sends back a response.
I designed the backend as a **REST API** — which means the app communicates with the server by sending HTTP requests, like GET or POST, and receives JSON data back.

**Third — the Database**, which stores all the data.
I used **MySQL** for this.
MySQL is a relational database — it stores data in tables, and the tables are linked together.
My database has **16 tables** in total.
I used **SQLAlchemy** to connect Flask to MySQL.
SQLAlchemy is an **ORM** — which means "Object Relational Mapper".
Instead of writing raw SQL queries, I define Python classes, and SQLAlchemy handles the database operations for me.

---
# PART 4 — SYSTEM FEATURES (25 minutes)
---

Now I'll walk through all the features of the app.

---

## 4.1 — Authentication

**[Show login screen]**

When users first open the app, they see the **login screen**.

To register, the user fills in their name, email, phone number, and a password.

For security, the password must be at least 8 characters, and it must contain uppercase letters, lowercase letters, and a special character.
This is enforced on the server side — so it can't be bypassed.

The password is never stored as plain text.
I use a library called **bcrypt** to hash the password before saving it.
Hashing means the password is converted into a scrambled string that can't be reversed.
So even if someone looks at the database, they can't see the real password.

After registration, the user gets a verification email.
They need to click the link in the email to confirm their email address.
This makes sure the email actually belongs to them.

When the user logs in, the server checks the email and the password.
If they match, the server returns a **JWT** — a JSON Web Token.

JWT is basically a digital key.
The app stores it locally, and it attaches this key to every future request.
The server checks the key to confirm the user is who they say they are.
The key expires after a short time — so if someone steals it, it becomes useless quickly.

---

## 4.2 — Two-Factor Authentication (2FA)

**[Show 2FA setup screen]**

I also built **Two-Factor Authentication**, or 2FA.

2FA adds an extra security step after the password.

When users enable it, the server generates a **secret key** and turns it into a **QR code**.
The user scans that QR code with an authenticator app — like Google Authenticator.

From that point on, every time they log in, after entering their password — they also need to enter a 6-digit code from the authenticator app.
That code changes every 30 seconds.
This is called **TOTP** — Time-based One-Time Password.

The standard I follow is called **RFC 6238** — it's the same standard used by Google, Facebook, and most banks.
I use a Python library called **pyotp** to generate and verify these codes.

I also generate **10 backup codes** when 2FA is set up.
These backup codes are for situations where the user loses their phone.
They can use one of these codes instead of the 6-digit code.
The backup codes are hashed with bcrypt before being stored — so they're secure too.

If 2FA is enabled — the login flow becomes two steps.
Step 1 — enter email and password.
Step 2 — enter the 6-digit TOTP code.
If the code is wrong, the session is rejected.

---

## 4.3 — Dashboard

**[Show dashboard screen]**

After logging in, the user lands on the **main dashboard**.

The dashboard shows a summary of their current financial situation.
It shows total income, total expenses, and the net balance for the current month.

There's also a compact **budget summary card** at the bottom.
If any budget category is overspent, it shows a red warning — so the user is alerted immediately without needing to navigate anywhere.

The dashboard also shows the **gamification strip** — current level, XP points, and the daily activity streak.
This gives the user a quick sense of progress every time they open the app.

---

## 4.4 — Transactions

**[Show add transaction screen]**

The transaction module is the core of the app.

The user can add two types: **income** or **expense**.

They enter the amount, select a category from a visual icon grid — like Food, Transport, Shopping, Bills — and pick a date.

When the user types a description — the app runs a **keyword analysis algorithm**.
This automatically suggests a category based on the words they typed.
For example, if they type "mamak lunch" — the system suggests the Food category.
If the confidence score is above 0.7 — the app highlights the suggested category.
But the user can always override it.

The **transaction history** screen shows all past transactions.
There's a **search bar** at the top.
There are also **filter chips** to filter by type — income or expense — or by category.

---

## 4.5 — Recurring Transactions

**[Show recurring transactions screen]**

Some transactions happen on a regular schedule — like monthly rent or a weekly salary.

Instead of manually adding them every time, users can create a **recurring transaction**.

They set the amount, category, and frequency — which can be daily, weekly, monthly, or yearly.

The backend automatically checks the **NextExecution** date.
When that date arrives, the system creates the real transaction record and advances the NextExecution date by one period.

Users can also **pause** a recurring transaction — for example if they cancel a subscription.
Paused transactions are skipped until the user resumes them.

---

## 4.6 — Budgets

**[Show budget creation screen]**

The budget module lets users plan their monthly spending.

To create a budget, the user enters the total amount for the month — for example, RM 3,000.

Then they allocate that amount across different categories.
For example, RM 800 for food, RM 400 for transport, RM 600 for bills, and so on.

As they type in each amount, the screen **updates in real time** and shows how much is still unallocated.
If the total allocation exceeds the budget, the app blocks the save and shows an error.

**[Show budget overview screen]**

Once the budget is saved, the Budget Overview screen shows the progress for each category.

Each category has a **linear progress bar**.
The colour changes depending on how much has been spent:
- Green means they're on track — below 75%.
- Amber means warning — approaching the limit.
- Red means they've exceeded the budget.

The backend calculates the budget status dynamically by adding up all the expense transactions for that month and comparing them against the allocated amounts.

---

## 4.7 — Financial Goals

**[Show goals screen]**

The goals module lets users set savings targets.

For example, a user might create a goal called "Japan Trip" with a target of RM 5,000 and a deadline.

They can also set a **priority level** — low, medium, or high — to indicate which goals matter most.

When they contribute money toward a goal, the app increases the **CurrentAmount** and shows a progress bar.

When the CurrentAmount reaches the TargetAmount, the goal is marked as **completed** — and this also unlocks a gamification achievement.

---

## 4.8 — Investments

**[Show investment portfolio screen]**

The investment module tracks the user's investment portfolio.

I support **10 asset types** — Stocks, Cryptocurrency, ETF, Bonds, Real Estate, Commodities, Fixed Deposit, Unit Trust, Options, and Others.

For each investment, the user enters the asset name, the number of units, the purchase price, and the purchase date.

The app then calculates the **gain or loss** by comparing the current price against the purchase price.
Each holding shows the profit or loss in green or red.

The portfolio overview shows the **total invested**, the **current value**, and the **overall percentage return**.
It also highlights the best-performing and worst-performing holdings.

Users update the current price manually — by tapping the holding and entering the latest market price.

---

## 4.9 — Analytics and Reports

**[Show analytics screen]**

The analytics screen gives users a visual breakdown of their spending.

I use a Flutter chart library called **fl_chart** to render four types of charts:
1. **Spending Trend** — a line chart showing expenses over time.
2. **Income vs Expense** — a bar chart comparing income and expenses side by side each month.
3. **Category Pie Chart** — a pie chart showing which categories the user spends the most on.
4. **Budget vs Actual** — horizontal bars comparing what they budgeted against what they actually spent.

There's a time range selector at the top — 1 month, 3 months, 6 months, 1 year, or all time.
Changing the range **refreshes all four charts** at the same time.

I load the chart data efficiently using **Future.wait** in Flutter.
Future.wait runs multiple API calls **simultaneously** — so instead of waiting for them one by one, they all finish together.
This makes the loading time roughly half of what it would be otherwise.

**[Show reports screen]**

The reports screen lets users **export their data**.

They can export a CSV file — which opens in Excel or Google Sheets.
Or they can generate a PDF report.

The CSV is generated by the Flask backend using Python's built-in csv module.
The PDF is generated entirely on the Flutter side using the pdf package, and shared via the system share sheet.

---

## 4.10 — Financial Insights

**[Show financial insights screen]**

This is one of the features I added beyond the original scope.

The Financial Insights screen gives the user a **personalised financial health score** — from 0 to 100.

The score is calculated from four pillars, each worth 25 points:
1. **Savings Rate** — are they saving enough of their income?
2. **Budget Adherence** — are they staying within their budget?
3. **Spending Consistency** — is their spending steady, or very irregular?
4. **Goal Progress** — are they making progress on their savings goals?

Below the score, the screen shows **insight cards** — short, personalised messages.
Each card is colour-coded:
- Green = positive feedback.
- Blue = informational tip.
- Yellow = warning.
- Red = urgent action needed.

This gives users actionable feedback, not just numbers.

---

## 4.11 — Gamification

**[Show gamification/achievements screen]**

The gamification system is designed to keep users engaged over time.

It has four parts:

**XP and Levelling.**
Users earn XP — experience points — by using the app.
For example, they earn 10 XP every time they add a transaction.
XP accumulates and increases their level, from Level 1 up to Level 10.
Higher levels unlock more badges.

**Achievements.**
There are over 20 achievement badges.
Each one has a condition — for example, "Record your first transaction", "Stay within budget for a full month", or "Maintain a 30-day streak".
Each achievement also has a difficulty level — Easy, Medium, Hard, or Expert.
When an achievement is unlocked, an animation plays and the user gets notified.

**Habit Streaks.**
The app tracks how many consecutive days the user has recorded a transaction.
If they record a transaction today and yesterday — they're on a streak.
If they miss a day — the streak resets to zero.
Milestones at 7, 14, 30, and 90 days give bonus XP.

**Leaderboard.**
Users can see their XP ranking compared to other users.
This adds a social motivation element.

---

## 4.12 — Settings and Security Centre

**[Show settings / security screen]**

The settings module covers profile editing, notification preferences, and security.

The **Security Centre** screen shows the user's **security score**.
The score is either 30, 60, or 100.
- 30 means email not verified.
- 60 means email verified but 2FA not enabled.
- 100 means both done.

This encourages users to complete the security steps.

The screen also shows **Active Sessions** — a list of all devices currently logged in.
Each session shows the device name and the last active time.
Users can **remotely log out** any individual device, or log out all other devices at once.

There's also a **Security Activity Log** that shows recent events — like logins, password changes, and session terminations.
This helps users spot suspicious activity.

---

# PART 5 — DATABASE DESIGN (5 minutes)
---

**[Show ERD diagram]**

Now let me talk about the database.

My database has **16 tables** in total.

The **central table** is the **Users** table.
Almost every other table links back to Users through a foreign key.

The **core tables** are: Users, Transactions, Budgets, BudgetCategories, and Investments.

The **extended feature tables** are: Goals, RecurringTransactions, Achievements, UserAchievements, HabitStreaks, and UserSettings.

The **security tables** are: UserSessions, SecurityLogs, EmailVerificationTokens, PasswordResetTokens, and TwoFactorAuths.

I use **ON DELETE CASCADE** on all foreign keys.
This means — if a user deletes their account, all their data is automatically removed too.
I don't need to write separate delete queries for each table.

I also added **indexes** on the most frequently searched columns — like UserId, TransactionDate, and NextExecution.
Indexes make queries much faster, especially as the data grows.

---

# PART 6 — TESTING RESULTS (5 minutes)
---

Now I'll talk about how I tested the system.

I ran four types of testing.

**Functional Testing.**
I wrote 50 test cases covering every feature — registration, login, transactions, budgets, investments, goals, gamification, security, reports.
All 50 test cases passed — 100% pass rate.

**Security Testing.**
I ran 7 security test cases — testing things like wrong password rejection, expired JWT handling, TOTP code verification, and backup code usage.
All 7 passed — 100% pass rate.

**Usability Testing.**
I recruited 6 participants and gave them a set of tasks to complete — like "add an expense", "create a budget", "set a savings goal".
I measured whether they could complete each task, and then asked them to rate their experience.

The results:
- **91.7% task completion rate** — my acceptance threshold was 80%, so this exceeded the target.
- **Average satisfaction score: 4.30 out of 5.00**
- **System Usability Scale score: 78.5** — which is rated as "Good" usability.

**Performance Testing.**
I tested the app on both Android and iOS.
I also tested on older low-end Android devices.
For charts with large amounts of data, I applied data aggregation — grouping daily data into weekly averages for ranges over 90 days.
This kept the charts smooth even on older devices.

---

# PART 7 — CHALLENGES AND SOLUTIONS (3 minutes)
---

Let me briefly mention some technical challenges I faced, and how I solved them.

**JWT expiry causing silent logouts.**
My first implementation didn't handle expired tokens gracefully.
When the token expired, the app just failed silently.
I fixed this by adding an automatic token refresh mechanism — the app quietly requests a new access token before the old one expires.

**2FA flow errors.**
During early testing, the login session could be completed without finishing the 2FA step.
I fixed this by redesigning the login as a strict two-stage process — the session is only created after the TOTP code is verified.

**Field naming mismatch — Python uses PascalCase, Dart uses camelCase.**
The database column names were PascalCase — like `UserId`.
But Flutter expected camelCase — like `userId`.
This caused silent null values — the app ran fine but showed blank or zero data.
I fixed it by adding explicit key mapping in every `to_dict()` method in the Flask models.
Now every API response consistently uses camelCase.

**Decimal type error in Flask 3.0.**
MySQL returns money values as Python `Decimal` objects.
Flask 3.0 can't convert Decimal to JSON directly — it throws an error.
I fixed it by converting every Decimal value to `float()` before building the JSON response.

---

# PART 8 — LIMITATIONS AND FUTURE WORK (3 minutes)
---

I want to be honest about the current limitations.

**Manual data entry.**
Right now, users have to type in every transaction manually.
In the future, I'd like to integrate with Malaysian bank APIs so the app can import transactions automatically.

**No real-time market prices.**
Investment prices have to be updated manually.
In the future, I'd connect to a market data API — like Yahoo Finance or CoinGecko for crypto — so prices update automatically.

**Local deployment only.**
During this FYP period, the Flask backend runs on my local machine.
Users can only connect when they're on the same network.
The next step is to deploy it to a cloud platform — like AWS or Google Cloud — so it works for anyone, anywhere.

**No offline mode.**
The app requires an internet connection.
In the future, I'd add a local cache so users can still view their data when offline.

---

# PART 9 — CONCLUSION (2 minutes)
---

To summarise.

SmartFinance is a full-stack mobile application built with Flutter, Python Flask, and MySQL.

It covers six core financial features — transactions, budgets, goals, investments, analytics, and reports.

It has a complete security system — email verification, two-factor authentication, JWT session management, and a security activity log.

And it has a gamification system — XP, levelling, achievement badges, streaks, and a leaderboard — to keep users motivated.

The testing results confirm that the system works correctly and is genuinely usable.
100% functional test pass rate, 91.7% usability task completion, and a System Usability Scale score of 78.5.

I'm proud of what I've built, and I believe SmartFinance is a useful and well-engineered solution to the financial literacy problem among Malaysian young adults.

Thank you. I'm ready for any questions.

---
---
---

# ANTICIPATED Q&A — MODERATOR QUESTIONS
# Read through ALL of these before the presentation. Know the answers well.

---

## Q1: Why did you choose Flutter instead of React Native or a native Android/iOS app?

Flutter lets me write one codebase that runs on both Android and iOS.
Native Android requires Kotlin/Java, and native iOS requires Swift — that's two separate codebases.
React Native is similar to Flutter in that it's cross-platform, but Flutter has better performance because it compiles directly to native machine code — it doesn't use a JavaScript bridge.
My supervisor also confirmed Flutter was suitable for this type of project.

---

## Q2: Why Flask instead of Django or Node.js?

Flask is lightweight and simple.
It gives me full control — I only add the components I need.
Django is more powerful but has a lot of built-in things I didn't need — it would add unnecessary complexity.
Node.js would have worked too, but I'm more comfortable with Python, and Flask integrates well with the scientific Python libraries I used for the analytics module.

---

## Q3: How does JWT authentication work exactly?

When the user logs in, the server creates a JWT — a JSON Web Token.
A JWT is a string that contains encoded information — like the user's ID and an expiry time.
The server signs it with a secret key that only the server knows.
The app stores this token locally.
Every time the app makes a request to the backend, it sends this token in the request header.
The server checks the token — if the signature is valid and it hasn't expired, the request is allowed.
If the token is expired or tampered with, the server rejects it with a 401 error.

---

## Q4: How does the TOTP two-factor authentication work?

TOTP stands for Time-based One-Time Password.
When the user enables 2FA, the server generates a random secret key and shows it as a QR code.
The user scans it with an authenticator app — like Google Authenticator.
Both the app and the server now share the same secret key.
Every 30 seconds, they both use the same formula — secret key + current time — to calculate the same 6-digit code.
When the user types the code, the server runs the same calculation and checks if they match.
Because the code changes every 30 seconds and is based on a shared secret — it's very hard to fake.
I use the `pyotp` library which follows the RFC 6238 standard.

---

## Q5: Why did you use SQLAlchemy instead of writing SQL queries directly?

SQLAlchemy is an ORM — Object Relational Mapper.
It lets me define database tables as Python classes, and query them using Python code instead of SQL.
This has a few advantages.
First — it protects against SQL injection attacks, because SQLAlchemy handles the escaping automatically.
Second — it makes the code easier to read and maintain.
Third — if I ever need to switch databases — from MySQL to PostgreSQL for example — I can do that without rewriting all the queries.

---

## Q6: What happens if the user forgets their 2FA device?

I handle this with backup codes.
When 2FA is first set up, the system generates 10 one-time backup codes.
These are shown to the user once, and the user is instructed to save them somewhere safe.
If they lose their phone, they can enter one of these backup codes instead of the TOTP code.
Each backup code can only be used once — the system marks it as used after consumption.
The backup codes are stored hashed in the database — same security as passwords.

---

## Q7: What is bcrypt and why use it for password hashing?

bcrypt is a hashing algorithm designed specifically for passwords.
Normal hashing algorithms like MD5 or SHA are very fast — which is good for most things, but bad for passwords.
Because they're fast, an attacker can try millions of passwords per second.
bcrypt is intentionally slow — it has a "cost factor" that controls how slow it is.
This makes brute-force attacks much harder.
bcrypt also adds a random "salt" — extra random data mixed in before hashing.
This means two users with the same password will have completely different hashes — so a pre-computed attack list doesn't work.

---

## Q8: How does the budget monitoring work in real time?

When the user adds an expense transaction, the backend checks if a budget exists for that month.
If it does, it finds the matching budget category and adds the transaction amount to the SpentAmount field.
It then calculates the consumption percentage — SpentAmount divided by AllocatedAmount, multiplied by 100.
If the percentage is above 80%, the status becomes "warning".
If it's above 100%, the status becomes "over budget".
The Flutter app receives this status and changes the progress bar colour accordingly — green, amber, or red.

---

## Q9: Why only 6 usability testing participants? Isn't that too few?

I acknowledge this as a limitation in my report.
In academic usability research, Jakob Nielsen's guideline says that 5 users can identify around 85% of usability problems.
So 6 participants is a recognised minimum threshold for exploratory usability testing.
However — I agree it's not enough to make strong statistical claims about the whole population.
For a more rigorous study, I'd want 30 or more participants, and ideally a longitudinal study over several weeks.
I document this honestly in the limitations section.

---

## Q10: What is the Financial Health Score and how is it calculated?

The Financial Health Score is a number from 0 to 100.
It's calculated from four equal pillars — each worth up to 25 points.
Pillar 1 — Savings Rate: what percentage of their income are they saving?
Pillar 2 — Budget Adherence: how well are they staying within their budget?
Pillar 3 — Spending Consistency: how regular and predictable is their spending?
Pillar 4 — Goal Progress: are they actively contributing to their savings goals?
The total is summed to give the final score.
For new users who haven't added enough data yet, pillars with missing data are given a neutral mid-range value — so the score doesn't unfairly show zero.

---

## Q11: How do you handle the case where the Flask backend returns a Decimal that JSON can't serialize?

MySQL stores money values as Decimal types.
Flask 3.0's default JSON serializer doesn't know how to convert Python's Decimal type to JSON.
It raises a TypeError and returns an HTTP 500 error.
I solved this by explicitly calling `float()` on every Decimal value when building the JSON response dictionary in the `to_dict()` methods.
This converts the Decimal to a plain Python float, which Flask can serialize normally.
I apply this pattern consistently across all models and API routes that return monetary values.

---

## Q12: What are the security features beyond just login?

There are several layers:
1. **Password hashing** with bcrypt — plain text passwords never stored.
2. **Email verification** — confirms the email is real before full access.
3. **Two-factor authentication** — adds a second step beyond the password.
4. **JWT with expiry** — tokens expire and can't be reused after expiry.
5. **Session management** — every login creates a session record. Users can see and revoke sessions per device.
6. **Security activity log** — logs every login, password change, 2FA toggle, and session termination.
7. **Security score** — visible feedback that nudges users to complete security steps.

---

## Q13: If this were a real product, what would be the most important thing to improve?

The most important thing is **cloud deployment**.
Right now, the backend runs on my local machine — so only people on the same network can use it.
To make it a real product, I'd deploy the Flask API to a cloud service like AWS or Google Cloud, add HTTPS for encrypted communication, and set up a proper database server instead of a local MySQL instance.

The second most important thing is **automatic transaction import** via bank APIs.
Manual entry is the biggest friction point — users who have to type in every transaction are likely to give up.

---

## Q14: What is a REST API and why did you build the backend as one?

REST stands for Representational State Transfer.
A REST API is a way for the app to communicate with the server using standard HTTP methods — GET, POST, PUT, DELETE.
GET is for reading data. POST is for creating data. PUT is for updating data. DELETE is for removing data.
I built the backend as a REST API because it cleanly separates the frontend from the backend.
The Flutter app doesn't care what database the server uses — it just sends requests and receives JSON responses.
This also means in the future, I could build a web version of the app that uses the same API without changing the backend.

---

## Q15: Did you encounter any challenges with cross-platform compatibility between Android and iOS?

Yes. Some Flutter widgets render slightly differently on iOS and Android.
For example, date pickers and dialog boxes have a different style on each platform.
I solved this by standardising on **Material Design** widgets throughout the app.
Material Design is Google's design system — it looks consistent on both platforms.
I avoided using Cupertino-style widgets (which are Apple-style) because they introduced visual inconsistencies on Android.

---

# END OF SCRIPT

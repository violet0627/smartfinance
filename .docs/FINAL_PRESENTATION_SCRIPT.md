# SmartFinance — Final Presentation Script
# Format: Live demo on Android emulator
# Estimated time: ~50–55 minutes speaking + Q&A

---
## HOW TO USE THIS SCRIPT
- Text in [square brackets] = what to DO on the emulator — not spoken
- Speak slowly. Pause between sections. Don't rush.
- If you lose your place, just say "let me continue with the next feature" — it's fine.
- The moderator is watching the screen, so describe what they're seeing as you go.
---

---
# PART 1 — INTRODUCTION (3 minutes)
# [App is closed. You're about to open it.]
---

Good morning / good afternoon.

My name is [your name], and today I'll be presenting my Final Year Project — **SmartFinance**.

SmartFinance is a mobile app for personal finance management.

It's designed for young Malaysians who want to track their income and expenses, set budgets, save toward goals, and monitor their investments.

What makes it different from a regular finance app is the **gamification system**.

The app gives users XP points, levels, achievement badges, and daily streaks — like a game.

The purpose is to make financial management more engaging, so people actually keep using it.

I built this as a full-stack system.

The frontend is built with **Flutter** — a framework by Google that lets one codebase run on both Android and iOS.

The backend is built with **Python Flask** — a lightweight web framework that handles all the server-side logic.

The database is **MySQL** — a relational database that stores all the user data.

The frontend communicates with the backend through a **REST API** — meaning the app sends HTTP requests and receives JSON responses back.

The backend has **12 route modules** covering over 50 API endpoints.

The database has **16 tables** in total.

Now let me show you the app.

---
# PART 2 — REGISTRATION (4 minutes)
# [Open the emulator. App should be on the login screen.]
---

This is the **login screen**.

The app opens here every time a user hasn't logged in yet.

Let me first show you the **registration flow**.

[Tap "Create Account"]

This is the **registration screen**.

The user enters their full name, email address, an optional phone number, a password, and a confirmation password.

[Fill in the registration form with test data]

For security, the password rules are enforced **on the server side** — not just in the app.

The password must be at least 8 characters, contain uppercase letters, lowercase letters, and a special character.

This is done server-side so that even if someone modifies the app, they can't bypass the rules.

The password is never stored as plain text.

I use **bcrypt** to hash the password before saving it to the database.

Hashing means the password is converted into a scrambled, irreversible string.

So even if someone looks directly at the database, they can't see the real password.

[Tap "Create Account"]

After registering, the system sends a **verification email** to the user's email address.

The user needs to click the link in that email to verify their account.

This confirms the email address actually belongs to them.

---
# PART 3 — LOGIN AND 2FA (5 minutes)
# [Go back to login screen. Log in with existing test account.]
---

Now let me log in with an existing test account.

[Enter email and password, tap Sign In]

When the user logs in, the backend checks the email and the hashed password.

If they match, the server returns a **JWT** — a JSON Web Token.

JWT is basically a digital key.

The app stores it locally, and attaches it to every future request to the backend.

The server checks this key to confirm the user is who they say they are.

The token expires after a short time — so if someone steals it, it becomes invalid quickly.

Now let me show you **Two-Factor Authentication**.

[Navigate to Settings → Security → Two-Factor Authentication]

This is the 2FA setup screen.

When the user enables 2FA, the server generates a **secret key** and displays it as a **QR code**.

The user scans the QR code with an authenticator app — like Google Authenticator.

From that point on, every time they log in — after entering the password, they also need to enter a **6-digit code** from the authenticator app.

That code changes every 30 seconds.

This is called **TOTP** — Time-based One-Time Password.

The standard I follow is **RFC 6238** — the same standard used by Google and most banks.

I use a Python library called **pyotp** to generate and verify these codes.

I also generate **10 backup codes** during setup.

These are for situations where the user loses their phone.

Each backup code can only be used once.

The backup codes are hashed with bcrypt before being stored — same security as passwords.

So if 2FA is enabled — login has two steps.

Step 1 — email and password.

Step 2 — 6-digit TOTP code.

If the code is wrong, the session is rejected.

---
# PART 4 — DASHBOARD (3 minutes)
# [Navigate to the main dashboard / home screen]
---

This is the **main dashboard**.

It's the first screen the user sees after logging in.

At the top, it shows the current month's **financial summary** — total income, total expenses, and the net balance.

Below that, there's a compact **budget summary card**.

If any budget category is overspent, this card immediately shows a red warning — so the user is alerted without needing to navigate anywhere.

At the bottom, the **gamification strip** shows the user's current level, XP points, and their daily activity streak.

This gives a quick sense of progress every time they open the app.

---
# PART 5 — TRANSACTIONS (6 minutes)
# [Navigate to Transactions or tap Add Transaction]
---

Now let me show the **transaction module**.

This is the core feature of the app.

[Tap the add transaction button / FAB]

This is the **Add Transaction screen**.

The user can add two types — **income** or **expense**.

[Show the income/expense toggle]

They switch between them using this toggle at the top.

[Enter an amount]

They enter the amount here.

[Type a description]

When they type a description, the app runs a **keyword analysis algorithm**.

This automatically suggests a category based on the words they typed.

For example, if I type "lunch at mamak" — the system suggests the Food category.

The confidence threshold is 0.7 — if the algorithm is more than 70% confident, it highlights the suggested category.

But the user can always tap a different category if the suggestion is wrong.

[Show the category icon grid]

These are the category icons.

The user selects one by tapping it.

[Select a date]

They also pick a date — it defaults to today.

[Tap Save Transaction]

When saved, the backend:
- Creates the transaction record in the database.
- If it's an expense, it updates the **budget spending amount** for that category.
- It awards **10 XP** to the user for logging a transaction.
- It updates the **habit streak**.
- It checks if any **achievement** criteria has been met.

[Navigate to Transaction History]

This is the **Transaction History screen**.

It shows all past transactions.

At the top is a **search bar** — the user can search by description.

These are **filter chips** — the user can filter by income, expense, or by specific category.

Each card shows the category icon, description, amount, and date.

Income transactions are shown in green, expenses in red.

---
# PART 6 — RECURRING TRANSACTIONS (3 minutes)
# [Navigate to Recurring Transactions screen]
---

This is the **Recurring Transactions** screen.

Some transactions happen on a fixed schedule — like monthly rent or a weekly salary.

Instead of manually adding them every time, the user creates a **recurring transaction template**.

[Show an existing recurring transaction]

For example, this is a monthly rent of RM 1,200 set to repeat every 1st of the month.

The backend stores a **NextExecution** date for each recurring transaction.

Every time the app checks in, the backend compares NextExecution against today's date.

If the date has passed, it automatically creates the real transaction and advances NextExecution to the next period.

Users can also **pause** a recurring transaction — for example, if they cancel a subscription.

Paused ones are skipped until the user resumes them.

---
# PART 7 — BUDGETS (5 minutes)
# [Navigate to Budget screen]
---

This is the **Budget module**.

[Show the Budget Overview screen]

This is the **Budget Overview**.

It shows the current month's budget at the top — total budget, total spent, and remaining.

Below that, each category has a **progress bar**.

The colour changes based on spending:
- **Green** means on track — below 75% spent.
- **Amber** means warning — getting close.
- **Red** means over budget.

[Navigate to Create Budget, or tap Edit]

This is the **Budget Creation screen**.

The user enters a **total budget amount** — for example, RM 3,000.

Then they allocate that amount to each category — for example, RM 800 for food, RM 400 for transport, RM 600 for bills.

[Point to the remaining counter]

As they type, this counter updates in real time and shows how much is still unallocated.

If the total allocation exceeds the budget, the app shows an error and won't let them save.

This validation is done on both the app side and the server side.

The budget status is calculated **dynamically** by the backend.

It sums up all expense transactions for the current month in each category and compares them against the allocated amounts.

---
# PART 8 — FINANCIAL GOALS (3 minutes)
# [Navigate to Goals screen]
---

This is the **Goals module**.

[Show the Goals Overview screen]

Users can create savings goals — for example, saving RM 5,000 for a holiday.

[Show or create a goal]

Each goal has a name, a target amount, a deadline, and a **priority level** — low, medium, or high.

The progress bar shows how much has been saved so far.

[Show the contribute button or flow]

When the user contributes money toward a goal, the CurrentAmount goes up and the progress bar fills.

When the goal is fully funded — the status changes to **completed**, and the user earns a gamification achievement.

---
# PART 9 — INVESTMENTS (5 minutes)
# [Navigate to Investment Portfolio screen]
---

This is the **Investment Portfolio screen**.

[Show the portfolio summary card]

At the top, there's a summary card showing:
- Total amount invested
- Current portfolio value
- Overall gain or loss, and the percentage return

[Show the holdings list]

Below that is the list of individual holdings.

Each one shows a **type-based icon**, the asset name, the current value, and the gain or loss in green or red.

I support **10 asset types** — Stocks, Cryptocurrency, ETF, Bonds, Real Estate, Commodities, Fixed Deposit, Unit Trust, Options, and Others.

[Tap the add investment button]

This is the **Add Investment screen**.

At the top is the **asset type grid** — the user selects which type their investment is.

Then they fill in the asset name, stock symbol if applicable, quantity, purchase price, and purchase date.

The app **automatically calculates the total** — quantity multiplied by purchase price.

[Show the total calculation]

They can also add optional notes.

When saved, the backend sets the current price equal to the purchase price initially.

The user then updates the current price manually over time by tapping the holding and entering the latest price.

---
# PART 10 — ANALYTICS (4 minutes)
# [Navigate to Analytics screen]
---

This is the **Analytics screen**.

It gives the user a visual breakdown of their financial data.

I use a Flutter chart library called **fl_chart** to render the charts.

[Show the charts one by one]

There are four chart types:

**Spending Trend** — a line chart showing expenses over time.

**Income vs Expense** — a bar chart comparing income and expenses month by month.

**Category Pie Chart** — a pie chart showing which categories the user spends the most on. Tapping a slice shows the exact amount.

**Budget vs Actual** — horizontal bars comparing the allocated budget against actual spending per category.

[Show the time range selector]

At the top is a time range selector — 1 month, 3 months, 6 months, 1 year, or all time.

Changing this **refreshes all four charts at the same time**.

I do this efficiently using **Future.wait** in Flutter.

Future.wait runs multiple API calls **simultaneously** — so instead of loading them one by one, they all load together.

This roughly halves the loading time.

---
# PART 11 — REPORTS AND EXPORT (3 minutes)
# [Navigate to Reports screen]
---

This is the **Reports screen**.

[Show the three tabs]

There are three tabs — Spending Report, Budget Report, and Category Analysis.

[Show the time period filter]

The user can filter by time period — this month, last month, last 3 months, last 6 months, or this year.

[Show the export buttons]

At the bottom are two export buttons — **CSV** and **PDF**.

The CSV is generated by the Flask backend using Python's built-in csv module, and the file is returned as a downloadable stream.

The PDF is generated entirely on the Flutter side using the pdf package, then shared via the system share sheet — so the user can save it or send it to someone.

---
# PART 12 — FINANCIAL INSIGHTS (3 minutes)
# [Navigate to Financial Insights screen]
---

This is the **Financial Insights screen** — one of the features I added beyond the original scope.

[Show the health score]

This is the **Financial Health Score** — a number from 0 to 100.

It's calculated from four pillars, each worth up to 25 points:

1. **Savings Rate** — what percentage of income is being saved.
2. **Budget Adherence** — how well they're staying within budget.
3. **Spending Consistency** — how regular and predictable their spending is.
4. **Goal Progress** — are they contributing to savings goals.

[Show the insight cards]

Below the score are **personalised insight cards**.

Each card is colour-coded:
- Green means something positive — like "You're saving well this month."
- Blue is informational.
- Yellow is a warning.
- Red is urgent — like "You've exceeded your food budget."

These give the user actionable feedback, not just numbers.

[Show pull to refresh]

Pulling down refreshes the full report with the latest data.

---
# PART 13 — GAMIFICATION (4 minutes)
# [Navigate to Gamification / Achievements screen]
---

This is the **Achievements screen**.

[Show the achievements grid]

There are over 20 achievement badges.

Each one has a name, a description, a difficulty level — Easy, Medium, Hard, or Expert — and an XP reward.

[Show a locked and an unlocked achievement]

Locked ones are shown in grey.

Unlocked ones show the badge in colour, with the date it was earned.

[Show the progress bar on a partially-completed achievement]

Some achievements also show a progress bar — so the user can see how close they are.

When an achievement is unlocked, an animation plays and the user gets a notification.

There are also **XP and levels** — users start at Level 1 and go up to Level 10.

Every transaction, goal contribution, and budget action earns XP.

The **habit streak** tracks how many consecutive days the user has recorded a transaction.

Miss a day and the streak resets to zero.

Milestones at 7, 14, 30, and 90 days give bonus XP.

And there's a **leaderboard** that shows the user's XP ranking compared to other users.

---
# PART 14 — SETTINGS AND SECURITY (4 minutes)
# [Navigate to Settings screen]
---

This is the **Settings screen**.

From here the user can edit their profile, manage notifications, and access security settings.

[Navigate to Security Centre]

This is the **Security Centre**.

[Point to the security score bar]

At the top is the **Security Score** — it's either 30, 60, or 100.

- **30** means the email is not verified.
- **60** means email is verified but 2FA is off.
- **100** means both are done.

The bar is red below 50, amber from 50 to 79, and green at 80 and above.

This nudges users to complete the security steps.

[Show the Active Sessions section]

This section shows **Active Sessions** — a list of all devices currently logged in.

Each session shows the device name and when it was last active.

[Show the revoke button]

The user can tap **Revoke** to remotely log out any specific device.

Or they can log out all other devices at once.

This is useful if the user suspects someone else has access to their account.

[Show the Security Activity Log]

This is the **Security Log** — it records every security-related event.

Things like logins, failed login attempts, password changes, 2FA being turned on or off, and sessions being terminated.

This gives the user full visibility into what's happening on their account.

---
# PART 15 — TESTING RESULTS (4 minutes)
# [No specific screen needed — just speak]
---

Now let me briefly go through the testing results.

I ran four types of testing.

**Functional testing** — I wrote 50 test cases covering every feature in the app.

All 50 passed — that's a 100% pass rate.

**Security testing** — I ran 7 security test cases.

These tested things like rejecting wrong passwords, rejecting expired tokens, validating TOTP codes, and using backup codes.

All 7 passed — 100% pass rate.

**Usability testing** — I had 6 participants complete a set of structured tasks in the app.

The results were:
- **91.7% task completion rate** — my target was 80%, so this exceeded it.
- **Average satisfaction score: 4.30 out of 5.00**
- **System Usability Scale score: 78.5** — classified as "Good" usability.

**Performance testing** — I tested on both Android and iOS, including older low-end Android devices.

For the analytics charts with large amounts of data, I applied data aggregation — grouping daily data into weekly averages for ranges over 90 days.

This kept the charts smooth even on older devices.

---
# PART 16 — LIMITATIONS AND FUTURE WORK (3 minutes)
# [No specific screen — just speak]
---

I also want to be honest about the current limitations.

**First — manual data entry.**

Right now, users have to type in every transaction manually.

In the future, I'd like to connect to Malaysian bank APIs so transactions can be imported automatically.

**Second — no real-time market prices.**

Investment prices are updated manually by the user.

In the future, I'd connect to a market data API — like Yahoo Finance or CoinGecko for crypto — so prices update automatically.

**Third — local deployment only.**

Right now, the Flask backend runs on my local machine.

To make this a real product, I'd deploy it to a cloud platform like AWS or Google Cloud, with a proper domain and HTTPS.

**Fourth — no offline mode.**

The app requires an internet connection at all times.

In the future, I'd add a local cache so users can still view and add data when they're offline.

---
# PART 17 — CONCLUSION (2 minutes)
---

To summarise.

SmartFinance is a full-stack mobile app built with Flutter, Python Flask, and MySQL.

It covers six core financial features — transactions, budgets, goals, investments, analytics, and reports.

It has a complete security system — bcrypt password hashing, email verification, two-factor authentication, JWT session management, session revocation, and a security activity log.

And it has a gamification system — XP, levels, achievement badges, daily streaks, and a leaderboard.

The testing results confirm the system works correctly and is genuinely usable.

100% functional test pass rate, 91.7% usability task completion, and a System Usability Scale score of 78.5.

Thank you. I'm ready for any questions.

---
---
---

# ANTICIPATED Q&A — MODERATOR QUESTIONS
# Read all of these before the presentation. Know the answers well.
# If you're unsure, it's okay to say "that's a good question, let me think for a moment."
---

## Q1: Why Flutter instead of React Native or native Android?

Flutter lets me write **one codebase** that works on both Android and iOS.

If I used native Android, I'd need Kotlin — and native iOS needs Swift — that's two separate codebases for the same app.

React Native is also cross-platform, but Flutter is faster because it compiles directly to native machine code.

React Native uses a JavaScript bridge to talk to native components — that adds overhead.

Flutter doesn't have that bridge — so it's more performant.

---

## Q2: Why Flask instead of Django or Node.js?

Flask is **lightweight and simple**.

It gives me full control — I only add the components I need.

Django has a lot of built-in features I didn't need — like an admin panel and an authentication system — which would add unnecessary complexity.

Node.js would work too, but I'm more comfortable with Python, and Flask integrates well with the data processing libraries I used.

---

## Q3: How does JWT authentication work?

When the user logs in successfully, the server creates a **JWT — a JSON Web Token**.

It's a string that contains encoded information — like the user's ID and an expiry time.

The server **signs** it with a secret key that only the server knows.

The app stores this token locally and **attaches it to every request** in the Authorization header.

When the server receives a request, it checks the signature.

If the signature is valid and the token hasn't expired — the request is allowed.

If it's expired or tampered with — the server returns a 401 error.

---

## Q4: How does TOTP two-factor authentication work?

TOTP stands for **Time-based One-Time Password**.

When 2FA is enabled, the server generates a **random secret key** and shows it as a QR code.

The user scans it with an authenticator app — like Google Authenticator.

Now both the app and the server share the **same secret key**.

Every 30 seconds, both of them use the same formula — secret key + current time — to calculate the same 6-digit code.

When the user types the code, the server runs the same calculation and checks if they match.

Because the code changes every 30 seconds and is based on a shared secret — it's very hard to fake.

I use the **pyotp** library which follows the **RFC 6238** standard.

---

## Q5: What happens if the user loses their 2FA phone?

I handle this with **backup codes**.

When 2FA is first set up, the system generates **10 one-time backup codes**.

These are shown to the user once, and they're told to save them somewhere safe.

If they lose their phone, they can enter a backup code instead of the 6-digit TOTP code.

Each backup code can **only be used once** — the system marks it as consumed after use.

The backup codes are stored **hashed** in the database — same security level as passwords.

---

## Q6: Why use bcrypt specifically for password hashing?

Normal hash algorithms like MD5 or SHA are **very fast**.

That's bad for passwords — because an attacker can try millions of passwords per second.

**bcrypt is intentionally slow**.

It has a "cost factor" that makes each hash computation take a certain amount of time.

This means brute-force attacks are much slower.

bcrypt also adds a **random salt** — extra random data mixed into the hash.

This means two users with the same password will have completely different hashes.

So pre-computed attack tables — called rainbow tables — don't work against bcrypt.

---

## Q7: Why use SQLAlchemy instead of writing SQL directly?

SQLAlchemy is an **ORM — Object Relational Mapper**.

It lets me define database tables as **Python classes** and query them using Python code.

This has three main benefits.

First — **SQL injection protection**.

SQLAlchemy handles all escaping automatically, so malicious input from a user can't break the query.

Second — **readability**.

Python code is easier to read and maintain than raw SQL strings, especially when the queries are complex.

Third — **portability**.

If I ever need to switch databases — from MySQL to PostgreSQL for example — I mostly just change the connection string, not all the queries.

---

## Q8: How does the budget monitoring update in real time?

When the user adds an **expense transaction**, the backend does this:

1. It checks if a budget exists for this month.
2. If yes, it finds the **matching category** in the budget.
3. It adds the transaction amount to that category's **SpentAmount** field.
4. It calculates the consumption percentage — SpentAmount divided by AllocatedAmount, times 100.
5. If the percentage is above 80% — status becomes "warning". If above 100% — "over budget".

The Flutter app receives this status and changes the progress bar colour — green, amber, or red.

---

## Q9: What is REST API? Why did you build the backend as one?

REST stands for **Representational State Transfer**.

A REST API is a way for the app to communicate with the server using standard HTTP methods:

- **GET** — to read data
- **POST** — to create data
- **PUT** — to update data
- **DELETE** — to remove data

I built it as a REST API because it **cleanly separates** the frontend from the backend.

The Flutter app doesn't care about the database — it just sends requests and receives JSON responses.

This also means in the future, I could build a web version of the app that uses the **same backend API** without any changes.

---

## Q10: What is the Financial Health Score and how is it calculated?

It's a number from 0 to 100.

It's calculated from four equal pillars — each worth up to 25 points.

**Pillar 1 — Savings Rate**: what percentage of income is the user saving?

**Pillar 2 — Budget Adherence**: how well are they staying within their budget?

**Pillar 3 — Spending Consistency**: is their spending regular and predictable, or very irregular?

**Pillar 4 — Goal Progress**: are they actively contributing toward their savings goals?

All four are added up to give the final score.

For new users who haven't added enough data yet — pillars with missing data are given a **neutral mid-range value** instead of zero.

This prevents the score from unfairly showing 0 just because the user is new.

---

## Q11: Why only 6 participants in the usability test? Is that enough?

I acknowledge this as a limitation in my report.

In academic usability research, **Jakob Nielsen's guideline** says that 5 users can identify around 85% of usability problems.

So 6 is a recognised minimum threshold for **exploratory usability testing**.

But I agree — it's not enough to make strong statistical claims about the whole population of Malaysian young adults.

For a more rigorous study, I'd want at least 30 participants, and ideally a **longitudinal study** tracking usage over several weeks.

I document this honestly in the limitations and future work section.

---

## Q12: What are all the security features in the app?

There are several layers:

1. **bcrypt password hashing** — passwords are never stored as plain text.
2. **Email verification** — confirms the email address is real before full access.
3. **Two-factor authentication** — adds a second step beyond the password.
4. **JWT with expiry** — tokens expire and can't be reused after expiry.
5. **Session management** — every login creates a session record. Users can see and revoke sessions per device.
6. **Security activity log** — logs every login, password change, 2FA toggle, and session termination.
7. **Security score** — visible feedback that nudges users to complete the security setup.

---

## Q13: If this were a real product, what would you improve first?

The most important thing is **cloud deployment**.

Right now, the backend runs on my local machine — so only people on the same network can use it.

For a real product, I'd deploy the Flask API to a cloud platform like AWS or Google Cloud, add HTTPS, and set up a proper production database.

The second most important thing is **automatic bank transaction import**.

Manual entry is the biggest friction point.

Users who have to manually type every transaction are likely to stop using the app over time.

Connecting to Malaysian bank APIs — or a third-party aggregation service — would solve this.

---

## Q14: What is the most technically challenging part of this project?

Honestly, the **2FA implementation** was the most complex.

It required coordinating many things at once:
- Generating the secret and QR code on setup.
- Verifying the TOTP code during login.
- Generating and hashing 10 backup codes.
- Making sure the session could **only be created after 2FA was completed** — not before.

Early in development I had a bug where the login session was created before the 2FA step was finished.

I fixed it by redesigning the login as a strict **two-stage process** — the server issues a temporary token after the password step, and the final JWT is only issued after the TOTP code is verified.

---

## Q15: How did you handle the case where a Decimal from MySQL can't be serialized to JSON?

MySQL stores money values as **Python Decimal objects**.

Flask 3.0's default JSON serializer doesn't know how to handle Decimal — it throws a TypeError and returns an HTTP 500 error.

This caused report screens to show empty data, which was difficult to debug because the app didn't crash — it just showed nothing.

I fixed it by calling **float()** on every Decimal value when building the JSON response in the `to_dict()` methods.

This converts Decimal to a plain Python float, which Flask can serialize normally.

I now apply this as a standard pattern across all models and API routes that return monetary values.

---

## Q16: Did you face any cross-platform issues between Android and iOS?

Yes.

Some Flutter widgets — like date pickers and dialog boxes — look slightly different on iOS versus Android.

I solved this by using **Material Design widgets** throughout the entire app.

Material Design is Google's design system, and it renders consistently on both platforms.

I avoided using Cupertino-style widgets — those are Apple-style and introduce visual inconsistencies when displayed on Android.

---

## Q17: What does "ON DELETE CASCADE" mean in your database?

**ON DELETE CASCADE** is a foreign key rule.

It means — if a parent record is deleted, all related child records are automatically deleted too.

For example, my database has the Users table, and almost every other table has a foreign key pointing to Users.

If a user deletes their account — ON DELETE CASCADE automatically removes all their transactions, budgets, goals, investments, sessions, and everything else.

I don't need to write separate delete queries for each table.

The database handles it automatically.

---

## Q18: How does the recurring transaction scheduler know when to run?

The system uses a **NextExecution** date stored in each recurring transaction record.

There's no background timer running on a server.

Instead, every time the Flutter app makes a request to certain backend routes — the backend also checks whether any recurring transactions are **due today or overdue**.

If NextExecution is on or before today — the backend creates the real transaction and advances NextExecution by one period — for example, one month forward.

This is sometimes called a **lazy evaluation** approach — it runs when needed, not on a fixed schedule.

---

# END OF SCRIPT

# SmartFinance — Final Presentation Script
# Target speaking time: ~40 minutes + 20 minutes Q&A = 1 hour total

---
## HOW TO USE THIS SCRIPT
- Text in [square brackets] = action to do — not spoken
- Speak slowly. One sentence at a time. Pause between sections.
- If you lose your place, say "let me move on to the next part" — it's fine.
- The database section is OPTIONAL — only include it if you plan to show the ERD or architecture diagram.
---

---
# PART 1 — INTRODUCTION (2 minutes)
---

Good morning / good afternoon.

My name is [your name], and today I'm presenting my Final Year Project — **SmartFinance**.

SmartFinance is a mobile app for personal finance management.

It's designed for young Malaysians who want to track their money, set budgets, save toward goals, and monitor investments.

What makes it different is the **gamification system**.

The app gives users XP points, levels, achievement badges, and daily streaks — like a game.

The goal is to make financial management more fun, so people actually keep using it.

---
# PART 2 — PROBLEM AND MOTIVATION (3 minutes)
---

So why did I build this?

Many young Malaysians don't manage their money well.

Financial literacy among Malaysian youth is quite low.

And most existing finance apps are either too complicated, too expensive, or designed for Western users — not Malaysians.

So people either don't use any app, or they try one and give up quickly.

I wanted to build something simple enough for anyone to use — and engaging enough that they actually stick with it.

That's the whole idea behind combining finance management with gamification.

Research shows that rewards, progress bars, and badges help people build habits.

So I applied that to personal finance.

---
# PART 3 — TECHNOLOGY STACK (3 minutes)
---

Let me briefly explain the technologies I used.

**[Show architecture diagram if available — otherwise just speak]**

SmartFinance has three layers.

**First — the Frontend.**
I used **Flutter**, a framework by Google.
Flutter lets me write one codebase that works on both Android and iOS.

**Second — the Backend.**
I used **Python Flask**.
Flask is a lightweight web server.
It handles all the logic — receiving requests from the app, processing them, and sending back a response.
I built it as a **REST API** — meaning the app communicates with the server using standard HTTP requests like GET and POST, and gets back JSON data.

**Third — the Database.**
I used **MySQL**.
My database has **16 tables** in total.
I used **SQLAlchemy** as the ORM — which means instead of writing raw SQL, I write Python classes and SQLAlchemy handles the database for me.

---
# PART 4 — SYSTEM FEATURES (25 minutes)
---

Now let me show you the app.

---

## 4.1 — Registration and Login

**[Show the login screen on the emulator]**

This is the **login screen**.

Let me show the registration first.

**[Tap Create Account]**

The user fills in their name, email, phone number, and a password.

The password rules are enforced **on the server side** — at least 8 characters, uppercase, lowercase, and a special character.

The password is never saved as plain text.

I use **bcrypt** to hash it before storing.

Hashing converts the password into a scrambled string that can't be reversed.

So even if someone accesses the database, they can't see the real password.

After registering, the user gets a **verification email**.

They click the link to confirm their email address.

**[Go back to login, log in with test account]**

When logging in, the server checks the email and password.

If they match, it returns a **JWT — a JSON Web Token**.

JWT is basically a digital key.

The app stores it and attaches it to every future request.

The server uses it to confirm who the user is.

The token has an expiry time — so if someone steals it, it becomes useless quickly.

---

## 4.2 — Two-Factor Authentication

**[Navigate to Settings → Security → 2FA]**

This is the **2FA setup screen**.

When the user enables 2FA, the server generates a secret key and shows it as a **QR code**.

The user scans it with an authenticator app — like Google Authenticator.

After that, every login has two steps.

Step 1 — enter email and password.

Step 2 — enter a **6-digit code** from the authenticator app.

That code changes every 30 seconds.

This is called **TOTP — Time-based One-Time Password**.

I use a Python library called **pyotp** which follows the **RFC 6238** standard — the same standard used by Google and most banks.

I also generate **10 backup codes** during setup.

These are one-time codes the user can use if they lose their phone.

The backup codes are also hashed with bcrypt before being stored.

---

## 4.3 — Dashboard

**[Navigate to the main dashboard]**

This is the **main dashboard**.

It shows the current month's total income, total expenses, and net balance.

There's also a **budget summary card** — if any category is over budget, it shows a red warning here immediately.

And the **gamification strip** at the bottom shows the user's current level, XP, and daily streak.

---

## 4.4 — Transactions and Recurring Transactions

**[Tap the add transaction button]**

This is the **Add Transaction screen**.

The user can add **income** or **expense** — they toggle between them here.

They enter the amount, pick a category from the icon grid, and select a date.

When they type a description, the app runs a **keyword analysis** to suggest a category automatically.

For example — if they type "lunch at mamak", it suggests Food.

The confidence threshold is 0.7 — if the algorithm is more than 70% sure, it highlights the suggested category.

The user can always pick a different one.

**[Navigate to Transaction History]**

The **Transaction History** screen shows all past transactions.

There's a **search bar** at the top, and **filter chips** to filter by income, expense, or category.

**[Navigate to Recurring Transactions]**

For transactions that repeat regularly — like monthly rent — the user can set up a **Recurring Transaction**.

They choose a frequency — daily, weekly, monthly, or yearly.

The backend checks the **NextExecution** date automatically.

When that date arrives, it creates the real transaction and advances the date to the next period.

Users can also **pause** a recurring transaction if they no longer need it.

---

## 4.5 — Budgets

**[Navigate to Budget Overview]**

This is the **Budget Overview**.

Each category has a **linear progress bar**.

The colour shows the spending level:
- **Green** — on track, below 75%.
- **Amber** — getting close.
- **Red** — over budget.

**[Navigate to Create Budget]**

To create a budget, the user enters a total amount — for example RM 3,000.

Then they allocate it to each category.

As they type, this counter updates in real time and shows the remaining unallocated amount.

If the total goes over the budget, the app blocks the save and shows an error.

Once saved, the backend tracks spending by summing expense transactions each month and comparing them against the allocated amounts.

---

## 4.6 — Goals

**[Navigate to Goals screen]**

The **Goals module** lets users set savings targets.

For example — "Japan Trip", target RM 5,000, deadline December 2026.

Each goal has a **priority level** — low, medium, or high.

When the user contributes money, the progress bar fills up.

When the goal is fully funded, it's marked as **completed** and the user earns a gamification achievement.

---

## 4.7 — Investments

**[Navigate to Investment Portfolio]**

This is the **Investment Portfolio screen**.

At the top — total invested, current value, and overall gain or loss.

I support **10 asset types** — Stocks, Cryptocurrency, ETF, Bonds, Real Estate, Commodities, Fixed Deposit, Unit Trust, Options, and Others.

Each holding shows the asset name, value, and profit or loss in green or red.

**[Tap the add investment button]**

To add an investment, the user selects the asset type from this grid.

Then fills in the name, quantity, purchase price, and purchase date.

The total is calculated automatically — quantity times price.

Users update the current price manually over time to track performance.

---

## 4.8 — Analytics, Reports, and Financial Insights

**[Navigate to Analytics screen]**

The **Analytics screen** shows spending charts.

I use a Flutter chart library called **fl_chart**.

There are four chart types — a spending trend line chart, an income vs expense bar chart, a category pie chart, and a budget vs actual comparison.

**[Show the time range selector]**

The user can change the time range — 1 month, 3 months, 6 months, 1 year, or all time.

All four charts update at the same time.

I load them using **Future.wait** — which runs all the API calls simultaneously instead of one by one, so it loads faster.

**[Navigate to Reports screen]**

The **Reports screen** lets users export their data.

They can download a **CSV** — generated by the Flask backend and opened in Excel.

Or a **PDF** — generated on the Flutter side and shared via the system share sheet.

**[Navigate to Financial Insights screen]**

This is the **Financial Insights screen** — a feature I added beyond the original scope.

It shows a **Financial Health Score** from 0 to 100.

The score comes from four things — savings rate, budget adherence, spending consistency, and goal progress.

Below the score are **personalised insight cards** — short messages in colour.

Green means something positive. Yellow is a warning. Red means urgent action needed.

---

## 4.9 — Gamification

**[Navigate to Achievements screen]**

This is the **Achievements screen**.

There are over 20 badges, each with a name, difficulty — Easy, Medium, Hard, or Expert — and an XP reward.

**[Show a locked and unlocked badge]**

Locked ones are grey. Unlocked ones show the badge in colour.

Users earn **XP** for every action — adding transactions, completing goals, staying within budget.

XP fills a level bar — from Level 1 to Level 10.

There's also a **habit streak** — consecutive days the user has recorded a transaction.

Miss a day and the streak resets.

And a **leaderboard** to compare XP rankings with other users.

---

## 4.10 — Settings and Security Centre

**[Navigate to Settings → Security Centre]**

This is the **Security Centre**.

At the top is the **Security Score** — either 30, 60, or 100.

- 30 means email is not verified.
- 60 means email verified but 2FA is off.
- 100 means both are done.

The bar is red, amber, or green depending on the score.

This encourages users to improve their account security.

**[Show Active Sessions]**

This section shows all devices currently logged in.

The user can **revoke** any session — which logs out that device remotely.

**[Show Security Log]**

The **Security Log** records every security event — logins, password changes, 2FA changes, session terminations.

This helps users spot any suspicious activity.

---

# PART 5 — DATABASE DESIGN — OPTIONAL (3 minutes)
# [Only include this if you are showing the ERD or architecture diagram]
---

**[Show ERD diagram]**

My database has **16 tables** in total.

The central one is the **Users** table — almost every other table links back to it.

The core tables are Users, Transactions, Budgets, BudgetCategories, and Investments.

The extended tables cover Goals, Recurring Transactions, Achievements, Streaks, and User Settings.

The security tables cover Sessions, Security Logs, Email Verification Tokens, Password Reset Tokens, and 2FA records.

I use **ON DELETE CASCADE** on all foreign keys.

This means if a user deletes their account, all their data is automatically removed — I don't need to write separate delete queries.

I also added **indexes** on frequently searched columns like UserId and TransactionDate, to keep queries fast as the data grows.

---
# PART 6 — TESTING RESULTS (3 minutes)
---

Let me go through the testing results quickly.

**Functional Testing** — I wrote 50 test cases covering every feature.

All 50 passed. That's a **100% pass rate**.

**Security Testing** — 7 test cases covering login rejection, JWT expiry, TOTP verification, and backup codes.

All 7 passed. **100% pass rate**.

**Usability Testing** — 6 participants completed structured tasks in the app.

Results:
- **91.7% task completion rate** — my target was 80%, so this exceeded it.
- **Average satisfaction score: 4.30 out of 5.00**
- **System Usability Scale: 78.5** — rated as "Good" usability.

---
# PART 7 — CHALLENGES (2 minutes)
---

Two main technical challenges I want to mention.

**First — field naming mismatch.**

The database uses PascalCase names — like `UserId`.

But Flutter expected camelCase — like `userId`.

This caused silent null values — the app ran fine but showed blank data.

I fixed it by adding explicit key mapping in every `to_dict()` method in the Flask models.

**Second — 2FA flow error.**

Early on, the login session could be created before the 2FA step was completed.

I fixed it by redesigning the login as a strict two-stage process.

The server issues a temporary token after the password check.

The real JWT is only issued after the TOTP code is verified.

---
# PART 8 — LIMITATIONS AND FUTURE WORK (2 minutes)
---

Three honest limitations of the current system.

**First — manual data entry.**

Users have to type every transaction manually.

In the future, I'd connect to Malaysian bank APIs for automatic import.

**Second — no real-time prices.**

Investment prices are updated manually.

I'd connect to a market data API like Yahoo Finance to automate this.

**Third — local deployment only.**

The backend runs on my local machine right now.

To make this a real product, I'd deploy it to a cloud platform like AWS or Google Cloud.

---
# PART 9 — CONCLUSION (1 minute)
---

To summarise.

SmartFinance is a full-stack mobile app — Flutter frontend, Python Flask backend, MySQL database.

It covers transactions, budgets, goals, investments, analytics, reports, gamification, and security.

Testing results confirm it works correctly — 100% functional test pass rate, 91.7% usability completion, and a SUS score of 78.5.

Thank you. I'm happy to answer any questions.

---
---
---

# Q&A — LIKELY MODERATOR QUESTIONS
# Read all of these before the presentation.
# If you're not sure, say: "That's a good question, let me think for a moment."
---

## Q1: Why Flutter instead of native Android or React Native?

Flutter lets me write **one codebase** for both Android and iOS.

Native Android needs Kotlin and native iOS needs Swift — that's two separate codebases.

React Native is also cross-platform, but Flutter compiles directly to native machine code.

React Native uses a JavaScript bridge, which adds overhead.

Flutter doesn't have that, so it's faster and smoother.

---

## Q2: Why Flask instead of Django or Node.js?

Flask is **lightweight and simple**.

Django has a lot of built-in features I didn't need — like an admin panel — which would add unnecessary complexity.

Node.js would work too, but I'm more comfortable with Python.

Flask also integrates well with the data processing libraries I used for analytics.

---

## Q3: How does JWT work?

When the user logs in, the server creates a **JWT — a JSON Web Token**.

It contains encoded information — like the user's ID and an expiry time.

The server **signs it** with a secret key only the server knows.

The app stores the token and attaches it to every request.

The server checks the signature on each request.

If it's valid and not expired — the request is allowed.

If it's expired or tampered with — the server returns a 401 error.

---

## Q4: How does TOTP 2FA work?

When 2FA is set up, the server generates a **random secret key** shown as a QR code.

The user scans it with an authenticator app.

Now both the app and the server share the **same secret key**.

Every 30 seconds, both calculate the same 6-digit code using — secret key + current time.

When the user enters the code, the server runs the same calculation and checks if they match.

I use **pyotp** which follows the **RFC 6238** standard — same as Google and most banks.

---

## Q5: What if the user loses their 2FA phone?

I generate **10 backup codes** when 2FA is set up.

The user saves them somewhere safe.

If they lose their phone, they enter a backup code instead of the 6-digit TOTP code.

Each code can only be used once.

They're stored **hashed with bcrypt** — same security as passwords.

---

## Q6: Why bcrypt for passwords?

Normal hash algorithms like MD5 are very fast — which is bad for passwords.

An attacker can try millions of passwords per second.

**bcrypt is intentionally slow**.

This makes brute-force attacks much harder.

bcrypt also adds a **random salt** — extra random data mixed in before hashing.

So two users with the same password will have completely different hashes.

Pre-computed attack tables — called rainbow tables — don't work against bcrypt.

---

## Q7: Why SQLAlchemy instead of raw SQL?

SQLAlchemy is an **ORM — Object Relational Mapper**.

I define database tables as Python classes instead of writing SQL.

Three main benefits:

First — **SQL injection protection** — SQLAlchemy handles escaping automatically.

Second — **easier to read and maintain**.

Third — **portability** — if I switch databases later, I mostly just change the connection string.

---

## Q8: How does budget monitoring work?

When an expense transaction is saved, the backend:

1. Checks if a budget exists for this month.
2. Finds the matching category.
3. Adds the transaction amount to **SpentAmount**.
4. Calculates consumption — SpentAmount divided by AllocatedAmount times 100.
5. If above 80% — warning. If above 100% — over budget.

Flutter gets this status and changes the progress bar colour — green, amber, or red.

---

## Q9: What is a REST API?

REST stands for **Representational State Transfer**.

It's a way for the app to talk to the server using standard HTTP methods.

**GET** reads data. **POST** creates data. **PUT** updates data. **DELETE** removes data.

I built it as REST because it **cleanly separates** the frontend from the backend.

The Flutter app doesn't touch the database directly — it just sends requests and gets JSON back.

---

## Q10: How is the Financial Health Score calculated?

It's a score from 0 to 100, made up of four equal parts — each worth 25 points.

**Savings Rate** — what percentage of income is being saved.

**Budget Adherence** — how well they stay within budget.

**Spending Consistency** — is their spending regular or very irregular.

**Goal Progress** — are they contributing to savings goals.

For new users without enough data yet, missing pillars get a **neutral mid-range value** instead of zero.

This prevents the score from unfairly showing 0 just because they're new.

---

## Q11: Why only 6 usability participants?

I acknowledge this as a limitation in my report.

Jakob Nielsen's research says **5 users** can identify around 85% of usability problems.

So 6 is a recognised minimum for exploratory usability testing.

But it's not enough to make strong statistical claims about the whole population.

For a more rigorous study, I'd want 30+ participants and a longer study over several weeks.

---

## Q12: What are all the security features?

1. **bcrypt password hashing** — passwords never stored as plain text.
2. **Email verification** — confirms the email is real.
3. **Two-factor authentication** — second step after password.
4. **JWT with expiry** — tokens expire and become invalid.
5. **Session management** — users can see and revoke sessions per device.
6. **Security activity log** — records all security events.
7. **Security score** — visible feedback to nudge users to complete security steps.

---

## Q13: What would you improve first if this were a real product?

**Cloud deployment** first.

Right now the backend runs on my local machine — so only people on the same network can connect.

For a real product, I'd deploy to AWS or Google Cloud, add HTTPS, and set up a proper production database.

**Second — automatic bank import.**

Manual entry is the biggest friction point.

Connecting to Malaysian bank APIs would remove the need to type in every transaction.

---

## Q14: What was the hardest part to build?

The **2FA system**.

It required many things to work together — generating the QR code, verifying the TOTP code during login, generating and hashing backup codes, and making sure the session is only created after 2FA is fully completed.

Early on I had a bug where login could finish without completing the 2FA step.

I fixed it by making the login a strict two-stage process — a temporary token is issued after the password, and the real JWT only comes after the TOTP code is verified.

---

## Q15: What does ON DELETE CASCADE mean?

It's a database rule on foreign keys.

If a parent record is deleted, all related child records are **automatically deleted too**.

For example — if a user deletes their account, all their transactions, budgets, goals, sessions, and everything else are removed automatically.

I don't need to write separate delete queries for each table.

---

## Q16: How do recurring transactions know when to run?

Each recurring transaction stores a **NextExecution** date.

When the app makes certain requests, the backend checks if any NextExecution date is today or overdue.

If yes — it creates the real transaction and moves NextExecution forward by one period.

For example, a monthly transaction moves forward by one month.

This runs automatically without any background scheduler.

---

# END OF SCRIPT

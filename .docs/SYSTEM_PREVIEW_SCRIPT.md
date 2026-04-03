# SmartFinance — FYP System Preview Script
### Final Version · Word-for-word · ~30 minutes

> **How to use this script:**
> - Read every word naturally — do not rush
> - Stage directions are in *italics inside brackets* — do not read these aloud
> - **Bold text** = emphasise these words slightly when speaking
> - Practice the demo flow at least once before presenting so your hands know where to tap

---

## SECTION 1 — Project Overview
### (~3 minutes)

"Good [morning / afternoon]. My name is [Your Name], student ID [Your ID], and my Final Year Project is called **SmartFinance** — a personal finance management mobile application built for Android.

Let me start by explaining the problem I am solving.

Managing personal finances is something most people know they should do, but very few actually do consistently. The main reasons are: it feels tedious, existing tools are either too complicated to use daily, or they just show you raw numbers without telling you what those numbers actually mean. You open your banking app, you see your account balance, and that is it. You have no idea whether you are overspending on food, whether you are on track with your savings target, or how all your investments are performing as a whole.

This problem is especially common among students and young working adults in Malaysia — people who are just starting to earn money but have no structured financial guidance.

**SmartFinance solves this** with an all-in-one mobile application that covers five core areas: transaction tracking, budget management, savings goals, investment portfolio tracking, and a financial insights engine that analyses the user's actual spending behaviour and produces a personalised health score with specific recommendations.

What makes this different from a basic finance tracking app is two key things. First, the **Financial Insights Engine** — it does not just record your data, it interprets your data and tells you what it means. Second, the **gamification system** — users earn experience points, unlock achievement badges, and maintain daily streaks, which encourages them to track consistently instead of giving up after the first week.

The system is built using **Flutter** for the mobile frontend, **Python Flask** for the backend REST API, and **MySQL** for the database. All three communicate together — the Flutter app sends HTTP requests to the Flask server, the Flask server processes the logic and queries MySQL, then returns the results as JSON back to the app.

Now let me demonstrate the system."

---

## SECTION 2 — Live Demo
### (~20 minutes)

---

### 2A — Login and Security
#### (~2 minutes)

"Let me begin from the login screen.

*(Open the app to the login screen.)*

I will log in with an existing account. *(Type in the email and password and tap Login.)* When the user taps Login, the app sends the credentials to my Flask backend at the authentication endpoint. The server checks the email and password against the MySQL database — if they match, it generates a **JWT access token** and returns it to the app. The app stores this token securely on the device, and from this point every single API call includes this token in the request header so the server knows who is making the request.

My system also supports **Two-Factor Authentication**. When 2FA is enabled, after entering the correct password the user receives a six-digit one-time code sent to their registered email address. They must enter this code within the time limit to complete the login. This means even if someone steals your password, they cannot access the account without also having access to your email.

New accounts require **email verification** before full access is granted. A verification email with a secure token link is sent on registration, and the account is only activated after the user clicks that link. This prevents fake accounts from being created.

There is also a **Security Score** visible in the security settings — the score is 30 if the email is not verified, 60 if the email is verified, and 100 if both email is verified and 2FA is enabled. This encourages users to fully secure their accounts in a way that feels rewarding rather than forced."

---

### 2B — Dashboard
#### (~3 minutes)

"After login, the user arrives at the **Dashboard**. This is the central hub of the entire application.

*(Show the dashboard screen.)*

At the very top, you can see the user's **profile photo** — users can upload their own photo from their gallery or take a new one with the camera. Next to it is a personalised greeting with the user's name.

Below that is the **Financial Summary card**. This shows total income, total expenses, and net savings for the current calendar month. Underneath the expense figure — *(point to it)* — you can see a percentage comparison against last month. If it shows '↑ 12% vs last month', it means the user is spending 12% more this month than they did last month. This gives immediate context without the user needing to go anywhere else.

Further down are quick-access cards showing the budget status, total portfolio value, and gamification progress — all live data that refreshes every time the dashboard loads.

Below that is a list of **upcoming bills** coming from the recurring transactions module, and a list of the five most recent transactions with a View All button.

The **bottom navigation bar** has five tabs: Dashboard, Transactions, Goals, Portfolio, and Financial Insights. I will walk through each one now.

One technical point — the dashboard loads all of this data simultaneously using parallel API calls with `Future.wait()`. All sections appear together at the same time instead of loading one after another, which makes the experience feel much smoother."

---

### 2C — Transaction Tracking
#### (~3 minutes)

"Transactions are the foundation of the entire system — every other feature depends on what the user records here.

*(Navigate to Add Transaction.)*

I will add a new expense now. I select **Expense**, enter the amount — let's say RM 25 — select the category **Food and Dining**, keep today's date, and optionally add a description. *(Fill in the form and tap Save.)*

*(Navigate to Transaction History.)* You can see it has appeared immediately in the list with the correct category icon, colour, and formatted date. This record is now stored in the MySQL database and is immediately reflected everywhere in the app — the dashboard summary updates, the budget tracker accounts for it, and the financial insights engine will include it in its next calculation.

The **transaction history screen** has powerful search and filter capabilities. I can search by category or description *(type in the search bar)*, filter to show income only or expenses only using the filter chips, sort by date or amount, and apply advanced filters for specific date ranges and amount ranges.

To **edit** a transaction, I tap on it — the form reopens with all the original values pre-filled. If I make no changes and tap back, the app does nothing — it is smart enough to detect that nothing was changed. But if I modify any field and try to leave, it shows a 'Discard changes?' dialog to prevent accidental data loss.

To **delete**, I swipe left on a transaction card. *(Demonstrate.)* A red delete background appears, and a confirmation dialog appears before anything is permanently removed.

The system also supports **recurring transactions** — for bills like monthly rent, weekly salary, or subscriptions. You set it up once with the name, amount, category, and frequency, and the system automatically shows upcoming bills on the dashboard and sends reminder notifications before they are due."

---

### 2D — Budget Management
#### (~3 minutes)

"Now let me show the **Budget** feature. *(Navigate to Budget.)*

A budget in SmartFinance is a monthly spending plan. The user sets a total budget amount for the month and allocates portions of it across different spending categories.

*(Show the budget overview screen.)*

Here you can see the total budget is set at a certain amount for this month. The large progress bar shows the overall percentage used. Below that is the **category breakdown** — Food and Dining, Transport, Entertainment, and so on — each with its own progress bar, amount used, and amount remaining.

The important thing here is the **intelligent alert system**. When any individual category reaches **90% of its limit**, or the overall budget reaches **80%**, the system automatically sends a push notification to the user's device — even if the app is closed. This is proactive — it warns the user before they overspend, not after they have already done so.

If a category goes over its allocated limit, its progress bar turns red and shows a negative remaining amount — a clear visual warning.

The budget is always based on the current calendar month, so it resets automatically on the first of every month and the user always starts fresh."

---

### 2E — Financial Goals
#### (~2 minutes)

"The **Goals** feature lets users set savings targets with deadlines and track their progress over time.

*(Navigate to Goals.)*

The summary card at the top shows the number of active goals, completed goals, and the combined progress percentage across all goals.

Each goal card shows the goal name, target amount, amount saved so far, a progress bar, and a **deadline countdown**. *(Point to the countdown.)* When the deadline is within seven days, this countdown text turns **orange** as an urgency warning to remind the user they need to act quickly.

I can contribute money to a goal by tapping the Contribute button. *(Tap it.)* A dialog appears showing the remaining amount needed. Now watch what happens when I enter an amount that is larger than what is remaining — *(type a number larger than remaining)* — a warning appears in real time below the input: 'Exceeds remaining by RM X.XX — the goal will be marked as completed.' This real-time validation makes sure the user always knows exactly what will happen before they confirm.

Goals can be filtered as All, Active, or Completed using the chips at the top. Completed goals are preserved in the history so users can look back at what they have achieved."

---

### 2F — Investment Portfolio
#### (~2 minutes)

"The **Portfolio** screen tracks all of the user's investments in one place.

*(Navigate to Portfolio.)*

At the top is a summary card showing the total portfolio value, total amount originally invested, and the overall profit or loss with a percentage return.

Below that is an **Asset Breakdown** showing what proportion of the portfolio is in each investment type. SmartFinance supports **ten asset classes**: Stocks, Cryptocurrency, Bonds, Mutual Funds, ETFs, Real Estate, Commodities, Fixed Deposits, Unit Trusts, and Other. These cover all the major investment types available to Malaysian investors.

Each individual investment card shows the asset name, type, purchase price, current price, and the profit or loss in ringgit. *(Point to a card.)* Since market prices change daily, users can update the current price by tapping the edit icon, entering the new value, and the profit and loss recalculate immediately.

The **Top Performers** section automatically surfaces the investments giving the best returns.

The filter button in the top right lets users view one asset class at a time. When a filter is active, a banner appears at the top *(show if filter is applied)* showing which type is being filtered, with a Clear button. The filter icon also changes colour to indicate that results are filtered — a small but important usability detail."

---

### 2G — Financial Insights Engine
#### (~3 minutes)

"This is the most distinctive feature of SmartFinance, and the one I am most proud of. *(Navigate to the Financial Insights tab.)*

The **Financial Insights Engine** analyses the user's transaction data for the current calendar month and produces a **Financial Health Score from 0 to 100**. The score is colour-coded — green for Excellent, which is 80 and above; teal for Good, which is 60 to 79; orange for Fair, which is 40 to 59; and red for Needs Work, which is below 40.

The score is calculated from **four independent pillars**, each contributing up to 25 points.

**Pillar one is Savings Rate.** This measures what percentage of the user's income is being saved. A savings rate of 20% or more earns the full 25 points. Below 20%, the score scales down proportionally. If there is no income recorded, the pillar gets a neutral 12.5 points.

**Pillar two is Budget Adherence.** If the user has a budget and is within it, they get full marks. If they go over budget, the score drops — at 50% over budget the pillar score reaches zero. If no budget is set at all, a neutral 12.5 points is given to avoid unfairly penalising users who have not yet set one up.

**Pillar three is Spending Consistency.** This compares the current month's total spending against last month's. If spending has increased by less than 10%, the user gets full marks. For each additional percentage above that threshold, points are deducted. This rewards stable spending habits.

**Pillar four is Goal Progress.** This looks at how many of the user's active savings goals are completed. The score is proportional — fully completing all goals earns 25 points. If no goals exist, the pillar returns a neutral score.

The four pillar scores are added together to give the total out of 100.

Below the score are **personalised insight cards**. Each card identifies a specific pattern in the user's data — for example: 'You are saving 28.5% of your income this month — above the recommended 20%.' Or: 'Your spending increased by 35% compared to last month — review your recent expenses.' These messages are generated dynamically by the backend based on the user's actual numbers. Nothing is hardcoded."

---

### 2H — Gamification
#### (~2 minutes)

"The last major feature is the **gamification system**, which addresses the biggest real-world problem with finance apps — users stop opening them after a few days.

*(Navigate to the gamification section on the dashboard or achievements screen.)*

Every time the user logs a transaction, they earn **experience points** and extend their **daily streak**. The streak is a count of consecutive days where at least one transaction was logged. If the user misses a day, the streak resets to zero.

There are **achievement badges** for reaching specific milestones — logging your first transaction, reaching a 7-day streak, completing your first goal, and others. When a new achievement is unlocked, the app sends a push notification and shows the badge on the achievements screen.

Users also have a **level** that increases as they accumulate XP, and a **leaderboard** where they can see how they rank compared to other users on the platform. Users who prefer privacy can opt out of the leaderboard in the notification settings.

The reason I built this is behavioural — financial tracking has a very high drop-off rate because it feels like a chore. The streak mechanic specifically creates a loss-aversion effect: users do not want to break their streak, so they open the app and log a transaction even on days they would normally skip. Over time, this becomes an automatic daily habit."

---

## SECTION 3 — Technical Explanation
### (~4 minutes)

"Let me now explain how the system is structured technically.

**Architecture.** SmartFinance follows a client-server architecture. The Flutter mobile app is the client — it handles all user interface and interaction. The Python Flask application is the server — it handles all business logic, data processing, and database operations. They communicate through a RESTful API over HTTP using JSON as the data format.

**Why Flutter.** I chose Flutter because it uses the Dart language and compiles directly to native ARM machine code, meaning performance is close to a fully native Android app. It also provides a rich Material Design widget library that let me build a polished interface efficiently. A single codebase also supports both Android and iOS if needed in the future.

**Why Flask.** Flask is a micro-framework that gives full control over API structure without unnecessary overhead. I organised the backend into **route blueprints** — one file per feature: authentication, transactions, budgets, goals, investments, insights, gamification, and recurring transactions. Each blueprint is registered with its own URL prefix in the main application file.

**Database.** MySQL is used for persistent storage. The main tables are Users, Transactions, Budgets, BudgetCategories, Goals, Investments, RecurringTransactions, and Gamification. Relationships between tables are enforced using foreign keys to maintain data integrity.

**Security.** Passwords are never stored as plain text — they are hashed using bcrypt with a unique salt before being saved to the database. Every protected API endpoint validates the JWT token on every single request. Email communications for verification and password reset go through an SMTP server using TLS encryption. For 2FA, the one-time code is time-limited and single use.

**Notifications.** The app uses the `flutter_local_notifications` package. The notification service is initialised at app startup and requests the Android 13 runtime permission for notifications. Budget alerts, achievement unlocks, and bill reminders all use this single centralised notification service, which ensures consistency."

---

## SECTION 4 — Test Cases
### (~3 minutes)

"Let me walk through three prepared test cases to show that the system behaves correctly under specific conditions.

---

**Test Case 1 — Budget Category Alert Notification**

The purpose of this test is to verify that the system correctly triggers a notification when a spending category approaches its limit.

- **Input:** Add an expense that causes the Food and Dining category to exceed 90% of its allocated budget.
- **Expected output:** A push notification appears with the message warning that the category is near its limit, and the budget screen highlights the category.
- **Actual result:** *(Show or describe the notification appearing.)* The notification fires with the category name and percentage used. The category card on the budget screen also shows a warning colour. **Test passes.**

---

**Test Case 2 — Financial Health Score Reflects Actual Data**

The purpose of this test is to verify that the score accurately reflects the user's financial behaviour.

- **Input:** A user with income recorded this month, expenses below the budget limit, and at least one active savings goal.
- **Expected output:** The Savings Rate and Budget Adherence pillars should score well, producing a score in the Good or Excellent range.
- **Actual result:** *(Navigate to Financial Insights and show the score.)* The score is in the expected range. The Savings Rate pillar bar is green because savings exceed the 20% threshold. The Budget Adherence pillar is green because spending is within the budget. The score reflects the user's real situation, not a hardcoded value. **Test passes.**

---

**Test Case 3 — Goal Over-Contribution Real-Time Warning**

The purpose of this test is to verify that the system warns users before they enter more than the goal's remaining amount.

- **Input:** A goal with RM 200 remaining. User opens the contribute dialog and types RM 500.
- **Expected output:** A warning message should appear in real time showing the exact excess amount.
- **Actual result:** *(Open the contribute dialog and type 500.)* The warning message appears immediately below the input field as the user types: 'Exceeds remaining by RM 300.00 — the goal will be marked as completed.' The user is fully informed before confirming. **Test passes.**"

---

## CLOSING
### (~1 minute)

"To summarise what I have demonstrated today —

SmartFinance is a fully functional personal finance management system with eight integrated modules: secure authentication, transaction tracking, budget management with alerts, savings goals, investment portfolio tracking, a personalised financial insights engine, recurring transaction management, and a gamification system.

Every module is connected to the others — a transaction immediately affects the budget tracker, which feeds into the financial health score, which may trigger a push notification to the user. The system is not just a collection of screens — it is a coherent, end-to-end financial management experience.

The backend is live, the mobile app is fully functional on Android, and all core features have been tested.

Thank you very much for your time. I am happy to demonstrate any specific feature in more detail or answer any questions you have."

---
---

# Q&A PREPARATION
## Supervisor Questions with Full Prepared Answers

> Read through these before your presentation. You do not need to memorise them word for word — understand the answer so you can explain it naturally.

---

### Q1: Why did you choose Flutter instead of React Native or native Android development?

"I chose Flutter for three main reasons. First, Flutter compiles to native ARM machine code, meaning the performance is very close to a fully native Android app — unlike React Native which goes through a JavaScript bridge that can introduce performance bottlenecks. Second, Flutter has a very mature and well-documented widget system based on Material Design, which allowed me to build a professional-looking UI efficiently without starting from scratch. Third, Flutter supports both Android and iOS from a single codebase, which gives the project more reach even though I am currently focusing on Android for this project."

---

### Q2: Why Flask instead of Django or Node.js?

"Flask is a micro-framework — it provides the essential tools and lets me structure the application the way I want. For a project where I needed a clean REST API with clear separation between features, Flask blueprints are a perfect fit. Django would add a lot of overhead that I do not need — it is better suited for full-stack web applications with its own template engine and admin panel. I chose Python over Node.js primarily because Python made the financial calculations in the insights engine much easier to implement and test. Python's built-in numeric handling and libraries like SQLAlchemy also made database work very straightforward."

---

### Q3: How exactly does the Financial Health Score algorithm work?

"The score is out of 100 and is divided into four independent pillars, each worth a maximum of 25 points.

Pillar one is Savings Rate. I calculate income minus expenses divided by income to get the savings percentage. If the savings rate is 20% or above, the pillar gets the full 25 points. Below 20%, it scales proportionally. If no income is recorded this month, the pillar gets a neutral 12.5 points to avoid penalising someone who simply has not logged income yet.

Pillar two is Budget Adherence. If the user is within their budget, they get 25 points. As they go over budget, the score drops, and at 50% over budget the pillar reaches zero. If no budget is set, a neutral 12.5 is given.

Pillar three is Spending Consistency. This compares the current month's total spending against last month's. If the increase is within 10%, the pillar gets full marks. For every percentage above 10%, points are deducted. This rewards stable, predictable spending habits. If there is no previous month data, the pillar returns a neutral 12.5.

Pillar four is Goal Progress. This is the ratio of completed goals to total goals, multiplied by 25. If all goals are completed, the pillar gets full marks. No goals means a neutral 12.5.

All four pillar scores are summed and rounded to give the final score out of 100, clamped between 0 and 100."

---

### Q4: How do you ensure the security of user data?

"There are several layers. Passwords are hashed using bcrypt with a salt before being stored in the database — even if the database is compromised, the plain text passwords cannot be recovered from the hash. All protected API endpoints require a valid JWT token in the request header, and the server verifies the token's signature and expiry on every single request — there are no unprotected routes for sensitive data. The JWT secret key is stored in the server environment configuration, not in the source code. Email communications for verification and password reset use TLS encryption through SMTP. For 2FA, the one-time code is time-limited and single use, so it cannot be replayed. On the device side, the JWT token is stored in shared preferences which is sandboxed to the app by the Android OS."

---

### Q5: How does your app compare to existing apps like Money Manager, Spendee, or Wallet?

"Most existing apps focus purely on tracking — they record your transactions and show you charts. SmartFinance has two things that most of them do not have. First, the Financial Insights Engine that actively interprets the data and gives personalised, specific recommendations — not just visualisations. Second, the gamification system that builds consistent usage habits through streaks, XP, and achievements. SmartFinance also combines investment portfolio tracking together with spending and budgeting in one place, whereas most personal finance apps focus on either spending tracking or investing, but not both together.

The main limitation compared to commercial apps is that SmartFinance requires manual transaction entry — users must log every transaction themselves. Commercial apps like Money Manager often offer automatic bank statement import or direct bank integration. That kind of integration requires working with Malaysian banking APIs, which was beyond the scope of this project."

---

### Q6: What are the limitations of your system?

"I am aware of three main limitations. First, all transaction data must be entered manually by the user — there is no automatic bank sync or statement import. This is the most significant barrier to daily usage in a real-world scenario. Second, the financial insights are calculated only on the current calendar month's data — a longer historical window, such as six months or a year, would allow for more accurate trend detection and benchmarking. Third, the system is designed for a single user — it does not support shared budgets between partners or family members, which is a common real-world need. These three areas would be my first priorities if the project were extended beyond the FYP scope."

---

### Q7: How did you test the system?

"I conducted two types of testing. The first is functional testing — I prepared 50 test cases covering all eight modules, including both normal use cases and edge cases such as empty data states, invalid inputs, expired tokens, and boundary conditions. Each test case documents the input, expected output, and actual result. The second type is user acceptance testing — I had six participants use the application and complete a structured evaluation questionnaire covering ease of use, feature completeness, and overall satisfaction. The results showed positive feedback overall, with the Financial Insights and gamification features receiving the highest satisfaction ratings. Participants also suggested wanting more chart types in the reports section, which I noted as future work."

---

### Q8: What was the most challenging part of building this system?

"The most challenging part was the Financial Insights Engine. The difficulty was not the coding itself, but deciding on the right formula for a meaningful health score. The thresholds and weightings had to be calibrated carefully — if the scoring is too strict, users always get low scores and lose motivation to improve. If it is too lenient, the score is meaningless. I tested the formula against multiple different user profiles with different spending patterns to make sure the score felt fair and accurate across different situations, and I iterated on the weightings several times before arriving at the current formula.

The second challenge was the notification system. Getting push notifications to work correctly on Android 13 required understanding the runtime permission model introduced in that Android version, and ensuring the notification plugin was properly initialised at app startup rather than lazily on first use, which was the cause of a bug where notifications would silently fail to appear."

---

### Q9: How does your gamification system prevent users from cheating — for example, logging and deleting fake transactions just to earn XP?

"That is a valid concern and an honest limitation of the current implementation. A user could theoretically log fake transactions to farm XP. In the current version, this is not prevented because SmartFinance is designed as a personal finance tool — the data the user enters only affects themselves, so gaming the system mainly hurts their own financial accuracy rather than others.

In a production version with a real competitive leaderboard, I would address this by only awarding XP after a transaction has existed in the system for at least 24 hours without being deleted, and by flagging unusual patterns such as a large number of transactions created and immediately deleted in a short period. For the scope of this FYP, the risk is considered low since the system is designed for personal, honest use."

---

### Q10: Why did you use MySQL instead of a NoSQL database like MongoDB or Firebase Firestore?

"Financial data is inherently relational. A transaction belongs to a user, may be counted against a budget category, and may contribute to a goal. These relationships are naturally expressed in a relational schema with foreign keys and joins. MySQL also provides ACID compliance — meaning any database operation either completes fully or not at all. This is critical for financial data where a partial write could cause data inconsistency, such as a transaction being saved without the corresponding budget update. NoSQL databases like MongoDB are better suited for unstructured or highly variable data models, which does not apply to the structured and predictable nature of financial records."

---

### Q11: How scalable is your backend?

"Currently the backend runs as a single Flask development server, which is appropriate for a FYP with a small number of users. For real-world scaling, the path forward would be to containerise the Flask application using Docker, deploy it behind a production WSGI server like Gunicorn or uWSGI, and put multiple instances behind a load balancer. The JWT-based authentication is already stateless, which means horizontal scaling — running multiple server instances simultaneously — is straightforward because no session state is shared between instances. The MySQL database could be moved to a managed cloud service like AWS RDS or Google Cloud SQL for automatic backups and scaling."

---

### Q12: What would you add or improve if you had more time?

"Three things. First, automatic bank statement import — allowing users to upload their PDF bank statement and have transactions extracted and categorised automatically, which would eliminate the manual entry barrier that is the biggest limitation right now.

Second, a machine learning component for the insights engine — instead of rule-based thresholds, use the user's own historical data to generate personalised benchmarks. For example, instead of comparing against a fixed 20% savings rate target, compare against that specific user's own average savings rate over the past six months. This would make the insights much more personalised and accurate.

Third, multi-user budget sharing for couples or families — allowing two accounts to share a combined budget and see each other's transactions. This would significantly expand the target user base."

---

### Q13: How does the app handle a brand new user who has no data yet?

"Every screen that depends on data has an empty state designed specifically for new users. For example, the Financial Insights screen shows an encouraging message — 'No insights yet — start adding your income and expenses to see your financial health.' The budget overview shows a friendly prompt to create the first budget with a clear button. The goals and portfolio screens similarly guide new users toward their first action. The financial health score uses neutral values — 12.5 out of 25 for each pillar — when data is missing, rather than giving a misleading 0 score to someone who simply has not entered any data yet. This ensures new users have a positive first experience rather than seeing a screen full of error states or zero values."

---

*End of Script — Good luck with your presentation!*

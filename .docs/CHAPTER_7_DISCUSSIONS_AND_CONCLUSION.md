# Chapter 7: Discussions and Conclusion

---

## 7.1 Chapter Introduction

This chapter provides a reflective evaluation of the SmartFinance project as a whole. It synthesises the work carried out across the preceding chapters — from problem identification and literature review through to system design, implementation, and testing — and examines the extent to which the project's stated objectives were met. The chapter opens with a concise summary of the project, followed by a structured assessment of achievements measured against the objectives set out in Chapter 1 and the empirical results reported in Chapter 5. The contributions of the project are then discussed from academic, technical, and societal perspectives. The chapter proceeds to acknowledge the limitations of the current system honestly and proposes specific directions for future improvement. Technical challenges encountered during development are discussed alongside the solutions that were adopted. The chapter closes with a conclusion that contextualises SmartFinance within the broader challenge of improving financial literacy and financial self-management among Malaysian young adults.

---

## 7.2 Project Summary

SmartFinance is a gamified, cross-platform personal finance management mobile application designed for Malaysian young adults. The project was conceived in response to a well-documented gap in financial literacy among young Malaysians, a demographic increasingly responsible for their own financial decisions yet frequently underserved by existing tools that are either too complex, too costly, or culturally misaligned with local needs. The application targets the core problem of disengagement with personal budgeting by combining practical financial management features with motivational gamification mechanisms rooted in behavioural science.

The system was built as a full-stack mobile solution comprising a Flutter frontend, a Python Flask RESTful backend, and a MySQL relational database. The Flutter framework was selected specifically for its ability to produce native-quality applications for both Android and iOS from a single shared codebase, directly supporting the objective of broad cross-platform accessibility. The backend exposes a structured JSON API consumed exclusively by the mobile client, ensuring a clean separation of concerns and a scalable foundation for future development.

In its delivered form, SmartFinance encompasses 25 Flutter screens organised across 10 functional modules and 12 Flask route modules. Core features include user authentication with email verification and two-factor authentication, expense and income tracking with manual categorisation, budget creation and monitoring, financial goal management, investment portfolio tracking, interactive analytics with charting, financial report generation with CSV and PDF export, and a comprehensive gamification layer featuring achievements, experience points, levelling, habit streaks, and a leaderboard. Several features were delivered beyond the original project scope, including a Financial Insights module providing a personalised financial health score and actionable insight cards, recurring transaction scheduling, active session management with per-device revocation, a security activity log, a security score system, and an onboarding experience for first-time users. These additions reflect the iterative nature of the development process and a commitment to building a system that is not only functional but genuinely usable and trustworthy.

---

## 7.3 Achievements

### 7.3.1 Overview

The project set out four primary objectives and three secondary objectives in Chapter 1. The testing and evaluation results documented in Chapter 5 provide a basis for assessing the degree to which each objective was realised. Across all objective categories, the outcomes either met or exceeded the predefined acceptance criteria.

### 7.3.2 Primary Objective 1 — Intuitive Expense Tracking and Budget Management

The first primary objective was to develop a user-friendly financial tracking system with intuitive expense tracking and budget management capabilities. This objective was addressed through the implementation of a transaction management module supporting manual entry of both income and expense records with category assignment, and a budget module allowing users to create category-specific budgets with visual progress tracking.

The evidence from Chapter 5 supports a positive evaluation of this objective. Functional testing returned a 100% pass rate across all 50 test cases, including all cases relating to transaction creation, budget creation, and budget monitoring. Usability testing yielded an overall task completion rate of 91.7%, which comfortably exceeds the 80% acceptance threshold set at the outset of the project. The average satisfaction score of 4.30 out of 5.00 and a System Usability Scale average of 78.5 — classified as "Good" usability — confirm that participants found the system accessible and straightforward to use without prior training.

### 7.3.3 Primary Objective 2 — Gamification and Behavioural Design

The second primary objective was to implement gamification and behavioural design elements that encourage positive financial behaviours. This was realised through a layered gamification system incorporating more than 20 achievement badges, an experience points and levelling system spanning levels 1 to 10, habit streaks that reward consistent engagement, and a leaderboard that introduces a social comparison dimension.

Participants in the usability study responded positively to these elements. The achievement and gamification module achieved a mean satisfaction score that contributed to the overall average of 4.30 out of 5.00. Qualitatively, feedback indicated that the badge and level system provided a sense of progress that made continued engagement feel rewarding, which aligns with the self-determination theory and fogg behaviour model principles drawn upon in the literature review. This objective is therefore considered achieved.

### 7.3.4 Primary Objective 3 — Investment Portfolio Management

The third primary objective was to provide basic investment portfolio management capabilities. The investment module supports six asset classes — stocks, unit trusts, bonds, cryptocurrencies, ETFs, and commodities — with manual entry of purchase price, current value, and quantity. The portfolio overview screen presents unrealised gains and losses with percentage returns per holding and aggregated across the portfolio.

All investment-related functional test cases passed, confirming that the core data management operations function correctly. The module fulfils the "basic" scope defined in the objective, providing a structured record-keeping and monitoring capability. The known limitation of manual value updates, discussed further in Section 7.5, does not negate the achievement of the stated objective but does represent a clear opportunity for future enhancement.

### 7.3.5 Primary Objective 4 — Cross-Platform Accessibility

The fourth primary objective was to ensure cross-platform accessibility for both Android and iOS users. This was achieved through the Flutter framework, which produces native-quality applications for both platforms from a single Dart codebase. The system was tested on physical Android devices and the iOS Simulator, with all 50 functional test cases and all 7 security test cases passing across both environments.

The use of Material Design widgets — adopted as a deliberate mitigation strategy for platform-specific rendering inconsistencies, discussed in Section 7.6 — ensured a consistent visual and interactive experience regardless of operating system. This objective is considered fully achieved.

### 7.3.6 Secondary Objectives

The three secondary objectives — trust-centred interface design, personalised financial insights, and comprehensive usability testing — were each addressed to a satisfactory degree.

Trust-centred design was realised through the security architecture: two-factor authentication with TOTP and backup codes, JWT-based session management with per-device revocation, a security activity log, and a quantified security score system that gives users visible feedback on their account protection posture. The 100% pass rate across all seven security test cases confirms the correctness of these mechanisms.

Personalised financial insights were delivered through the analytics module, which renders spending trends, income versus expense comparisons, and category-level breakdowns as interactive charts. The report export feature further supports informed personal decision-making by allowing users to retain and review their own financial data outside the application.

Comprehensive usability testing was conducted with six participants using a structured task-based protocol, a post-task satisfaction questionnaire, and the System Usability Scale instrument. While the participant count is modest — a limitation acknowledged in Section 7.5 — the methodology was systematic and the results were analysed rigorously, providing a credible basis for evaluation.

---

## 7.4 Contributions

### 7.4.1 Academic Contributions

SmartFinance makes a modest but meaningful contribution to the applied research literature on gamification in personal finance applications. The project operationalises and empirically evaluates a multi-mechanism gamification model — combining achievement badges, experience points, levelling, streaks, and social comparison — within a single application targeted specifically at the Malaysian young adult demographic. The usability study, while limited in scale, contributes a structured dataset linking gamification design choices to self-reported engagement and satisfaction, providing a foundation that future work could build upon with larger sample sizes and longitudinal methods.

The project also contributes to the body of practice-based knowledge on integrating behavioural design principles — specifically the Fogg Behaviour Model and Self-Determination Theory — into the design of financial wellness applications. The mapping of these theoretical constructs to concrete feature decisions, documented through the design and implementation chapters, provides a replicable methodological approach for future software engineering final year projects in this domain.

### 7.4.2 Technical Contributions

From a technical standpoint, the project demonstrates a reproducible full-stack architecture for cross-platform mobile finance applications. The combination of Flutter, Python Flask, and MySQL is well-suited to rapid development by a single developer, and the clean separation between the mobile client and RESTful API means that either layer can be replaced or scaled independently. The codebase — which is fully commented at a beginner level across all 92 source files — serves as an accessible reference implementation for students and developers approaching mobile application development for the first time.

The Financial Insights module represents a practical contribution to the body of knowledge on data-driven financial self-awareness tools. By computing a four-pillar health score — savings rate, budget adherence, spending consistency, and goal progress — entirely from the user's own transaction history and presenting the results as ranked, actionable insight cards, the module demonstrates a lightweight pattern for generating personalised financial guidance without reliance on external data sources or machine learning models. The system's security architecture — encompassing TOTP-based two-factor authentication, backup code management, per-device session revocation, and a security activity log — provides a reusable blueprint for implementing layered account security in Flask-based web APIs.

### 7.4.3 Societal Contributions

SmartFinance addresses a genuine and pressing social problem. Financial literacy among Malaysian youth remains low, and the consequences — rising personal debt, inadequate savings rates, and vulnerability to predatory financial products — are well documented. By providing a free, accessible, and locally contextualised tool for financial self-management, the project contributes directly to the goal of improving financial wellbeing among a demographic that stands to benefit most from early, sustained engagement with budgeting and saving behaviours.

The gamification layer is particularly significant from a societal perspective. It targets the engagement and motivation barriers that cause most users of conventional budgeting tools to abandon them within weeks of installation. By making financial management intrinsically rewarding through progress mechanics, social comparison, and recognition, SmartFinance is designed to foster sustained behavioural change rather than transient interest. The usability results — an average satisfaction score of 4.30 out of 5.00 and a SUS score of 78.5 — provide preliminary evidence that this design intent is being realised in practice.

---

## 7.5 Limitations and Future Improvements

### 7.5.1 Current Limitations

Every software project developed under time, resource, and scope constraints carries limitations, and SmartFinance is no exception. An honest acknowledgement of these limitations is essential both for academic integrity and for establishing a clear roadmap for future development.

The following limitations characterise the current version of the system:

- **Manual data entry.** All transactions, investment holdings, and investment values must be entered manually by the user. No integration with banking APIs or financial data aggregators exists. This is the most significant friction point in the user experience and the area most likely to result in user abandonment over time, as maintaining accurate records demands consistent effort.

- **No real-time market data.** Investment portfolio valuations depend entirely on the user manually updating the current price of each holding. There is no connection to live market data feeds for equities, unit trusts, cryptocurrencies, or commodities. This limits the utility of the portfolio module for users who require up-to-date performance tracking.

- **Limited usability study scale.** The usability evaluation was conducted with seven participants. While the results are encouraging and the methodology is sound, a sample of this size is insufficient to make statistically robust claims about usability across the broader target population of Malaysian young adults. Cultural, linguistic, and demographic diversity within that population is not fully captured.

- **Local deployment only.** During the FYP period, the Flask backend runs on the developer's local machine. There is no cloud-hosted instance, which means the application cannot be distributed to end users beyond the immediate testing environment. The hardcoded base URL configuration further compounds this limitation, requiring a manual update to the IP address each time the network environment changes.

- **No offline mode.** All data operations require an active internet connection. The application does not cache data for offline viewing and does not support offline entry with subsequent synchronisation. Users in low-connectivity environments — which remain common in parts of Malaysia — are unable to use the application when connectivity is unavailable.

- **Scope exclusions.** Advanced financial planning features — including retirement planning calculators, income tax estimation, loan repayment schedules, and emergency fund guidance — are outside the current scope. These are features that would substantially increase the practical value of the application for users making medium- to long-term financial decisions.

### 7.5.2 Future Improvements

The limitations identified above directly inform the following recommendations for future development:

- **Bank API and Open Finance integration.** Integrating with Malaysian banking institutions' APIs — where available through programmes such as Bank Negara Malaysia's open banking initiative — or with third-party financial data aggregation services would eliminate manual transaction entry and significantly reduce the primary friction point in the user experience.

- **Real-time market data feeds.** Connecting the investment module to publicly available or subscription-based market data APIs (for example, Yahoo Finance, Alpha Vantage, or CoinGecko for cryptocurrencies) would enable automatic portfolio valuation updates, transforming the module from a manual record-keeping tool into a live monitoring dashboard.

- **Cloud deployment and scalable infrastructure.** Migrating the Flask backend to a cloud platform such as AWS, Google Cloud, or Microsoft Azure would enable genuine multi-user access, remove the hardcoded IP dependency, and provide a foundation for production-grade reliability, security, and scalability. A proper domain name, HTTPS termination, and environment-based configuration management would be essential components of this migration.

- **Offline-first architecture.** Implementing a local SQLite cache with background synchronisation — using Flutter's `drift` or `sqflite` package alongside a conflict resolution strategy — would allow users to view and enter data without an internet connection, with changes synchronised automatically when connectivity is restored.

- **Expanded usability and longitudinal studies.** Future evaluation should involve a larger and more demographically representative participant pool. A longitudinal study tracking actual usage behaviour over a period of four to twelve weeks would provide far stronger evidence of the gamification system's effectiveness in sustaining financial management habits than the cross-sectional usability study conducted during this FYP.

- **Advanced financial planning modules.** Adding retirement planning calculators, EPF and KWSP contribution tracking, income tax estimation based on Malaysian tax brackets, and loan repayment amortisation tools would substantially broaden the application's utility and differentiate it further from generic budgeting applications available on the market.

- **Notification and reminder system.** Although the notification service was scaffolded during this project, a fully implemented push notification system — reminding users of upcoming budget limits, overdue goal contributions, habit streak risks, and recurring transaction schedules — would directly support the behavioural design objective by reducing the cognitive burden of self-monitoring.

- **Social features and peer accountability.** Expanding the leaderboard into a fuller social layer — allowing users to follow friends, share achievements, or participate in savings challenges — would strengthen the social comparison and relatedness dimensions of the self-determination theory framework and may improve long-term engagement.

---

## 7.6 Issues and Solutions

The development of SmartFinance was not without technical challenges. This section documents the most significant issues encountered during the implementation phase and describes the solutions that were adopted. These experiences represent a valuable record of practical problem-solving in full-stack mobile development.

**Cross-platform widget rendering inconsistency.** Early testing on both Android and iOS revealed that certain Flutter widgets produced visually inconsistent results across platforms, particularly in the rendering of input fields, date pickers, and dialogue boxes. This was resolved by standardising on Material Design widgets throughout the application and avoiding the use of Cupertino-style widgets, which are optimised for iOS but introduce divergence when displayed on Android. Platform-specific testing was incorporated as a standard step throughout the development process to catch regressions early.

**JWT token expiry and silent logouts.** The initial implementation of JWT-based authentication did not handle token expiry gracefully. When a user's access token expired, API requests would fail silently, leaving the application in an inconsistent state without providing the user any indication of what had occurred. This was resolved by implementing a token refresh mechanism that automatically requests a new access token using the long-lived refresh token before the access token expires, and by adding a user-facing session expiry notification that prompts the user to re-authenticate if the refresh token itself has also expired.

**Financial Insights score accuracy with sparse data.** The Financial Health Score is computed from the current calendar month's transactions. For new users or users who had not recorded transactions for the full month, several pillars — particularly budget adherence and spending consistency — defaulted to zero or produced misleading low scores due to insufficient data. This was resolved by introducing a data sufficiency check in the `financial_insights.py` endpoint: pillars for which the required data is absent are assigned a neutral mid-range value rather than zero, and a contextual note is included in the insight cards informing the user that their score will become more accurate as they continue adding transactions.

**Two-factor authentication integration complexity.** Implementing TOTP-based two-factor authentication required careful coordination across multiple system components: QR code generation during setup, TOTP verification at login, backup code generation, storage, and one-time consumption, and the integration of 2FA status into the session validation logic. Early implementation attempts produced subtle flow errors in which the session could be established without completing the 2FA step. This was resolved by adopting the RFC 6238 TOTP standard as implemented by the `pyotp` library, redesigning the authentication flow as an explicit two-stage process with server-side state tracking, and writing dedicated test cases for each 2FA scenario.

**Database field naming mismatch.** The SQLAlchemy data models used PascalCase column naming conventions consistent with Python class attribute style, while the Flutter Dart models expected camelCase JSON keys consistent with Dart naming conventions. This mismatch caused silent null values in the Flutter models when deserialising API responses — a category of bug that is particularly difficult to diagnose because the application continues to run without throwing an error, but displays missing or zero-valued data to the user. The issue was resolved comprehensively by adding explicit key mapping in every `to_dict()` method on the SQLAlchemy models, ensuring that the JSON output consistently used the camelCase keys expected by the Dart client.

**Chart rendering performance on low-end devices.** The `fl_chart` library produced smooth animations and responsive interactions on modern mid-range and high-end devices. However, testing on older low-end Android devices revealed frame rate drops during chart rendering, particularly for line charts displaying large numbers of data points across extended date ranges. This was addressed by reducing the density of data points rendered at any one time — aggregating daily data to weekly averages for ranges exceeding 90 days — and by deferring chart initialisation until the data is fully loaded, preventing partially rendered frames from being displayed.

**Decimal type serialisation incompatibility in Flask 3.0.** MySQL's `NUMERIC` and `DECIMAL` column types are returned by the PyMySQL driver as Python `decimal.Decimal` objects rather than native floating-point numbers. Flask 3.0's default JSON provider does not include a serialiser for `Decimal`, causing `jsonify()` to raise a `TypeError` and return an HTTP 500 error whenever any API response included a monetary value drawn directly from a SQLAlchemy model field. The failure was silent from the Flutter client's perspective — the API response indicated failure without a user-visible crash — but resulted in report screens rendering empty data. The issue was resolved by applying an explicit `float()` conversion to every `Decimal`-typed field at the point of constructing the JSON response dictionaries across the spending report, budget report, and category analysis endpoints. This conversion is now applied consistently throughout the `reports.py` module as a standard pattern.

**Android 11 URL launch restriction on export downloads.** The CSV export feature in the Reports screen used Flutter's `url_launcher` package to open a backend-generated CSV file directly in the device's default browser. On Android 11 and later (API level 30+), the operating system requires applications to explicitly declare which URL schemes they intend to open via a `<queries>` block in the `AndroidManifest.xml` file. Without this declaration, the `canLaunchUrl()` function returns `false` for all `http://` and `https://` URLs, causing the download action to complete silently without providing the user any feedback or file. The issue was resolved by adding `<intent>` entries for the `VIEW` action with `http` and `https` data schemes to the manifest's `<queries>` block, restoring correct URL launch behaviour on Android 11+ devices. An additional `else` branch was added to the download handler to display a meaningful error message in the event that URL launching fails despite the manifest declaration.

---

## 7.7 Conclusion

SmartFinance set out to address a real and consequential problem: the disengagement of Malaysian young adults from personal financial management, driven by a combination of low financial literacy, poorly designed tools, and the absence of intrinsic motivation to engage with budgeting as a sustained habit. The project responds to this problem with a purposefully designed, full-featured mobile application that integrates practical financial management capabilities with a scientifically grounded gamification system, all delivered through a single cross-platform codebase accessible to both Android and iOS users.

The results documented in Chapter 5 confirm that the system achieves its objectives to a degree that meets or exceeds every predefined acceptance criterion. A 100% functional test pass rate across 50 test cases demonstrates the correctness and reliability of the implemented features. A 100% security test pass rate across 7 security tests validates the robustness of the authentication and data protection architecture. A 91.7% usability task completion rate, a satisfaction score of 4.30 out of 5.00, and a System Usability Scale average of 78.5 collectively confirm that the application is genuinely usable by its intended audience without requiring prior technical expertise or financial knowledge.

Beyond meeting its stated objectives, SmartFinance delivers several features that were not in the original scope — including a Financial Insights module with personalised health scoring, two-factor authentication, recurring transaction management, session revocation, and a security scoring system — demonstrating an iterative development mindset and a commitment to producing software that reflects the genuine security and usability expectations of a contemporary mobile application. The limitations that remain — primarily the absence of bank API integration, real-time market data, cloud deployment, and offline support — are well understood, honestly acknowledged, and mapped to concrete future development directions.

Taken together, the achievements of this project demonstrate that a single developer, working within the constraints of a final year project, can deliver a technically sound, feature-rich, and user-validated mobile application that makes a meaningful contribution to the challenge of financial wellness among Malaysian young adults. SmartFinance provides both a working software artefact and a replicable architectural and methodological template that future work can build upon, extend, and — ultimately — deploy to the users it was designed to serve.

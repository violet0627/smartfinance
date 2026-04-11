# Chapter 1 — Introduction: Revisions Document

## Overview

This document contains revised text for every AI-flagged section in Chapter 1. The changes address four recurring issues: (1) bolded "Connection / Link / Summary" callout paragraphs that do not appear in natural academic writing, (2) an overly long and self-congratulatory Chapter Summary (1.8), (3) an inflated Abstract closing sentence, and (4) bullet-heavy subsections in 1.4.2 that read as AI-generated structured output rather than prose.

Each revision below is labelled with the precise action to take in your Word document.

---

## Revision 1 — Abstract

**Action:** Replace the entire Abstract with the text below.

---

Financial literacy among Malaysian young adults remains low, with many lacking the basic knowledge needed for long-term financial stability. This project addresses that gap by developing SmartFinance, a gamified cross-platform mobile application designed for Malaysian young adults aged 18–30. The application combines practical financial management with behavioural design principles to encourage sustainable financial habits through expense tracking, budget management, and basic investment portfolio monitoring.

The project uses Agile development methodology with user-centred design, built on Flutter for cross-platform mobile development, Python Flask for backend services, and MySQL for data management. Gamification elements — including achievement badges, habit streaks, and progress celebrations — are incorporated to address the psychological barriers that prevent consistent financial tracking. Core features include expense categorisation, visual budget monitoring, spending pattern analysis, and manual investment tracking without third-party banking integration.

User feedback was gathered through Google Forms surveys distributed to university students and young professionals, with usability testing conducted among peers to validate the design and feature effectiveness. The application targets university students managing RM500–1,500 monthly and entry-level professionals earning RM2,000–4,000 monthly.

The project contributes to Malaysian financial literacy by providing culturally appropriate tools that reflect local banking habits and spending patterns. Expected outcomes include improved financial tracking consistency, enhanced financial literacy through guided experiences, and sustainable habit formation through motivational design.

---

## Revision 2 — Section 1.1 Project Background

**Action:** Find the bold paragraph beginning **"Sustainable Development Goals (SDG) Alignment:"** and replace it with the plain paragraph below.

---

This project also aligns with broader development goals — specifically SDG 4 (Quality Education) and SDG 8 (Decent Work and Economic Growth) — by promoting financial literacy through accessible digital tools and empowering young adults with the financial management capabilities needed for long-term economic participation. These are goals that traditional academic curricula rarely address in a practical, applied way.

---

## Revision 3 — Section 1.1.1 Current Financial Management Challenges

**Action:** Delete the entire bolded **"Summary of Key Challenges:"** section (the bold heading and all five bullet points beneath it). Also delete the closing sentence that begins "These interconnected challenges necessitate...". Replace both with the single sentence below.

---

Taken together, these challenges point to a clear need for a solution specifically built around the behavioural patterns and cultural context of Malaysian young adults, rather than adapting tools designed for other markets.

---

## Revision 4 — Section 1.1.2 Target Demographic Analysis

**Action:** Find the bold paragraph beginning **"Rationale for Target Selection:"** and replace it with the plain paragraph below.

---

These two age groups were chosen because the 18–30 range represents a critical transition from financial dependence to independence, when financial habits and attitudes are still forming. Preliminary survey data indicated that this demographic shows both the highest need for financial literacy support and the greatest willingness to adopt digital solutions. The income ranges — RM500–1,500 for students and RM2,000–4,000 for young professionals — reflect typical Malaysian financial situations documented by the Department of Statistics Malaysia (2024), and are specific enough to guide focused feature design without being too narrow to be useful.

---

## Revision 5 — Section 1.1.3 Technological Foundation

**Action:** Find the bold paragraph beginning **"Appropriateness for Final Year Project:"** and replace it with the plain paragraph below.

---

These technology choices are well-suited to a Final Year Project context. Flutter's single codebase approach reduces development time compared to building separate native applications, making cross-platform delivery feasible within the academic timeline. Python Flask's minimalist design allows rapid API development without requiring deep backend expertise, and its modular structure supports incremental development in line with Agile methodology. MySQL's widespread adoption means documentation and troubleshooting support are readily available. Together, these technologies balance professional-grade capability with the practical learning constraints of a student-led project.

---

## Revision 6 — Section 1.4.2 Excluded Features (Out of Scope)

**Action:** Replace the entire content of Section 1.4.2 with the prose below. This removes all the bolded sub-bullet structures under each exclusion.

---

### 1.4.2 Excluded Features (Out of Scope)

Banking integration is excluded from this project. Connecting to third-party banking APIs would require compliance with Bank Negara Malaysia guidelines that are beyond the scope of a student project, introduce significant data security responsibilities, and require commercial partnerships unavailable to academic projects. The application therefore relies on manual transaction entry rather than automatic importing.

Real-time market data is similarly excluded. Reliable financial data APIs carry subscription costs unsuitable for a student project, and integrating multiple data sources for Malaysian stocks, funds, and bonds would significantly increase development complexity. Since the educational focus is on basic investment awareness, users can update prices manually from publicly available sources without losing the core value of the feature.

Advanced financial planning tools such as retirement planning, tax optimisation, or loan calculations fall outside the current scope. Accurate financial planning algorithms require actuarial and domain expertise beyond computer science, and providing such advice within an academic project raises regulatory and liability concerns that are inappropriate at this stage.

Multi-user collaboration features are not included, as they would require sophisticated access control and data synchronisation mechanisms. Research also indicates that young adults in this age group primarily manage finances individually rather than collaboratively, making this a low-priority feature for the target demographic.

---

## Revision 7 — Section 1.4.3 Project Limitations

**Action:** Delete the entire bolded **"Summary of Key Limitations:"** section (the bold heading and all six bullet points beneath it). Replace with the single sentence below, placed as the closing sentence of the section.

---

These limitations represent deliberate trade-offs that prioritise development feasibility, data privacy, and core functionality over a broader feature set that would be difficult to deliver effectively within FYP constraints.

---

## Revision 8 — Section 1.5.1 Societal Impact

**Action:** Delete the entire bold paragraph beginning **"Link to Problem Statement:"** (from "The problem statement identified..." to "...improved economic stability for this demographic."). The section ends at the paragraph referencing Fogg (2009).

---

## Revision 9 — Section 1.5.2 Academic and Technical Contributions

**Action:** Delete the entire bold paragraph beginning **"Connection to Problem Statement:"**. The section ends after the paragraph on UX design framework contributions.

---

## Revision 10 — Section 1.5.3 Commercial Potential

**Action:** Delete the entire bold paragraph beginning **"Addressing the Identified Gap:"**. The section ends at the existing paragraph:

> "The scalable design approach ensures that future expansion remains feasible without requiring complete system redesign, supporting potential long-term development beyond the academic project scope."

---

## Revision 11 — Section 1.8 Chapter Summary and Evaluation

**Action:** Replace the entire Section 1.8 with the text below. The original is far too long and reads as AI self-evaluation. Keep it short.

---

### 1.8 Chapter Summary

This chapter has established the foundation for the SmartFinance project. The financial literacy challenges facing Malaysian young adults aged 18–30 were identified and supported by data from Bank Negara Malaysia, AKPK, the Securities Commission Malaysia, and the Department of Statistics Malaysia. The problem statement, project objectives, scope, limitations, and development methodology were defined to provide clear direction for subsequent development phases.

Chapter 2 reviews existing literature on financial literacy, behavioural economics, gamification, and mobile application design to provide theoretical grounding for the decisions outlined here. Chapter 3 details the methodology and requirements analysis, translating the problems identified in this chapter into specific technical and user experience requirements.

---

---

## CONTENT CORRECTIONS (apply after language revisions above)

---

## Content Revision 12 — Section 1.3.1 Objective 3: Investment Types

**Action:** Find the bullet point under Objective 3 that reads:
> "Implementation of investment transaction recording for at least three major investment types (stocks, funds, bonds)"

Replace it with:
> Implementation of investment transaction recording across ten asset types — Stocks, Cryptocurrency, Bonds, Mutual Funds, ETF, Real Estate, Commodities, Fixed Deposit, Unit Trust, and Other — covering the full range of investment vehicles relevant to Malaysian young adults

---

## Content Revision 13 — Section 1.3.1 Objective 3: Remove Educational Content Bullet

**Action:** Find and delete the bullet point:
> "Provision of educational content covering at least five fundamental investment concepts relevant to Malaysian markets"

No replacement needed — this feature was not implemented.

---

## Content Revision 14 — Section 1.3.1 Objective 2: Add Leaderboard

**Action:** Find the paragraph beginning "To implement gamification and behavioural design elements..." (the Objective 2 description). At the end of this paragraph, add:

> A leaderboard ranks users by total XP, providing the peer comparison motivation identified in user research as a driver of sustained engagement.

---

## Content Revision 15 — Section 1.4.1: Add Recurring Transactions to Scope

**Action:** In the paragraph listing core financial management features (starting "The core financial management features include manual expense entry..."), add the following sentence after the sentence about budget monitoring:

> Recurring transaction scheduling allows users to set up regular income or expense entries on daily, weekly, monthly, or yearly schedules, with automatic execution tracking and pause/resume controls — reducing manual re-entry for fixed financial commitments such as subscriptions, rent, or salary.

---

## Content Revision 16 — Section 1.4.1: Add Two-Factor Authentication to Scope

**Action:** Find the sentence:
> "User management and security features encompass secure authentication and registration, data privacy protection and encryption, user profile management and preferences, and local data storage without third-party banking integration."

Replace it with:
> User management and security features encompass secure authentication and registration, optional two-factor authentication (TOTP) with backup codes, data privacy protection, user profile management and preferences, and server-side data storage without third-party banking integration.

---

## Content Revision 17 — Section 1.4.1: Add Financial Insights to Scope

**Action:** In the paragraph listing core financial management features, add the following sentence at the end of that paragraph:

> A Financial Insights screen generates a personalised financial health score and breakdown from the user's actual spending, budget, goal, and consistency data, surfacing actionable recommendations without requiring users to interpret raw numbers.

---

## Content Revision 18 — Section 1.4.3: Remove Progressive Web App Reference

**Action:** Find the sentence:
> "Mitigation strategies include implementing progressive web app capabilities as a backup option, ensuring offline functionality for core features, and conducting extensive testing across budget Android devices commonly used by students."

Replace it with:
> Mitigation strategies include conducting extensive testing across budget Android devices commonly used by students and optimising API response times to remain within the 2-second usability threshold across varying network conditions.

---

## Content Revision 19 — Section 1.4.3: Remove Customisable Gamification Intensity

**Action:** Find the sentences:
> "To accommodate this diversity, the application will implement customisable gamification intensity levels, allowing users to enable or disable specific motivational features. Cultural consultation with Malaysian advisors will ensure that achievement systems remain respectful and appropriate."

Replace with:
> To accommodate diversity in motivational preferences, the gamification system is designed to feel encouraging rather than pressuring — achievement notifications appear as positive celebrations rather than failure warnings, and cultural appropriateness of achievement names and categories was validated through peer feedback with Malaysian users.

---

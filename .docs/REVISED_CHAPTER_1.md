# Chapter 1: Introduction

## 1 Introduction

This chapter presents an overview of the SmartFinance project, a gamified cross-platform mobile application designed to address financial literacy challenges among Malaysian young adults. The chapter outlines the project background and motivation, defines the problem statement, establishes the project objectives and scope, and describes the development methodology and organisational structure that guided the project.

---

## 1.1 Project Background

Young adults in Malaysia face considerable challenges when it comes to managing personal finances effectively. Despite widespread access to smartphones and digital technology, many struggle to develop consistent financial management habits. This disconnect between available technology and actual usage suggests that current financial management tools fail to address the specific needs and behavioural patterns of this demographic.

This project also aligns with broader development goals, specifically SDG 4 (Quality Education) and SDG 8 (Decent Work and Economic Growth), by promoting financial literacy through accessible digital tools and empowering young adults with the financial management capabilities needed for long-term economic participation. These are goals that traditional academic curricula rarely address in a practical, applied way.

### 1.1.1 Current Financial Management Challenges

The difficulty young adults face in maintaining consistent financial tracking habits stems from a complex interplay of psychological and practical factors. Behavioural economics research has shown that cognitive biases such as present bias, where immediate gratification is valued over future benefits, and loss aversion significantly undermine sustained financial management efforts (Kahneman and Tversky, 1979). Traditional financial tools often overlook these behavioural principles, focusing instead on feature-rich interfaces that can overwhelm users rather than motivate them.

Existing financial management applications present several limitations for Malaysian young adults. International solutions like Mint and You Need a Budget (YNAB) are designed around Western banking systems, featuring automatic bank integration and credit score tracking that do not align with Malaysian financial practices (Chen et al., 2020). Meanwhile, local applications tend to emphasise comprehensive financial analysis without adequately considering the motivational factors that influence sustained engagement among younger users.

Several Malaysian financial applications have struggled to gain traction with young adults. While Touch 'n Go eWallet has achieved success as a payment platform, it lacks the comprehensive budgeting features that appeal to users seeking financial education (Malaysia Digital Economy Corporation, 2023). BigPay offers budgeting tools but requires multiple app integrations that many students find cumbersome. Similarly, GrabPay provides basic expense tracking without the motivational elements needed to maintain user engagement over time.

Traditional banking apps face similar challenges. Research indicates that a significant proportion of young adults aged 18 to 25 find conventional banking apps overwhelming and discontinue use within the first month (Asian Banking and Finance, 2023). The pattern that emerges from these local solutions is clear: while the technical capabilities exist, user experience design and behavioural engagement strategies fail to meet the specific needs of Malaysian young adults who are transitioning from financial dependence to independence.

Taken together, these challenges point to a clear need for a solution specifically built around the behavioural patterns and cultural context of Malaysian young adults, rather than adapting tools designed for other markets.

### 1.1.2 Target Demographic Analysis

This project targets two distinct but related segments within Malaysia's young adult population. The first consists of university students aged 18 to 24 who typically manage monthly allowances ranging from RM500 to RM1,500. For many in this group, this represents their first experience handling personal finances independently. Preliminary discussions with university students suggest that while many attempt various financial tracking methods, maintaining consistent usage remains a significant challenge.

The second segment comprises young professionals aged 22 to 30, typically entry-level workers earning between RM2,000 and RM4,000 monthly. This group needs tools that strike a balance between sophistication and accessibility, particularly for investment tracking and long-term financial planning as they establish their careers and build financial foundations.

These two age groups were chosen because the 18 to 30 range represents a critical transition from financial dependence to independence, when financial habits and attitudes are still forming. Preliminary survey data indicated that this demographic shows both the highest need for financial literacy support and the greatest willingness to adopt digital solutions. The income ranges, RM500 to RM1,500 for students and RM2,000 to RM4,000 for young professionals, reflect typical Malaysian financial situations documented by the Department of Statistics Malaysia (2024), and are specific enough to guide focused feature design without being too narrow to be useful.

### 1.1.3 Technological Foundation

The proposed solution leverages modern cross-platform development technologies to ensure broad accessibility and a consistent user experience. Flutter, Google's UI framework, enables unified development for both Android and iOS platforms while maintaining native-like performance (Google Developers, 2024). Python Flask provides a robust backend infrastructure for data management and user authentication, offering the scalability needed for financial applications (Pallets Projects, 2024). MySQL serves as the database management system, ensuring reliable data storage and retrieval for long-term financial tracking.

These technology choices are well-suited to a Final Year Project context. Flutter's single codebase approach reduces development time compared to building separate native applications, making cross-platform delivery feasible within the academic timeline. Python Flask's minimalist design allows rapid API development without requiring deep backend expertise, and its modular structure supports incremental development in line with Agile methodology. MySQL's widespread adoption means documentation and troubleshooting support are readily available. Together, these technologies balance professional-grade capability with the practical learning constraints of a student-led project.

---

## 1.2 Problem Statement

Malaysian young adults currently lack access to culturally appropriate and engaging financial management tools that effectively combine practical functionality with the behavioural design principles necessary for developing sustainable financial habits. Existing solutions often overwhelm users with excessive complexity or fail to provide sufficient motivational elements for consistent usage, potentially limiting financial literacy development and effective money management skills.

The extent of this problem is well-documented. Bank Negara Malaysia's Financial Capability and Inclusion Survey revealed that financial literacy remains inadequate among a substantial portion of young Malaysians, with many having never created a personal budget (Bank Negara Malaysia, 2019). The Credit Counselling and Debt Management Agency (AKPK) has reported concerning debt-to-income ratios among young Malaysians, indicating widespread financial management challenges (AKPK, 2023).

The Department of Statistics Malaysia has documented that a large proportion of young adults live paycheck-to-paycheck, despite most expressing a desire to improve their financial management skills (Department of Statistics Malaysia, 2024). Additionally, the Securities Commission Malaysia found that young adult participation in investment activities remains low, with lack of knowledge and confidence cited as primary barriers (Securities Commission Malaysia, 2023).

A preliminary survey conducted across several Malaysian universities revealed that most students rely on manual tracking methods such as notebooks or basic spreadsheets, which they typically abandon within two months. Nearly half of the respondents had attempted multiple financial apps but found them either too complex or culturally inappropriate for their needs.

The fundamental problem is therefore that Malaysian young adults lack financial management tools specifically designed to address their unique combination of challenges: limited financial literacy, cultural expectations around money management, a preference for simple interfaces over complex features, a need for motivational support to maintain tracking consistency, and a transition status between financial dependence and independence. Existing solutions either target Western markets with different cultural contexts or prioritise feature comprehensiveness over user engagement, leaving Malaysian young adults without effective tools to develop essential financial management capabilities during this critical life stage.

---

## 1.3 Project Objectives

### 1.3.1 Primary Objectives

**Objective 1: Develop a User-Friendly Financial Tracking System**

To develop a user-friendly financial tracking system that provides intuitive expense tracking and budget management suitable for varying levels of financial literacy. Success will be measured by:

- Implementation of at least eight core financial management features including expense categorisation, budget creation, spending visualisation, and monthly summaries
- Achievement of average task completion times under 30 seconds for common operations such as expense entry and budget checking
- Usability testing scores averaging 4.0 or higher on a 5-point scale across ease of use, clarity of information, and navigation efficiency metrics

**Objective 2: Implement Gamification and Behavioural Design**

To implement gamification and behavioural design elements that encourage positive financial behaviours and sustained application usage. Measurable outcomes include:

- Development of at least 15 achievement badges tied to specific financial milestones
- Implementation of habit streak tracking with visual progress indicators
- Integration of at least five behavioural nudge mechanisms based on established behavioural economics principles
- Achievement of user engagement metrics showing at least 70% of test users returning to the application within 48 hours during the beta testing period
- A leaderboard that ranks users by total XP, providing the peer comparison motivation identified in user research as a driver of sustained engagement

**Objective 3: Provide Basic Investment Portfolio Management**

To provide basic investment portfolio management capabilities enabling users to manually record investment activities, monitor portfolio performance, and track progress against budgeted targets. Success criteria include:

- Implementation of investment transaction recording across ten asset types, namely Stocks, Cryptocurrency, Bonds, Mutual Funds, ETF, Real Estate, Commodities, Fixed Deposit, Unit Trust, and Others, covering the full range of investment vehicles relevant to Malaysian young adults
- Calculation and display of basic portfolio performance metrics including total invested amount, current value, and percentage gain or loss
- Integration of investment goal setting features with progress visualisation

**Objective 4: Ensure Cross-Platform Accessibility**

To ensure cross-platform accessibility by delivering a functional mobile application compatible with both Android and iOS platforms. Deliverables include:

- Fully functional application versions for Android 8.0 and above and iOS 12.0 and above
- Consistent feature parity across both platforms with no platform-specific functionality limitations
- Responsive user interface adapting appropriately to screen sizes ranging from 4.5 to 6.5 inches
- Successful deployment to at least 20 test devices representing diverse hardware specifications including budget, mid-range, and flagship models

### 1.3.2 Secondary Objectives

Beyond the primary goals, this project aims to establish a trust-centred interface design that builds user confidence when handling financial data. This involves creating a professional user interface with clear privacy indicators and secure authentication methods. The application will also generate personalised financial insights, offering straightforward advice based on spending patterns, goal-oriented feedback, and content tailored to young adult financial challenges.

Comprehensive usability testing with target demographic users will validate the user experience, ensuring that both the interface and features effectively meet user needs. Success will be measured through usability testing sessions with at least 12 participants from the target demographic, achieving average System Usability Scale (SUS) scores of 70 or above, and incorporating feedback from at least 80% of identified usability issues into final design iterations.

---

## 1.4 Project Scope

### 1.4.1 Included Features (In Scope)

The core financial management features include manual expense entry with intelligent categorisation, budget creation and monitoring with visual progress indicators, spending pattern analysis through interactive charts and reports, and monthly and weekly financial summaries. These features form the foundation of the application's financial management functionality.

Recurring transaction scheduling allows users to set up regular income or expense entries on daily, weekly, monthly, or yearly schedules, with automatic execution tracking and pause and resume controls, reducing manual re-entry for fixed financial commitments such as subscriptions, rent, or salary.

Investment tracking capabilities include manual investment portfolio tracking, the ability to record investment purchases and monitor performance, investment goal setting with progress visualisation, and basic portfolio analytics and reporting. These features remain accessible to investment beginners while providing adequate functionality for users developing their investment strategies.

The gamification system includes an achievement badge system for reaching financial milestones, habit streak tracking for consistent logging behaviour, progress celebrations and motivational notifications, and user level progression based on financial activities.

User management and security features encompass secure authentication and registration, optional two-factor authentication (TOTP) with backup codes, data privacy protection, user profile management and preferences, and server-side data storage without third-party banking integration.

A Financial Insights screen generates a personalised financial health score derived from the user's actual spending, budget, goal, and consistency data, surfacing actionable recommendations without requiring users to interpret raw numbers.

### 1.4.2 Excluded Features (Out of Scope)

Banking integration is excluded from this project. Connecting to third-party banking APIs would require compliance with Bank Negara Malaysia guidelines that are beyond the scope of a student project, introduce significant data security responsibilities, and require commercial partnerships unavailable to academic projects. The application therefore relies on manual transaction entry rather than automatic importing.

Real-time market data is similarly excluded. Reliable financial data APIs carry subscription costs unsuitable for a student project, and integrating multiple data sources for Malaysian stocks, funds, and bonds would significantly increase development complexity. Since the educational focus is on basic investment awareness, users can update prices manually from publicly available sources without losing the core value of the feature.

Advanced financial planning tools such as retirement planning, tax optimisation, or loan calculations fall outside the current scope. Accurate financial planning algorithms require actuarial and domain expertise beyond computer science, and providing such advice within an academic project raises regulatory and liability concerns that are inappropriate at this stage.

Multi-user collaboration features are not included, as they would require sophisticated access control and data synchronisation mechanisms. Research also indicates that young adults in this age group primarily manage finances individually rather than collaboratively, making this a low-priority feature for the target demographic.

### 1.4.3 Project Limitations

Several limitations must be acknowledged. The reliance on manual data entry may impact convenience compared to automated solutions. To mitigate this, the application implements intelligent expense categorisation and quick-entry features that minimise input time. The user interface features large, touch-friendly elements and suggestions based on common Malaysian spending categories such as mamak, Grab rides, and university fees.

Without real-time market data integration, investment tracking remains limited to user-provided information. To address this, the application provides a manual price update mechanism so users can maintain accurate portfolio valuations using publicly available market data.

The gamification approach may not appeal uniformly across the target demographic, as motivational preferences can vary. To accommodate this diversity, the gamification system is designed to feel encouraging rather than pressuring: achievement notifications appear as positive celebrations rather than failure warnings, and the cultural appropriateness of achievement names and categories was validated through peer feedback with Malaysian users.

Technical limitations include dependency on user device capabilities and potential performance variations across mobile platforms. Mitigation strategies include conducting extensive testing across budget Android devices commonly used by students and optimising API response times to remain within the two-second usability threshold across varying network conditions.

The application architecture is designed with API integration capabilities that would allow future connection to Malaysian banking APIs when regulatory frameworks permit, and to investment platforms for automated price updates. These current manual entry limitations are therefore deliberate stepping stones toward broader automation in future iterations.

These limitations represent deliberate trade-offs that prioritise development feasibility, data privacy, and core functionality over a broader feature set that would be difficult to deliver effectively within FYP constraints.

---

## 1.5 Project Significance and Contributions

### 1.5.1 Societal Impact

This application aims to contribute meaningfully to financial literacy improvement among Malaysian young adults, potentially supporting broader economic resilience and reducing financial vulnerability. By providing accessible and culturally appropriate financial management tools, the project addresses a demonstrated need that extends beyond individual benefit to community-level financial capability enhancement.

The project applies behavioural psychology principles and gamification strategies to demonstrate how technology can encourage positive habit formation in personal finance management. This approach contributes to understanding how digital interventions can effectively address behavioural barriers to financial literacy development (Fogg, 2009).

### 1.5.2 Academic and Technical Contributions

From an academic perspective, this project contributes to Human-Computer Interaction research by investigating gamification effectiveness in financial applications and examining behavioural design principles for habit formation in mobile environments. The implementation demonstrates practical application of the Flutter framework for financial applications, contributing to mobile development best practices and cross-platform development methodology.

The user experience design framework established through this project can serve as a reference for future financial education tools, contributing knowledge regarding culturally appropriate technology design. The design methodology and findings provide guidance for developers creating financial applications for similar demographic groups.

### 1.5.3 Commercial Potential

The application addresses a gap in Malaysian fintech solutions specifically targeted at young adults. While commercial viability cannot be definitively assessed within the Final Year Project timeframe, the technical architecture provides a foundation for potential future development and integration opportunities.

The current Malaysian fintech landscape focuses primarily on payments such as Touch 'n Go and GrabPay, or comprehensive banking through Maybank MAE and CIMB Octo, without specifically addressing young adult financial education needs. SmartFinance occupies a distinct position by combining behavioural psychology, cultural appropriateness, and practical financial tools specifically for the 18 to 30 demographic.

With over 2.8 million Malaysians aged 20 to 29 (Department of Statistics Malaysia, 2024) and smartphone penetration exceeding 95% in this demographic, the potential market represents a significant opportunity. University enrolment exceeding 500,000 students provides a concentrated initial market for validation and growth.

Future monetisation possibilities could include premium features such as advanced analytics and financial coaching, partnerships with Malaysian investment platforms including ASNB and unit trust companies, and educational content sponsorships from financial institutions seeking to engage young adults. The scalable design approach ensures that future expansion remains feasible without requiring complete system redesign, supporting potential long-term development beyond the academic project scope.

---

## 1.6 Project Team and Organisation

### 1.6.1 Project Team Structure

The project team consists of the student developer, Siow Chuan Sheng from the RSW Programme, who holds primary responsibility for all development activities including requirements analysis, system design, implementation, testing, and documentation. This role also encompasses coordinating user research and managing usability testing to ensure comprehensive coverage of both technical development and user experience validation.

Project supervision is provided by Ms. Siti Nadiah binti Nain, who offers technical guidance and academic supervision throughout the project lifecycle. The supervisor's role includes monitoring progress, evaluating milestones, and ensuring both project quality and adherence to academic standards.

Project progress is monitored through several structured mechanisms. Weekly supervisor meetings provide regular touchpoints for progress review, challenge discussion, and guidance on technical decisions. These meetings follow a standardised agenda covering completed work, current challenges, and plans for the coming week. Bi-weekly milestone reviews assess deliverable completion against the project timeline, with formal evaluation of sprint outcomes including functional demonstrations and documentation review. Additionally, the developer maintains a digital project log documenting daily progress, technical decisions, challenges encountered, and solutions implemented, which serves as both a progress tracking tool and reference for final documentation. This multi-layered monitoring approach ensures early identification of delays or challenges, enabling timely intervention and adjustment of project plans when necessary.

### 1.6.2 Stakeholder Identification

Primary stakeholders include the target users, namely Malaysian university students and young professionals aged 18 to 30, who represent the principal beneficiaries of the project outcomes. Academic supervisors and the evaluation committee constitute critical stakeholders responsible for project assessment and academic validation. The Faculty of Computing and Information Technology at Tunku Abdul Rahman University of Management and Technology serves as the institutional stakeholder, providing resources, guidance, and the academic framework necessary for project completion.

Secondary stakeholders include the university student community participating in testing and feedback provision, contributing to user experience validation and system refinement. The broader Malaysian fintech ecosystem represents an additional stakeholder group with potential interest in project outcomes for future development opportunities.

---

## 1.7 Development Methodology

The project employs Agile Development methodology integrated with User-Centred Design principles and iterative usability testing. This approach enables responsive development and consistent incorporation of user feedback throughout the development lifecycle, allowing adaptation to user needs and technical challenges while maintaining progress toward established objectives.

**Table 1.7.1: Project Phase Timeline and Activities**

| Phase | Duration | Key Activities | Deliverables |
|-------|----------|----------------|--------------|
| Phase 1: Foundation (FYP1) | Weeks 1–2 | Requirements gathering, user research, system architecture design | Requirements document, user personas, system design specifications |
| | Weeks 3–4 | Core expense tracking module development and testing | Functional expense tracking module, unit test suite |
| | Week 5 | Budget management module implementation and integration testing | Integrated budget and expense modules, integration test results |
| Phase 2: Enhancement (FYP2) | Weeks 1–2 | Gamification system implementation | Achievement system, habit tracking, progress visualisation |
| | Weeks 3–4 | Investment tracking module development | Investment recording and portfolio analytics features |
| | Weeks 5–6 | System integration, performance optimisation | Optimised integrated system, performance test results |
| | Weeks 7–8 | Comprehensive testing, user acceptance testing, refinement | Final application, test documentation, user feedback reports |

This table illustrates how Agile sprints structure development across Project 1 and Project 2, with each phase building incrementally upon previous work while maintaining focus on delivering functional components that can be tested and refined based on user feedback.

User feedback is collected primarily through Google Forms surveys distributed to university students and young professionals within accessible networks. The surveys assess current financial management practices, app preferences, and feature priorities. This approach allows for reaching a reasonable number of respondents while remaining feasible within the constraints of a university Final Year Project.

Usability testing is conducted with fellow students and peers who fit the target demographic profile. Participants are asked to use the application and provide feedback on user interface design, feature functionality, and overall user experience. Testing sessions are kept informal and practical, focusing on identifying usability issues and gathering suggestions for improvement.

Initial testing uses low-fidelity prototypes such as wireframes and mockups shared with classmates and friends to validate basic design concepts and user flow. Feedback at this stage focuses on whether the information architecture makes sense and whether navigation feels intuitive. As development progresses, a working version of the application is shared with volunteer testers from the university community, who use the app for a short period and provide feedback through Google Forms or informal discussions.

The feedback integration process involves reviewing survey responses and tester comments regularly, identifying common themes or critical issues, and prioritising improvements based on feasibility and impact. Changes are implemented iteratively during development sprints to ensure continuous improvement based on actual user input.

---

## 1.8 Chapter Summary

This chapter has established the foundation for the SmartFinance project. The financial literacy challenges facing Malaysian young adults aged 18 to 30 were identified and supported by data from Bank Negara Malaysia, AKPK, the Securities Commission Malaysia, and the Department of Statistics Malaysia. The problem statement, project objectives, scope, limitations, and development methodology were defined to provide clear direction for subsequent development phases.

Chapter 2 reviews existing literature on financial literacy, behavioural economics, gamification, and mobile application design to provide theoretical grounding for the decisions outlined here. Chapter 3 details the methodology and requirements analysis, translating the problems identified in this chapter into specific technical and user experience requirements.

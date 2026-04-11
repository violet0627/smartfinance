# Chapter 3 — Methodology and Requirements Analysis: Revisions Document

## Overview

Chapter 3 has two recurring AI patterns:

1. **"Link to User Personas:" bold callout paragraphs** — appears 11 times, once after every single functional and non-functional requirement (FR001–FR005, NFR001–NFR006). This is the same structural problem as "Connection to SmartFinance:" in Chapter 2.

2. **Miscellaneous bold callout headings** — "Visual Representation of Integrated Methodology:", "Sample Size Considerations and Limitations:", "Core Functionality Requirements:", and "Connection to System Design Chapter:" all follow the same AI-generated labelled-box pattern.

The fix is consistent throughout: remove the bold label and either (a) keep the paragraph as plain prose with a natural opening, or (b) delete it where the connection to the personas is already obvious from the requirement description itself.

Section 3.7 Chapter Summary is overly long and ends with the "Connection to System Design Chapter:" callout — it needs trimming and that callout removed.

Everything else in Chapter 3 — the Agile/UCD methodology description, sprint structure, user personas, FR/NFR content, risk management sections, and UX design methodology — is well-written and reads naturally. No changes needed there.

---

## Revision 1 — Section 3.1.1 (Visual Representation bold heading)

**Action:** Find the bold heading **"Visual Representation of Integrated Methodology:"** that appears just before Figure 3.1.1. Delete the bold heading entirely. Replace it with the plain sentence below, which naturally introduces the figure.

---

Figure 3.1.1 illustrates how Agile sprints incorporate User-Centered Design activities across both Project 1 and Project 2 phases.

---

## Revision 2 — Section 3.2.1 (Sample Size Considerations bold heading)

**Action:** Find the bold heading **"Sample Size Considerations and Limitations:"** and delete it. The paragraph that follows (starting "The target sample of 20-25 survey respondents...") can remain as-is — it already reads well as a standalone paragraph without needing a labelled heading.

---

## Revision 3 — Section 3.3.2 (Core Functionality Requirements bold heading)

**Action:** Find the bold heading **"Core Functionality Requirements:"** and delete it. The section heading 3.3.2 already establishes this context. The first requirement (FR001) follows immediately and needs no additional label.

---

## Revision 4 — FR001: Link to User Personas paragraph

**Action:** Find the bold **"Link to User Personas:"** paragraph under FR001. Delete the bold label. Rewrite the opening sentence as below, then keep the rest unchanged.

**Revised opening sentence:**
> This requirement addresses both Siti's need for simple, non-intimidating account setup and Rahman's expectation of professional security standards.

---

## Revision 5 — FR002: Link to User Personas paragraph

**Action:** Find the bold **"Link to User Personas:"** paragraph under FR002. Delete the bold label. Rewrite the opening sentence as below, then keep the rest unchanged.

**Revised opening sentence:**
> Quick expense entry with intelligent categorisation directly addresses Siti's pain point of inconsistent tracking by reducing friction in the logging process.

---

## Revision 6 — FR003: Link to User Personas paragraph

**Action:** Find the bold **"Link to User Personas:"** paragraph under FR003. Delete the bold label. Rewrite the opening sentence as below, then keep the rest unchanged.

**Revised opening sentence:**
> Visual progress indicators and real-time tracking address Siti's need for immediate feedback and achievement visualisation.

---

## Revision 7 — FR004: Link to User Personas paragraph

**Action:** Find the bold **"Link to User Personas:"** paragraph under FR004. Delete the bold label. Rewrite the opening sentence as below, then keep the rest unchanged.

**Revised opening sentence:**
> This feature primarily serves Rahman's goal of starting investment tracking while remaining accessible for Siti's future needs.

---

## Revision 8 — FR005: Link to User Personas paragraph

**Action:** Find the bold **"Link to User Personas:"** paragraph under FR005. Delete the bold label and delete the entire paragraph. The three preceding paragraphs in FR005 already explain the gamification system clearly — the persona connection is obvious and does not need restating.

---

## Revision 9 — NFR001: Link to User Personas paragraph

**Action:** Find the bold **"Link to User Personas:"** paragraph under NFR001. Delete the bold label and delete the entire paragraph. The requirement already clearly explains why 2-second response time matters for users who log expenses during brief moments — the persona connection adds nothing new.

---

## Revision 10 — NFR002: Link to User Personas paragraph

**Action:** Find the bold **"Link to User Personas:"** paragraph under NFR002. Delete the bold label and delete the entire paragraph. Android 8.0+ and offline functionality are self-evidently useful for the target demographic — restating this for Siti and Rahman adds no value.

---

## Revision 11 — NFR003: Link to User Personas paragraph

**Action:** Find the bold **"Link to User Personas:"** paragraph under NFR003. Delete the bold label. Rewrite as a single plain closing sentence for the NFR003 section:

---

These security measures address both personas' concern about trusting a financial app with sensitive data, with PDPA compliance and transparent privacy explanations being particularly important for first-time users like Siti.

---

## Revision 12 — NFR004: Link to User Personas paragraph

**Action:** Find the bold **"Link to User Personas:"** paragraph under NFR004. Delete the bold label and delete the entire paragraph. The reliability requirements are self-explanatory and the persona connections stated are very thin.

---

## Revision 13 — NFR005: Link to User Personas paragraph

**Action:** Find the bold **"Link to User Personas:"** paragraph under NFR005. Delete the bold label and delete the entire paragraph. The usability requirements have already been explained clearly and in terms of the target demographic throughout NFR005 — the persona callout is redundant.

---

## Revision 14 — NFR006: Link to User Personas paragraph

**Action:** Find the bold **"Link to User Personas:"** paragraph under NFR006. Delete the bold label. Rewrite as a single plain closing sentence for the NFR006 section:

---

The use of "allowance" rather than "income" specifically reflects Siti's situation as a student receiving money from parents, and the respect for family-oriented financial goals accommodates both personas' cultural context.

---

## Revision 15 — Section 3.7 Chapter Summary and Evaluation (trim + remove callout)

**Action:** Replace the entire Section 3.7 with the text below. The original is five long paragraphs followed by a "Connection to System Design Chapter:" callout box. The callout should be removed and the summary trimmed to three focused paragraphs.

---

### 3.7 Chapter Summary

This chapter has established the methodology and requirements framework for the SmartFinance project. The integration of Agile development with User-Centered Design principles provides a development approach suited to a financial application where user trust, cultural sensitivity, and iterative refinement are essential. The scaled research approach — 10–12 interviews, 20–25 surveys, and 12–15 beta testers — balances validity with the practical constraints of a Final Year Project.

The requirements analysis captures both functional and non-functional requirements grounded in the user research findings. Functional requirements (FR001–FR005) address the core user needs identified through persona development and survey data. Non-functional requirements (NFR001–NFR006) set concrete quality, security, and usability standards appropriate for a financial application. The risk management framework identifies technical, timeline, and adoption risks alongside realistic mitigation strategies.

The functional requirements defined here translate directly into system components, database schemas, and interface designs in Chapter 4. The non-functional requirements inform architectural patterns, security implementation choices, and performance optimisation strategies. Each design decision in Chapter 4 can be traced back to a specific requirement or user need documented in this chapter.

---

---

## CONTENT CORRECTIONS (apply after language revisions above)

---

## Content Revision 16 — FR001: Correct JWT Token Expiry

**Action:** Find the sentence in FR001:
> "The implementation will use JWT token authentication with 7-day expiry, balancing security with convenience for daily use."

Replace it with:
> The implementation uses a dual-token JWT system: access tokens expire after one hour, limiting the window of exposure if a token is compromised, while refresh tokens have a 30-day lifespan so users are not forced to log in repeatedly during normal use.

---

## Content Revision 17 — FR001: Add Two-Factor Authentication

**Action:** After the paragraph ending "Profile customisation and privacy settings give users control over their data and experience." (the last paragraph before the "Link to User Personas" block), add:

> For users who require enhanced security, the system supports optional two-factor authentication (TOTP). During setup, the application generates a QR code for scanning with any standard authenticator app. Ten single-use backup codes are also generated and displayed for safekeeping in case the authenticator device is unavailable. 2FA can be enabled or disabled from the Security Settings screen at any time.

---

## Content Revision 18 — FR002: Add Recurring Transactions

**Action:** After the last paragraph of FR002 (the paragraph about Malaysian Ringgit formatting), add a new paragraph:

> The system also supports recurring transactions. Users define a template with a name, type, category, amount, and frequency (daily, weekly, monthly, or yearly). The system tracks the next due date and either executes the transaction automatically when the user opens the app, or allows manual execution on demand. Recurring templates can be paused and resumed; when resumed after a gap, the system advances the next execution date rather than creating backdated entries for missed periods.

---

## Content Revision 19 — FR004: Correct Investment Types

**Action:** Find the opening sentence of FR004:
> "Users must be able to manually record investment transactions including stocks, funds, and bonds."

Replace it with:
> Users can manually record investment transactions across ten asset types: Stocks, Cryptocurrency, Bonds, Mutual Funds, ETF, Real Estate, Commodities, Fixed Deposit, Unit Trust, and Other.

---

## Content Revision 20 — FR004: Remove Investment Education Content Paragraph

**Action:** Find and delete the paragraph:
> "The system will provide basic investment education content relevant to Malaysian markets. Rather than trying to compete with dedicated investment platforms, the focus is on demystifying investment concepts and building confidence among beginners."

Replace it with:
> The investment tracking interface uses asset type labels familiar to Malaysian users — including Fixed Deposit, Unit Trust, and Commodities — so that users do not need to map their holdings to generic categories. Portfolio performance is displayed visually through gain/loss indicators, making it accessible to beginners without requiring them to calculate returns manually.

---

## Content Revision 21 — NFR002: Correct Offline Functionality Claim

**Action:** Find the paragraph in NFR002:
> "The system should support offline functionality for core features with data synchronisation. Users might want to log expenses in areas with poor connectivity, so the app needs to function offline and sync when connectivity returns."

Replace it with:
> Data is stored server-side via the Flask API rather than locally on the device. This means the application requires an active internet connection for core operations. Offline support was not implemented within the FYP timeline and is identified as a candidate for future enhancement. The server-side storage model does, however, ensure that financial data is not at risk of loss if the user's device is lost or replaced.

---

## Content Revision 22 — NFR003: Correct Encryption Claims

**Action:** Find the two sentences:
> "All user financial data must be encrypted using AES-256 encryption standards. Financial data is sensitive, and encryption protects it both in transit and at rest. This level of encryption meets banking industry standards and builds user confidence."

And separately:
> "Local data storage will use encrypted databases with secure key management. Since the application stores data locally rather than relying solely on cloud storage, local encryption is essential."

Replace both blocks with:
> User passwords are stored exclusively as bcrypt hashes — plaintext passwords are never persisted anywhere in the system. All communication between the Flutter app and the Flask backend occurs over HTTPS, ensuring data is encrypted in transit. Financial data is stored server-side in MySQL; no sensitive financial data is cached or stored locally on the user's device, which eliminates the risk of data extraction from a lost or stolen phone.

---

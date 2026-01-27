# SmartFinance Survey - Complete Setup Guide

**Quick Start:** Creating Your Survey in Google Forms

---

## 📋 Step-by-Step Setup Instructions

### Step 1: Create New Google Form

1. Go to **https://forms.google.com**
2. Click **"+ Blank"** or use a template
3. Click on **"Untitled form"** at the top
4. Change title to: **"SmartFinance User Survey"**

---

### Step 2: Add Form Description

Click on "Form description" and paste:

```
Thank you for participating in this survey. Your feedback is invaluable for evaluating the SmartFinance mobile application, developed as part of a Final Year Project.

SmartFinance is a comprehensive personal finance management app that helps users track expenses, manage budgets, analyze spending patterns, and monitor investments.

* Indicates required question

Description for Scaling Questions:
1 - Very Poor
2 - Poor
3 - Neutral
4 - Good
5 - Excellent
```

---

### Step 3: Configure Settings

Click the **Settings (⚙️)** icon at the top right:

**General Tab:**
- ☑️ Collect email addresses (Optional - only if needed for follow-up)
- ☑️ Limit to 1 response
- ☑️ Respondents can edit after submit
- ☐ See summary charts and text responses (You'll see these anyway)

**Presentation Tab:**
- ☑️ Show progress bar
- ☑️ Shuffle question order: **UNCHECK** (keep logical flow)
- ☑️ Show link to submit another response
- Confirmation message: "Thank you for your feedback!"

**Quizzes Tab:**
- Leave this unchecked (not a quiz)

Click **Save**

---

### Step 4: Create Section 1 - Personal Information

#### Add Section Break
1. Click the **"+"** icon on the right sidebar
2. Select **"Add section"** icon (two rectangles)
3. Title: **"Section 1: Personal Information"**
4. Description: **"This section collects demographic information to understand our user base."**

#### Question 1: Age Group
- Click **"+ Add question"**
- Question text: **"What is your age group?"**
- Type: **Multiple choice**
- Options:
  ```
  18-24
  25-34
  35-44
  45-54
  55 and above
  ```
- Toggle **"Required"** ON

#### Question 2: Educational Level
- Type: **Multiple choice**
- Question: **"What is your educational level?"**
- Options:
  ```
  Secondary School / High School
  Diploma
  Bachelor's Degree
  Master's Degree
  PhD
  Others
  ```
- Toggle **"Required"** ON

#### Question 3: Employment Status
- Type: **Multiple choice**
- Question: **"What is your current employment status?"**
- Options:
  ```
  Full-time employed
  Part-time employed
  Self-employed
  Student
  Unemployed
  Retired
  ```
- Toggle **"Required"** ON

#### Question 4: Monthly Income
- Type: **Multiple choice**
- Question: **"What is your approximate monthly income range?"**
- Options:
  ```
  Less than RM 1,500
  RM 1,500 - RM 3,000
  RM 3,001 - RM 5,000
  RM 5,001 - RM 8,000
  RM 8,001 - RM 12,000
  More than RM 12,000
  Prefer not to say
  ```
- Toggle **"Required"** ON

---

### Step 5: Create Section 2 - Current Financial Management

#### Add New Section
- Click **"Add section"** icon
- Title: **"Section 2: Current Financial Management Practices"**
- Description: **"This section explores your current methods of managing personal finances."**

#### Question 5: How Track Expenses
- Type: **Checkboxes** (allows multiple selections)
- Question: **"How do you currently track your expenses and income?"**
- Options:
  ```
  Manual notebook/journal
  Excel spreadsheet
  Mobile finance apps
  Online banking apps
  Pen and paper
  I don't track my finances
  ```
- Check **"Add 'Other'"** option
- Toggle **"Required"** ON

#### Question 6: Review Frequency
- Type: **Multiple choice**
- Question: **"How often do you review your financial transactions?"**
- Options:
  ```
  Daily
  Weekly
  Monthly
  Quarterly
  Rarely or never
  ```
- Toggle **"Required"** ON

#### Question 7: Challenges
- Type: **Checkboxes**
- Question: **"What challenges do you face when managing your finances?"**
- Options:
  ```
  Too time-consuming to track manually
  Forgetting to record transactions
  Difficulty categorizing expenses
  Lack of visualization/reports
  Hard to stick to budgets
  Cannot track multiple accounts
  No centralized system
  No challenges - satisfied with current method
  ```
- Check **"Add 'Other'"** option
- Toggle **"Required"** ON

#### Question 8: Used Finance Apps Before
- Type: **Multiple choice**
- Question: **"Have you used any personal finance mobile apps before?"**
- Options:
  ```
  Yes, currently using one
  Yes, but stopped using it
  No, never tried
  No, but interested to try
  ```
- Toggle **"Required"** ON

---

### Step 6: Create Section 3 - Mobile App Usage

#### Add New Section
- Title: **"Section 3: Mobile App Usage & Technology"**
- Description: **"This section asks about your technology usage and preferences."**

#### Question 9: Smartphone Platform
- Type: **Multiple choice**
- Question: **"What is your primary smartphone platform?"**
- Options:
  ```
  Android
  iOS (iPhone)
  Both
  I don't use a smartphone
  ```
- Toggle **"Required"** ON

#### Question 10: Comfort with Apps
- Type: **Linear scale**
- Question: **"How comfortable are you with using mobile applications?"**
- Scale: **1 to 5**
- Label for 1: **"Not comfortable"**
- Label for 5: **"Very comfortable"**
- Toggle **"Required"** ON

---

### Step 7: Create Section 4 - Features & Needs

#### Add New Section
- Title: **"Section 4: SmartFinance App Features & Needs"**
- Description: **"This section evaluates which features are important to you in a finance management app."**

#### Question 11: Most Useful Features
- Type: **Checkboxes**
- Question: **"Which features would be most useful to you in a personal finance app?"**
- Options:
  ```
  Transaction tracking (income & expenses)
  Budget creation and monitoring
  Spending analytics and charts
  Recurring transaction automation
  Bill reminders and notifications
  Investment portfolio tracking
  Receipt scanning (OCR technology)
  Data export (CSV/PDF)
  Two-factor authentication for security
  Multi-currency support
  ```
- Check **"Add 'Other'"** option
- Toggle **"Required"** ON

#### Question 12: Security Importance
- Type: **Linear scale**
- Question: **"How important is data security and privacy in a finance app?"**
- Scale: **1 to 5**
- Label for 1: **"Not important"**
- Label for 5: **"Extremely important"**
- Toggle **"Required"** ON

---

### Step 8: Create Section 5 - App Experience (WITH SKIP LOGIC)

#### Add New Section
- Title: **"Section 5: SmartFinance App Experience"**
- Description: **"This section evaluates your experience using the SmartFinance application. If you haven't tested the app, please select 'N/A - Haven't tested the app' for rating questions."**

#### Question 13: Have You Tested (IMPORTANT - SKIP LOGIC)
- Type: **Multiple choice**
- Question: **"Have you tested or used the SmartFinance application?"**
- Options:
  ```
  Yes, I have tested it
  No, I haven't tested it
  ```
- Toggle **"Required"** ON
- **Click the three dots (⋮)** at bottom right of question
- Select **"Go to section based on answer"**
- Set up:
  - **"Yes, I have tested it"** → Continue to next section
  - **"No, I haven't tested it"** → Skip to Section 6

#### Question 14: Rate UI/Design
- Type: **Linear scale**
- Question: **"How would you rate the overall user interface (UI) and design of SmartFinance?"**
- Scale: **0 to 5**
- Label for 0: **"N/A - Haven't tested"**
- Label for 1: **"Very Poor"**
- Label for 5: **"Excellent"**
- Toggle **"Required"** ON

#### Question 15: Ease of Use
- Type: **Linear scale**
- Question: **"How easy was it to navigate and use the SmartFinance app?"**
- Scale: **0 to 5**
- Label for 0: **"N/A - Haven't tested"**
- Label for 1: **"Very difficult"**
- Label for 5: **"Very easy"**
- Toggle **"Required"** ON

#### Question 16: Feature Satisfaction Grid
- Type: **Multiple choice grid**
- Question: **"How satisfied are you with the following features?"**
- Rows (one per line):
  ```
  Transaction management (Add/Edit/Delete)
  Budget creation and tracking
  Analytics and spending charts
  Recurring transactions
  Investment portfolio
  Overall app performance
  ```
- Columns (one per line):
  ```
  1 (Very Poor)
  2
  3
  4
  5 (Excellent)
  N/A
  ```
- Check **"Require a response in each row"**
- Toggle **"Required"** ON

#### Question 17: Improvements (Optional)
- Type: **Paragraph**
- Question: **"What improvements or additional features would you like to see in SmartFinance?"**
- Toggle **"Required"** OFF (this one is optional)
- Add description: **"(Optional)"**

---

### Step 9: Create Section 6 - Overall Satisfaction

#### Add New Section
- Title: **"Section 6: Overall Satisfaction & Future Usage"**
- Description: **"This section evaluates your overall satisfaction and future intentions."**

#### Question 18: Likelihood to Use
- Type: **Linear scale**
- Question: **"Based on your experience or understanding of SmartFinance, how likely are you to use it for managing your personal finances?"**
- Scale: **1 to 5**
- Label for 1: **"Very unlikely"**
- Label for 5: **"Very likely"**
- Toggle **"Required"** ON

#### Question 19: Likelihood to Recommend
- Type: **Linear scale**
- Question: **"How likely are you to recommend SmartFinance to friends or family?"**
- Scale: **1 to 5**
- Label for 1: **"Very unlikely"**
- Label for 5: **"Very likely"**
- Toggle **"Required"** ON

#### Question 20: Overall Rating
- Type: **Linear scale**
- Question: **"Overall, how would you rate the SmartFinance application as a personal finance management solution?"**
- Scale: **1 to 5**
- Label for 1: **"Very Poor"**
- Label for 5: **"Excellent"**
- Toggle **"Required"** ON

---

### Step 10: Customize Confirmation Message

1. Click **Settings (⚙️)** → **Presentation** tab
2. In **"Confirmation message"** field, enter:
   ```
   Thank you so much for your time and valuable feedback! Your responses will help improve SmartFinance and contribute to the success of this Final Year Project.

   If you have any questions or would like to learn more about SmartFinance, please contact: [Your Email]
   ```

---

### Step 11: Customize Theme & Appearance

1. Click the **palette icon** at the top right
2. **Header:** Upload SmartFinance app screenshot or logo (optional)
3. **Theme color:** Choose blue/gradient color matching your app
4. **Background color:** White or light gray
5. **Font style:** Choose readable font (e.g., "Basic")

---

### Step 12: Preview & Test

1. Click the **eye icon (👁️)** at top right to preview
2. **Test the form yourself**:
   - Fill it out completely
   - Test the skip logic (Q13 → should skip to Section 6 if "No")
   - Check all required fields work
   - Verify all scales display correctly
3. Check responses in **Responses** tab

---

### Step 13: Get Shareable Link

1. Click **Send** button at top right
2. Choose how to share:
   - **Link icon:** Get shareable URL
   - Click **"Shorten URL"** to get short link
   - Copy the link

**OR**

3. Get QR Code:
   - Use a QR code generator (e.g., qr-code-generator.com)
   - Paste your form link
   - Download QR code
   - Print for campus distribution

---

## 📊 After Data Collection

### View Responses

1. Click **Responses** tab at top
2. View summary charts automatically generated
3. Click **green spreadsheet icon** to export to Google Sheets
4. Download as CSV for analysis in Excel

### Analyze Data

**Key Metrics to Calculate:**
- **Response rate:** (Responses / People sent to) × 100
- **Demographics breakdown:** Age, education, income distribution
- **Feature popularity:** Which features users want most
- **Average satisfaction:** Mean score for Q14, Q15, Q20
- **Net Promoter Score (NPS):** Based on Q19
  - Promoters (5): % who gave 5
  - Passives (3-4): % who gave 3-4
  - Detractors (1-2): % who gave 1-2
  - **NPS = % Promoters - % Detractors**
- **Qualitative themes:** Common suggestions from Q17

---

## 📈 Creating Charts for FYP Report

### In Google Sheets (After Export):

1. **Pie Charts:** Demographics (age, education, income)
2. **Bar Charts:** Feature preferences, current tracking methods
3. **Line Charts:** Satisfaction scores comparison
4. **Word Cloud:** Q17 open-ended responses (use wordclouds.com)

### Example Charts to Include:

1. **Respondent Demographics:**
   - Age distribution (pie chart)
   - Employment status (bar chart)
   - Income levels (bar chart)

2. **Current Practices:**
   - How people track finances (horizontal bar)
   - Tracking frequency (pie chart)
   - Challenges faced (horizontal bar - sorted by count)

3. **SmartFinance Evaluation:**
   - Feature satisfaction ratings (grouped bar chart)
   - Overall ratings comparison (radar chart)
   - UI/UX scores (line chart)

4. **User Intent:**
   - Likelihood to use (stacked bar showing distribution)
   - Likelihood to recommend - NPS visualization

---

## ✅ Survey Launch Checklist

**Before launching:**
- [ ] All 20 questions created
- [ ] All required fields marked (except Q17)
- [ ] Skip logic set up (Q13)
- [ ] Confirmation message customized
- [ ] Theme and colors applied
- [ ] Preview tested completely
- [ ] Tested on mobile device
- [ ] Shareable link created
- [ ] QR code generated (if needed)

**Distribution:**
- [ ] Send to 5 friends first (pilot test)
- [ ] Fix any issues found
- [ ] Send to larger audience
- [ ] Post on social media
- [ ] Share in WhatsApp groups
- [ ] Email to classmates/contacts
- [ ] Print QR codes for campus

**Target:** 50-100 responses minimum for valid analysis

---

## 🎯 Tips for Maximum Responses

1. **Timing:** Share during lunch hours or evenings (better response rate)
2. **Incentive:** Consider small prize draw (optional)
3. **Follow-up:** Send reminder after 3-4 days
4. **Personal touch:** Add note explaining it's for FYP
5. **Make it easy:** Use QR codes in person, short links online
6. **Multiple channels:** Don't rely on just one distribution method

---

## 📞 Support

If you encounter any issues:
- Google Forms Help: https://support.google.com/docs/answer/6281888
- YouTube: Search "How to create Google Forms survey"
- Your files: All survey questions are in `SMARTFINANCE_SURVEY_QUESTIONS.md`

---

**You're all set! Good luck with your survey! 🚀**

Remember: 50-100 responses is excellent for FYP analysis. Quality feedback is more important than quantity.

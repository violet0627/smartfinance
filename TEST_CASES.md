# SmartFinance — Full Application Test Cases
### Manual QA Test Plan

**How to use this document:**
- Go through each section in order
- For each test case, do exactly what the steps say
- Write PASS or FAIL next to the test case number
- If FAIL, write what actually happened

**Before you start:**
- Docker is running (`docker-compose up -d`)
- Emulator is running
- App is freshly installed (or wiped) so you start with no existing account

---

## Module 1 — Onboarding

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 1.1 | Onboarding shows on first launch | Fresh install → open app | Onboarding slides appear, NOT the login screen |
| 1.2 | Can swipe through slides | Swipe left on each slide | Each slide advances correctly, last slide shows "Get Started" or similar button |
| 1.3 | Get Started navigates to login | Press Get Started / final button | Navigates to Login screen |
| 1.4 | Onboarding skipped on second launch | Close and reopen app | Goes straight to Login screen, NOT onboarding again |

---

## Module 2 — Registration

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 2.1 | Successful registration | Fill all fields correctly → Create Account | Success dialog appears saying account created, two buttons: "Verify Email" and "Login Now" |
| 2.2 | Empty full name blocked | Leave full name empty → Create Account | Error: "Please enter your full name" |
| 2.3 | Empty email blocked | Leave email empty → Create Account | Error: "Email is required" |
| 2.4 | Invalid email format blocked | Enter "notanemail" → Create Account | Error about valid email format |
| 2.5 | Password too short blocked | Enter password shorter than 8 chars → Create Account | Error: "Password must be at least 8 characters" |
| 2.6 | Password missing uppercase blocked | Enter "password1!" → Create Account | Error about uppercase letter |
| 2.7 | Password missing lowercase blocked | Enter "PASSWORD1!" → Create Account | Error about lowercase letter |
| 2.8 | Password missing symbol blocked | Enter "Password1" → Create Account | Error about symbol |
| 2.9 | Password mismatch blocked | Enter different passwords in Password and Confirm Password → Create Account | Error: "Passwords do not match" |
| 2.10 | Terms checkbox required | Leave Terms unchecked → Create Account | SnackBar: "Please agree to the Terms & Conditions" |
| 2.11 | Duplicate email blocked | Try to register with an email already in the database | Error about email already registered |
| 2.12 | Password strength indicators appear | Type something in password field | Real-time indicators appear (green checkmarks / red X) showing length, uppercase, lowercase, symbol requirements |
| 2.13 | Phone number optional | Leave phone empty → register | Registration succeeds |
| 2.14 | Invalid phone format blocked | Enter "123" → Create Account | Error about valid Malaysian phone number |
| 2.15 | Back to login works | Press back arrow | Returns to Login screen |

---

## Module 3 — Email Verification

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 3.1 | Token field is empty on arrival | Register → press "Verify Email" in success dialog | Verification screen opens with an **empty** token field (NOT pre-filled) |
| 3.2 | Empty token blocked | Leave token empty → press Verify Email | Error: "Please enter the verification token" |
| 3.3 | Wrong token rejected | Type random text as token → press Verify Email | Error: "Invalid or expired verification token" |
| 3.4 | Correct token verifies | Check your email inbox → copy the real token → paste → press Verify Email | Success dialog: "Your email has been verified successfully!" with "Go to Dashboard" button |
| 3.5 | Go to Dashboard works and user is logged in | Press "Go to Dashboard" after successful verification | Dashboard loads with your actual account data (not empty, not "user not logged in") |
| 3.6 | Resend verification works | Press "Didn't receive the email? Resend" | SnackBar: "Verification email sent" (check inbox for new email) |
| 3.7 | Resend does NOT auto-fill token | Press Resend → wait for success message | Token field stays empty after resend (user must still manually enter token from email) |
| 3.8 | Back to Login works | Press "Back to Login" | Returns to Login screen |

---

## Module 4 — Login

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 4.1 | Successful login | Enter valid email + password → Login | Dashboard loads with user's data |
| 4.2 | Empty email blocked | Leave email empty → Login | Error shown |
| 4.3 | Empty password blocked | Leave password empty → Login | Error shown |
| 4.4 | Wrong password rejected | Correct email + wrong password → Login | Error: "Invalid email or password" (or similar) |
| 4.5 | Nonexistent email rejected | Email not in database → Login | Error: "Invalid email or password" (should NOT say which one is wrong — security) |
| 4.6 | Remember me / auto-login | Login → close app → reopen | Goes directly to Dashboard (not Login screen) — if auto-login is implemented |
| 4.7 | Forgot Password link visible | Open login screen | "Forgot Password?" link visible |
| 4.8 | Register link navigates | Press "Create Account" or "Register" link | Goes to Registration screen |

---

## Module 5 — Forgot Password / Reset Password

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 5.1 | Forgot password form accepts email | Press "Forgot Password?" → enter email → submit | Success message: "Reset email sent" or similar |
| 5.2 | Nonexistent email handled | Enter email not in database → submit | App shows a message (should NOT confirm whether email exists — security best practice) |
| 5.3 | Invalid email format blocked | Enter "notanemail" → submit | Error about valid email format |
| 5.4 | Empty email blocked | Leave email empty → submit | Error shown |
| 5.5 | Reset link/token received in email | Check inbox after step 5.1 | Email arrives with reset token or link |
| 5.6 | Valid reset token accepted | Enter token from email + new password + confirm → submit | Success: password changed, navigate to login |
| 5.7 | Weak new password blocked | Enter password that fails strength rules | Same password strength errors as registration |
| 5.8 | Password mismatch blocked | Enter different passwords → submit | Error: passwords do not match |
| 5.9 | Invalid reset token rejected | Type random text as token → submit | Error: "Invalid or expired token" |
| 5.10 | Old password no longer works after reset | Reset password → try logging in with OLD password | Login fails |
| 5.11 | New password works after reset | Reset password → login with NEW password | Login succeeds |

---

## Module 6 — Dashboard

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 6.1 | Dashboard loads without errors | Login → arrive at Dashboard | Dashboard loads, no error messages, no empty/broken widgets |
| 6.2 | Financial summary visible | Look at Dashboard | Shows total balance, income, expense (or similar overview) |
| 6.3 | Recent transactions visible | Have some transactions → view Dashboard | Recent transactions list shows |
| 6.4 | Empty state when no data | Fresh account with no transactions → Dashboard | Graceful empty state shown (e.g., "No transactions yet") |
| 6.5 | Unverified email banner shown | Login without verifying email → Dashboard | A banner/notice appears prompting user to verify email |
| 6.6 | Verify Now in banner works | Press "Verify Now" on email banner | Opens email verification screen |
| 6.7 | Bottom navigation works | Tap each icon in bottom nav bar | Navigates to correct screen (Transactions, Budget, Goals, etc.) |
| 6.8 | Pull to refresh works | Pull down on Dashboard | Data refreshes (loading indicator shown, then updated data) |

---

## Module 7 — Transactions

### 7A — Add Transaction

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 7A.1 | Add expense successfully | Press add → select Expense → fill amount, category, date, notes → Save | Transaction saved, appears in history |
| 7A.2 | Add income successfully | Press add → select Income → fill amount, category, date → Save | Transaction saved, income type shown correctly |
| 7A.3 | Zero amount blocked | Enter 0.00 as amount → Save | Error: amount must be greater than zero |
| 7A.4 | Negative amount blocked | Enter -50 → Save | Error or field doesn't allow it |
| 7A.5 | Empty amount blocked | Leave amount empty → Save | Error: amount is required |
| 7A.6 | Empty category blocked | Leave category empty → Save | Error: category is required |
| 7A.7 | Default date is today | Open add transaction | Date field shows today's date |
| 7A.8 | Can change date | Press date field → select a past date | Date updates to selected date |
| 7A.9 | Future date allowed or blocked | Select a future date | Clearly handled (either allowed or blocked with a message) |
| 7A.10 | Notes are optional | Leave notes empty → Save | Transaction saves successfully |
| 7A.11 | Cancel/back discards | Press Cancel or back arrow | Returns to previous screen, nothing saved |

### 7B — Transaction History

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 7B.1 | All transactions visible | Navigate to transaction history | All transactions shown in list |
| 7B.2 | Transactions sorted newest first | View history | Most recent transaction at top |
| 7B.3 | Filter by Income | Apply "Income" filter | Only income transactions shown |
| 7B.4 | Filter by Expense | Apply "Expense" filter | Only expense transactions shown |
| 7B.5 | Filter by date range | Set start date and end date | Only transactions within that range shown |
| 7B.6 | Clear filter shows all | Remove filter | All transactions shown again |
| 7B.7 | Empty state when no transactions | Fresh account → view history | "No transactions" message shown (not a crash or blank screen) |
| 7B.8 | Tap transaction to view detail | Tap on a transaction | Transaction detail shown (or edit screen opens) |
| 7B.9 | Edit transaction works | Edit a transaction field → Save | Change is reflected in the list |
| 7B.10 | Delete transaction works | Delete a transaction → confirm | Transaction removed from list, totals update |
| 7B.11 | Delete requires confirmation | Press delete | Confirmation dialog appears before actual deletion |

### 7C — Recurring Transactions

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 7C.1 | Add recurring transaction | Navigate to Recurring → Add → fill details → Save | Recurring transaction created successfully |
| 7C.2 | Required fields validated | Leave required fields empty → Save | Appropriate error messages |
| 7C.3 | View all recurring transactions | Navigate to Recurring Transactions | List of all active recurring transactions shown |
| 7C.4 | Delete recurring transaction | Delete a recurring transaction → confirm | Removed from list |
| 7C.5 | Frequency options available | Open frequency selector | Options like Daily, Weekly, Monthly available |

---

## Module 8 — Budgets

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 8.1 | Create budget successfully | Navigate to Budgets → Create → fill category, limit, period → Save | Budget created and appears in overview |
| 8.2 | Empty category blocked | Leave category empty → Save | Error shown |
| 8.3 | Zero/empty budget limit blocked | Enter 0 or leave empty → Save | Error: limit must be greater than zero |
| 8.4 | Budget overview loads | Navigate to Budget overview | All budgets listed with progress bars |
| 8.5 | Progress bar accurate | Create budget of RM500, add RM200 expense in that category | Progress shows 40% (RM200/RM500) |
| 8.6 | Over-budget highlighted | Spend more than budget limit | Budget shown in red / "over budget" indicator |
| 8.7 | Edit budget works | Edit budget limit → Save | New limit reflected in overview |
| 8.8 | Delete budget works | Delete a budget → confirm | Budget removed from list |
| 8.9 | Empty state when no budgets | Fresh account → Budgets | "No budgets yet" message (not crash) |
| 8.10 | Duplicate category budget handled | Create two budgets for the same category | Either blocked or both allowed (consistent behavior) |

---

## Module 9 — Goals

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 9.1 | Create goal successfully | Navigate to Goals → Add → fill name, target amount, deadline → Save | Goal created and appears in list |
| 9.2 | Empty goal name blocked | Leave name empty → Save | Error shown |
| 9.3 | Zero target amount blocked | Enter 0 → Save | Error shown |
| 9.4 | Past deadline handled | Enter a past date as deadline | Either blocked or allowed (consistent, no crash) |
| 9.5 | Goals list loads | Navigate to Goals | All goals shown with progress |
| 9.6 | Goal progress accurate | Create goal RM1000, add RM300 contribution | Progress shows 30% |
| 9.7 | Add contribution to goal | Press "Add Contribution" or similar → enter amount | Current amount increases, progress bar updates |
| 9.8 | Goal completion state | Contribute until 100% reached | Goal shown as "Completed" or similar |
| 9.9 | Edit goal works | Edit goal details → Save | Changes reflected in list |
| 9.10 | Delete goal works | Delete a goal → confirm | Goal removed from list |
| 9.11 | Empty state when no goals | Fresh account → Goals | "No goals yet" message (not crash) |

---

## Module 10 — Investments

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 10.1 | Add investment successfully | Navigate to Investments → Add → fill type, name, amount → Save | Investment created and appears in portfolio |
| 10.2 | Empty name blocked | Leave name empty → Save | Error shown |
| 10.3 | Zero amount blocked | Enter 0 → Save | Error shown |
| 10.4 | Investment types available | Open type selector | Options like Stocks, Crypto, Unit Trust, etc. available |
| 10.5 | Portfolio overview loads | Navigate to Portfolio | All investments listed with values |
| 10.6 | Total portfolio value shown | View portfolio with multiple investments | Total value calculated and displayed |
| 10.7 | Edit investment works | Edit investment details → Save | Changes reflected in portfolio |
| 10.8 | Delete investment works | Delete an investment → confirm | Removed from portfolio, total updates |
| 10.9 | Empty state when no investments | Fresh account → Portfolio | "No investments yet" message (not crash) |

---

## Module 11 — Analytics

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 11.1 | Analytics screen loads | Navigate to Analytics | Screen loads without errors |
| 11.2 | Charts render with data | Have transactions → view analytics | Charts/graphs display correctly (bars, pie, lines) |
| 11.3 | Empty state with no data | Fresh account → Analytics | Graceful empty state, no broken chart rendering |
| 11.4 | Income vs Expense chart correct | Have RM500 income and RM200 expense | Chart shows correct ratio |
| 11.5 | Category breakdown correct | Have expenses across different categories | Pie/bar chart shows correct category breakdown |
| 11.6 | Time period filter works | Switch between week / month / year | Charts update to show data for selected period |
| 11.7 | No data for period handled | Select a period with no transactions | Chart shows empty gracefully (no crash, no broken chart) |

---

## Module 12 — Financial Insights

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 12.1 | Insights screen loads | Navigate to Financial Insights | Screen loads without errors |
| 12.2 | Financial health score shown | Have some transactions → view insights | A health score (number or letter grade) is displayed |
| 12.3 | Score with no data | Fresh account → Insights | Graceful state (score of 0, or "insufficient data" message) |
| 12.4 | Spending insights visible | Have expenses → view insights | Spending breakdown / tips shown |
| 12.5 | Goal insights visible | Have goals → view insights | Goal progress mentioned in insights |
| 12.6 | Insights refresh with new data | Add a transaction → come back to Insights | Insights update to reflect new data |

---

## Module 13 — Reports

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 13.1 | Reports screen loads | Navigate to Reports | Screen loads without errors |
| 13.2 | Report generates with data | Have transactions → generate report | Report shows summary of income, expense, balance |
| 13.3 | Date range filter works | Set a custom date range → generate | Report shows data only for that period |
| 13.4 | Export to PDF works | Press Export PDF (if available) | PDF generated or download initiated without crash |
| 13.5 | Export to CSV works | Press Export CSV (if available) | CSV generated without crash |
| 13.6 | Empty report handled | Select date range with no data | "No data for this period" message (not crash) |

---

## Module 14 — Achievements / Gamification

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 14.1 | Achievements screen loads | Navigate to Achievements | Screen loads, list of achievements shown |
| 14.2 | Locked achievements shown | Fresh account | Locked achievements visible (greyed out / locked icon) |
| 14.3 | "First Step" unlocks | Add your first transaction | "First Step" achievement shows as unlocked (checkmark / badge) |
| 14.4 | "Budget Beginner" unlocks | Create your first budget | "Budget Beginner" achievement unlocked |
| 14.5 | "Investment Initiate" unlocks | Add your first investment | "Investment Initiate" achievement unlocked |
| 14.6 | XP / points displayed | View achievements | XP earned shown somewhere in the screen |
| 14.7 | Achievement progress visible | View partially-met achievement | Progress indicator shown (e.g., "3/7 days streak") |

---

## Module 15 — Settings

### 15A — Profile Edit

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 15A.1 | Profile screen loads | Settings → Edit Profile | Screen shows current full name, email, phone |
| 15A.2 | Edit full name works | Change full name → Save | New name saved, reflected everywhere |
| 15A.3 | Edit phone number works | Change phone → Save | New number saved |
| 15A.4 | Empty full name blocked | Clear full name → Save | Error: name is required |
| 15A.5 | Invalid phone format blocked | Enter "123" → Save | Error about phone format |
| 15A.6 | Email field read-only | Try to edit email field | Field is disabled or read-only (email cannot be changed here) |

### 15B — Security Settings

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 15B.1 | Security screen loads | Settings → Security | Screen loads with security score, email verification status, 2FA toggle |
| 15B.2 | Email verified status correct | After verifying email → Security settings | Shows "Email Verified" with green indicator |
| 15B.3 | Email unverified shows prompt | Login without verifying → Security settings | Shows "Email Not Verified" with option to verify |
| 15B.4 | Change password — correct current password | Enter correct current password + valid new password + confirm → Save | Password changed successfully |
| 15B.5 | Change password — wrong current password | Enter wrong current password → Save | Error: incorrect current password |
| 15B.6 | Change password — weak new password | Enter new password that fails strength rules | Same strength errors as registration |
| 15B.7 | Change password — mismatch | Enter different new and confirm passwords | Error: passwords do not match |
| 15B.8 | Active sessions visible | View Security screen | Current active sessions listed (or "No active sessions") |
| 15B.9 | Security log visible | View Security screen | Recent security events listed (logins, password changes) |
| 15B.10 | Delete account — correct password | Press Delete Account → enter correct password → confirm | Account deleted, navigates to Login screen |
| 15B.11 | Delete account — wrong password | Press Delete Account → enter wrong password → confirm | Error: incorrect password, stays on screen |
| 15B.12 | Delete account — cancel | Press Delete Account → press Cancel | Nothing deleted, stays on Security screen |
| 15B.13 | After delete, old credentials rejected | Delete account → try logging in with old email/password | Login fails (account no longer exists) |
| 15B.14 | After delete, session is cleared | Delete account → check if auto-login happens on reopen | No auto-login, shows Login screen fresh |

### 15C — Two-Factor Authentication (2FA)

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 15C.1 | 2FA setup screen accessible | Security Settings → Enable 2FA | QR code shown for authenticator app |
| 15C.2 | QR code generates | View 2FA setup screen | QR code and manual key are displayed |
| 15C.3 | Invalid code rejected during setup | Enter a wrong 6-digit code → Verify | Error: invalid or expired code |
| 15C.4 | Valid code enables 2FA | Enter correct code from authenticator app → Verify | 2FA enabled, backup codes shown |
| 15C.5 | Backup codes generated | Complete 2FA setup | A list of one-time backup codes shown |
| 15C.6 | Backup codes screen accessible | Settings → Backup Codes | Backup codes displayed |
| 15C.7 | 2FA required on login | Enable 2FA → logout → login again | After entering email+password, asked for 2FA code |
| 15C.8 | Correct 2FA code allows login | Enter correct code from app → submit | Dashboard loads |
| 15C.9 | Wrong 2FA code blocks login | Enter wrong 6-digit code → submit | Error: invalid code |
| 15C.10 | Backup code can be used | Use backup code instead of 2FA code | Login succeeds, backup code cannot be reused |
| 15C.11 | Disable 2FA works | Security → Disable 2FA → confirm | 2FA disabled, next login doesn't ask for code |

### 15D — General Settings

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 15D.1 | Settings screen loads | Navigate to Settings | Screen loads with all sections visible |
| 15D.2 | Dark mode toggle works | Toggle dark mode | App UI switches to dark theme |
| 15D.3 | Light mode toggle works | Toggle back to light mode | App UI switches back to light theme |
| 15D.4 | Theme persists on relaunch | Enable dark mode → close and reopen app | App still in dark mode |
| 15D.5 | Logout works | Press Logout → confirm | Clears session, navigates to Login screen |
| 15D.6 | After logout, can't go back | Logout → press Android back button | Stays on Login screen (or exits app), doesn't go back to Dashboard |

---

## Module 16 — Logout

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 16.1 | Logout clears session | Logout → reopen app | Shows Login screen, not Dashboard |
| 16.2 | Logout requires confirmation | Press Logout | Confirmation dialog appears before logging out |
| 16.3 | Cancel logout stays on screen | Press Logout → Cancel | Stays on current screen, still logged in |
| 16.4 | After logout, API calls fail | Logout → manually navigate back | API calls return 401 / app redirects to Login |

---

## Module 17 — Edge Cases and Stress Tests

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 17.1 | App works with no internet | Turn off WiFi → use app | Error messages shown gracefully (not crash) |
| 17.2 | App recovers when internet returns | Turn WiFi back on → retry action | Works normally again |
| 17.3 | Very long text input handled | Enter 500+ character notes → Save | Either truncates cleanly or shows max length error |
| 17.4 | Special characters in fields | Enter `<script>alert('xss')</script>` in any text field → Save | Saved and displayed as plain text (not executed) |
| 17.5 | Very large numbers | Enter 999999999 as amount → Save | Handled correctly (saved or blocked with clear message) |
| 17.6 | Decimal amounts | Enter 12.50 as amount | Stored and displayed as 12.50, not 12 or 12.5000 |
| 17.7 | Rapid button tapping | Tap "Save" button very fast multiple times | Only ONE request sent (button disabled after first tap) |
| 17.8 | Back button during loading | Press back while a loading spinner is showing | Either cancels gracefully or waits and then navigates back |
| 17.9 | Token expiry handled | Leave app open for 1+ hour → try an action | Either auto-refreshes token or redirects to Login cleanly (no crash) |
| 17.10 | Multiple accounts | Register two accounts → switch between them | Data from one account never appears in the other |

---

## Module 18 — Navigation and UI Consistency

| # | Test Case | Steps | Expected Result |
|---|---|---|---|
| 18.1 | All back buttons work | Press back button on every screen | Always returns to the correct previous screen |
| 18.2 | Bottom nav highlights active tab | Navigate to each tab | The active tab is highlighted in the bottom navigation bar |
| 18.3 | No orphaned screens | Navigate deeply then use bottom nav | Bottom nav always resets to correct state |
| 18.4 | Loading states shown | Tap any button that makes an API call | Loading spinner or disabled state shown while waiting |
| 18.5 | Error messages readable | Trigger any error | Error messages are clear English text (not "null" or stack traces) |
| 18.6 | App works in portrait | Use app normally | No layout breaks in portrait mode |
| 18.7 | App works in landscape | Rotate device to landscape | App adapts or at least doesn't break |
| 18.8 | Dark mode text readable | Enable dark mode → use all screens | All text is visible (no white text on white background, etc.) |
| 18.9 | App survives background/foreground | Put app in background → switch back | App resumes correctly, data still shown |

---

## Summary Checklist

After completing all tests, tally your results:

```
Module 1  — Onboarding:                __ / 4  passed
Module 2  — Registration:              __ / 15 passed
Module 3  — Email Verification:        __ / 8  passed
Module 4  — Login:                     __ / 8  passed
Module 5  — Forgot / Reset Password:   __ / 11 passed
Module 6  — Dashboard:                 __ / 8  passed
Module 7A — Add Transaction:           __ / 11 passed
Module 7B — Transaction History:       __ / 11 passed
Module 7C — Recurring Transactions:    __ / 5  passed
Module 8  — Budgets:                   __ / 10 passed
Module 9  — Goals:                     __ / 11 passed
Module 10 — Investments:               __ / 9  passed
Module 11 — Analytics:                 __ / 7  passed
Module 12 — Financial Insights:        __ / 6  passed
Module 13 — Reports:                   __ / 6  passed
Module 14 — Achievements:              __ / 7  passed
Module 15A — Profile Edit:             __ / 6  passed
Module 15B — Security Settings:        __ / 14 passed
Module 15C — Two-Factor Auth:          __ / 11 passed
Module 15D — General Settings:         __ / 6  passed
Module 16 — Logout:                    __ / 4  passed
Module 17 — Edge Cases:                __ / 10 passed
Module 18 — Navigation / UI:           __ / 9  passed

TOTAL:                                 __ / 197 passed
```

---

## How to Report Bugs Back to Claude

When you find a FAIL, report it like this:

> **Test case:** 7A.1  
> **What I did:** Added an expense with amount 50, category Food, today's date  
> **What happened:** App crashed / showed wrong amount / didn't save / showed error "null"  
> **Screenshot:** (attach if you have one)

The more detail you give, the faster the bug can be found and fixed.

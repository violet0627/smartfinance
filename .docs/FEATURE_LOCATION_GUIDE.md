# SmartFinance - Feature Location Guide

This guide explains where to find all features in the SmartFinance app.

---

## 🏠 Dashboard Screen (Home)

The **Dashboard** is the main screen you see after logging in. It contains:

### Financial Summary Cards
- **Balance Card** - Shows your current balance (blue-purple gradient)
- **Income Card** - Total income (green gradient)
- **Expense Card** - Total expenses (red gradient)

### Quick Actions (8 Buttons)
Located below the financial summary:
1. **Add Transaction** - Create new income/expense
2. **History** - View all transactions
3. **Analytics** - View charts and spending analysis
4. **Budget** - Manage budgets
5. **Reports** - Generate reports
6. **Portfolio** - View investments
7. **Goals** - Manage financial goals
8. **Achievements** - View gamification achievements

### Other Dashboard Widgets
- **Budget Progress Card** - Only appears if you have an active budget
- **Investment Portfolio Card** - Only appears if you have investments
- **Upcoming Bills Widget** - **Only appears if you have bills/reminders set up**
- **Goals Progress** - Only appears if you have active goals

---

## 💰 Transaction Features

### How to Add Transactions
1. **From Dashboard**: Tap "Add Transaction" in Quick Actions
2. **From Transaction History**: Tap the floating + button (bottom right)

### How to View Transaction History
1. **From Dashboard**: Tap "History" in Quick Actions
2. **From Bottom Navigation**: Currently not directly accessible

### How to Edit/Delete Transactions
1. Go to **Transaction History** (via Dashboard → Quick Actions → History)
2. **To Edit**: Tap on any transaction
3. **To Delete**: Swipe transaction to the left

### Search & Filter Transactions
In **Transaction History** screen:
- **Search Bar** at top - Search by description
- **Filter Chips** - Quick filter by All/Income/Expense
- **Filter Icon** (top right) - Advanced filters:
  - Date range
  - Amount range
  - Category
  - Combine multiple filters
- **Sort Icon** (top right) - Sort by date or amount

---

## 🔁 Recurring Transactions

### How to Access
1. Go to **Transaction History** (Dashboard → Quick Actions → History)
2. Tap the **Repeat icon** (🔄) in the top-right corner of app bar
3. This opens the **Recurring Transactions Screen**

### How to Add Recurring Transaction
1. In Recurring Transactions screen, tap the **+ button** (bottom right)
2. Fill in:
   - Amount
   - Category
   - Description
   - Frequency (Daily/Weekly/Monthly/Yearly)
   - Start date
   - End date (optional)

---

## 📅 Upcoming Bills & Reminders

### Why You Don't See Them
The **Upcoming Bills Widget** only appears on the dashboard if:
- You have created recurring transactions, OR
- You have upcoming bill reminders set up

### How to Set Up Bills
1. Create a **Recurring Transaction** with future dates
2. The system will automatically show upcoming bills on dashboard
3. Bills appearing in next 30 days will show in the widget

### Bill Reminder Notifications
- System sends notifications 1 day before bill due date
- Notifications are automatically enabled if you have granted permission

---

## 💳 Receipt Scanning

### How to Access
1. Go to **Add Transaction** screen (Dashboard → Quick Actions → Add Transaction)
2. Look for the **Camera icon** or "Scan Receipt" button at the bottom
3. Take photo of receipt
4. System extracts amount, date, and merchant name
5. Review and confirm the transaction

---

## 📊 Reports & Analytics

### Analytics Screen
- Access via Dashboard → Quick Actions → "Analytics"
- View:
  - Spending trends
  - Category breakdown
  - Income vs Expense charts

### Reports Screen
- Access via Dashboard → Quick Actions → "Reports"
- Generate PDF/CSV reports

---

## 📤 Export Features

### Export from Transaction History
1. Go to Transaction History
2. Tap **Download icon** (top right)
3. Transactions exported to CSV
4. File saved to your device
5. Option to share the CSV file

### Export Reports (PDF/CSV)
- Currently exports are saved locally to device
- Look for files in your device's Documents folder
- Use the Share button to send via other apps

**Note**: If you see URL launcher errors, the export has still been created locally. Check your device's file manager in the SmartFinance folder.

---

## 👤 Account Information

### View Your Account
1. Tap **Settings** (bottom navigation or dashboard menu)
2. Your name and email are displayed at the top
3. Tap on your profile section for more details

### Account Details Available
- Full name
- Email address
- Phone number (if provided)
- Member since date
- Account verification status

---

## 🔒 Security Settings

### Access Security Settings
1. Go to **Settings** screen
2. Tap **"Security & Privacy"** option
3. Here you can:
   - Change password
   - Enable/Disable Two-Factor Authentication
   - View active sessions
   - View security activity log
   - Verify email

### Change Password
1. In Security Settings, tap **"Change Password"**
2. Enter:
   - Current password
   - New password (must meet requirements):
     - At least 8 characters
     - One uppercase letter
     - One lowercase letter
     - One symbol (!@#$%^&*())
   - Confirm new password

---

## 🎨 Theme Settings

### Current Theme Status
- **Light Mode** is the only active theme
- **Dark Mode** has been temporarily disabled due to text visibility issues
- Will be improved in future update

### How to Access Theme Settings
1. Go to **Settings**
2. Tap **"Theme"**
3. You'll see a message explaining Light mode is currently active

---

## 🔔 Notifications

### Types of Notifications
1. **Budget Alerts** - When spending exceeds 80% of budget
2. **Bill Reminders** - 1 day before recurring transaction due
3. **Achievement Unlocked** - When you unlock new achievements
4. **Category Over Budget** - When specific category exceeds limit

### Enable Notifications
- System prompts for permission on first launch
- Go to device Settings → Apps → SmartFinance → Notifications to manage

---

## 📱 Bottom Navigation

Currently, the app uses:
- **Dashboard** as the main screen
- **Quick Actions** on dashboard to access all features
- Bottom navigation may be simplified in future updates

---

## 🆘 Common Questions

### "I can't find the Transaction Screen at the bottom"
- Transactions are accessed via Dashboard → Quick Actions → "Add Transaction" or "History"
- The floating + button in History screen also adds transactions

### "Where is my Upcoming Bills widget?"
- It only appears if you have:
  - Created recurring transactions with future dates, OR
  - Upcoming bills in the next 30 days
- Try creating a recurring expense to see it appear

### "How do I see my registered account details?"
- Go to Settings screen
- Your profile info is displayed at the top
- Or tap the profile section for full details

### "Export is not working" (URL launcher errors)
- The files ARE being created successfully
- They're saved locally to your device
- Check Documents/SmartFinance folder
- Use the Share button to send files

### "Dark mode text is invisible"
- Dark mode has been disabled
- App now only uses Light mode
- This will be improved in a future update

---

## 📝 Feature Checklist

Use this checklist to ensure you've explored all features:

- [ ] Created an account and logged in
- [ ] Added income transaction
- [ ] Added expense transaction
- [ ] Scanned a receipt
- [ ] Created a budget
- [ ] Set up recurring transaction
- [ ] Viewed transaction history
- [ ] Filtered and searched transactions
- [ ] Checked analytics charts
- [ ] Viewed reports
- [ ] Created a financial goal
- [ ] Enabled two-factor authentication
- [ ] Changed password
- [ ] Exported transactions to CSV
- [ ] Verified email address

---

## 🐛 Known Issues (Fixed in This Version)

✅ **Fixed Issues:**
1. Email field validation - Now correctly required
2. Password requirements - Show red/green indicators
3. Transaction filter overflow - Fixed layout
4. Dark mode - Disabled (Light mode only)
5. Change password validation - Now matches registration requirements

---

## 💡 Tips for Best Experience

1. **Set up recurring transactions** for bills to see the Upcoming Bills widget
2. **Use Quick Actions** on dashboard - fastest way to access features
3. **Enable notifications** to get budget alerts and reminders
4. **Regular exports** - Export your data monthly for records
5. **Budget setup** - Create budgets to see progress tracking on dashboard

---

**Last Updated**: January 11, 2026
**Version**: 1.0.0

For bugs or feature requests, please check the GitHub issues page.

# SmartFinance - Testing Guide & Solutions

## 🔑 Account Management Solution

### Issue: "Where to see all registered accounts to delete duplicates?"

**Quick Solution**: Use unique email addresses for each test

**Recommended Testing Emails**:
```
test1@example.com
test2@example.com
test3@example.com
test4@example.com
test5@example.com
```

### How to View Current Account
1. Login to the app
2. Go to **Settings** (bottom navigation or menu)
3. Your account info is displayed at the top:
   - Full name
   - Email address
   - Phone number
   - Member since date

### Backend Database Access (For Deleting Test Accounts)

**Option 1: Direct Database Access**
```sql
-- View all users
SELECT user_id, email, full_name, created_at FROM Users;

-- Delete specific test account
DELETE FROM Users WHERE email = 'test1@example.com';
```

**Option 2: Backend API (If available)**
```bash
# List users (requires admin endpoint)
curl http://localhost:5000/api/admin/users

# Delete user
curl -X DELETE http://localhost:5000/api/admin/users/{user_id}
```

**Option 3: Keep Track Manually**
Create a file `test_accounts.txt`:
```
Test 1: test1@example.com - Password123!
Test 2: test2@example.com - Password123!
Test 3: test3@example.com - Password123!
```

---

## 🔄 Recurring Transaction Testing Guide

### Issue: "No field to enter name and amount, shows no name and RM0"

**Solution**: The fields ARE there! You need to scroll down.

### Step-by-Step Guide:

#### 1. Access Recurring Transactions
- Go to **Transaction History** (Dashboard → Quick Actions → History)
- Tap the **🔄 Repeat icon** in the top-right corner
- Tap the **+ button** (floating action button at bottom right)

#### 2. Fill Out the Form (SCROLL DOWN!)

**The form has these fields in order**:

1. **Transaction Type** (Top)
   - Toggle between Expense/Income

2. **Name** ⬅️ **THIS FIELD EXISTS!**
   - Example: "Monthly Rent"
   - Example: "Weekly Salary"
   - **SCROLL DOWN to see this**

3. **Amount (RM)** ⬅️ **THIS FIELD EXISTS!**
   - Enter amount like 1500 or 5000
   - **SCROLL DOWN to see this**

4. **Category**
   - Select from dropdown

5. **Description** (Optional)
   - Additional notes

6. **Frequency**
   - Daily / Weekly / Monthly / Yearly

7. **Start Date**
   - When to start recurring

8. **End Date** (Optional)
   - Toggle "Has End Date" checkbox

#### 3. Save the Transaction
- Tap **"Create Recurring Transaction"** button at bottom
- **IMPORTANT**: Make sure you scrolled and filled Name and Amount!

---

## 🐛 Common Issues & Solutions

### 1. "Shows no name and RM0"
**Cause**: Name and Amount fields were left empty (probably didn't scroll to see them)
**Solution**:
- Scroll down in the form
- Fill in the Name field (REQUIRED)
- Fill in the Amount field (REQUIRED)
- Both fields have * indicating they're required

### 2. "Cannot execute, cannot pause or resume, cannot delete"
**Cause**: RecurringId is null in the backend response
**Solution**:
- Fixed with null safety checks
- If buttons are still disabled, check backend is returning RecurringId
- Backend should return JSON like:
```json
{
  "RecurringId": 1,
  "Name": "Monthly Rent",
  "Amount": 1500,
  "Frequency": "monthly",
  ...
}
```

### 3. "Upcoming Bills Widget not showing"
**Cause**: No recurring transactions created yet
**Solution**:
- Create at least ONE recurring transaction
- Make sure the start date is within next 30 days
- Widget will appear automatically on dashboard

---

## ✅ Change Password Validation

### Issue: "Still didn't follow the conditions in register one"

**Status**: ✅ FIXED (but you said "not important")

**Current Validation**:
- ✅ Minimum 8 characters
- ✅ At least one uppercase letter (A-Z)
- ✅ At least one lowercase letter (a-z)
- ✅ At least one symbol (!@#$%^&*(),.?":{}|<>)

**Exactly the same as registration!**

**Location**: Settings → Security & Privacy → Change Password

**Test Password Examples**:
- ✅ `Password123!` (Valid)
- ✅ `Test@1234` (Valid)
- ❌ `password123` (Missing uppercase)
- ❌ `PASSWORD123` (Missing lowercase)
- ❌ `Password123` (Missing symbol)
- ❌ `Pass1!` (Too short - less than 8)

---

## 📝 Complete Testing Checklist

### ✅ Registration
- [ ] Email is required
- [ ] Phone is required
- [ ] Password strength indicators show red/green
- [ ] All 4 requirements must be green to submit

### ✅ Transactions
- [ ] Add new income/expense
- [ ] Edit transaction (button shows "Update")
- [ ] Delete transaction (swipe left)
- [ ] Filter transactions (should scroll, no overflow)

### ✅ Recurring Transactions
- [ ] Access via History → 🔄 icon
- [ ] Tap + button to create new
- [ ] **SCROLL DOWN** to see Name field
- [ ] **SCROLL DOWN** to see Amount field
- [ ] Fill ALL required fields (Name, Amount, Category, Frequency)
- [ ] Save successfully
- [ ] View in recurring list
- [ ] Test "Execute Now" button
- [ ] Test "Pause/Resume" button
- [ ] Test "Delete" button

### ✅ Dashboard
- [ ] Financial summary cards visible
- [ ] Quick actions work
- [ ] Upcoming bills widget shows (after creating recurring transaction)

### ✅ Settings
- [ ] View account info (name, email, phone)
- [ ] Change password with full validation
- [ ] Theme shows light mode only message

---

## 🔍 Debugging Recurring Transactions

### If Name/Amount Still Show as Empty:

**Check 1: Did you scroll?**
- The form is long and scrollable
- Name field is below the Transaction Type toggle
- Amount field is below the Name field

**Check 2: Did you fill them in?**
- Both have * indicating required
- Both show error if left empty
- Validator won't let you submit if empty

**Check 3: Backend API Check**
```bash
# Check what the backend received
# Look at backend logs when you create recurring transaction
# Should show: name, amount, frequency, etc.
```

**Check 4: Frontend Debug**
```dart
// In add_recurring_transaction_screen.dart line 125-128
print('Name: ${_nameController.text}');
print('Amount: ${_amountController.text}');
// These should show the values you entered
```

---

## 🎯 Summary

### Account Management
- ✅ Use different emails for each test (test1@, test2@, etc.)
- ✅ View current account in Settings
- ⚠️ Delete accounts via backend database directly

### Recurring Transactions
- ✅ Form HAS Name and Amount fields
- ✅ **YOU MUST SCROLL DOWN** to see them
- ✅ Both fields are REQUIRED
- ✅ Buttons fixed with null safety

### Change Password
- ✅ Validation is correct (8+ chars, uppercase, lowercase, symbol)
- ✅ Exactly matches registration requirements
- ℹ️ You said "not important" so I assume this is acceptable

---

## 📞 Still Having Issues?

### For Recurring Transactions:
1. Take a screenshot of the ENTIRE form (scroll through all of it)
2. Show me what you see
3. Share any error messages

### For Account Management:
1. Access backend database
2. Run: `SELECT * FROM Users;`
3. Delete test accounts: `DELETE FROM Users WHERE email LIKE 'test%';`

### For Other Issues:
1. Clear app data and try fresh install
2. Check backend is running
3. Share specific error messages

---

**Last Updated**: January 11, 2026
**Version**: 1.0.2

Happy Testing! 🚀

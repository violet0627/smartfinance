-- Delete Account Script for SmartFinance
-- Use this to delete test accounts from the database

-- WARNING: This will permanently delete the account and ALL associated data
-- Make sure you have a backup if needed!

-- ============================================
-- DELETE SPECIFIC ACCOUNT
-- ============================================

-- Delete elaina@gmail.com account
DELETE FROM Users WHERE email = 'elaina@gmail.com';

-- Or replace with your specific email:
-- DELETE FROM Users WHERE email = 'your.email@example.com';


-- ============================================
-- VIEW ALL ACCOUNTS (Before Deleting)
-- ============================================

-- See all registered accounts
SELECT user_id, email, full_name, created_at FROM Users ORDER BY created_at DESC;


-- ============================================
-- DELETE MULTIPLE TEST ACCOUNTS
-- ============================================

-- Delete all accounts starting with 'test'
DELETE FROM Users WHERE email LIKE 'test%@%';

-- Delete specific test accounts
DELETE FROM Users WHERE email IN (
    'test1@example.com',
    'test2@example.com',
    'test3@example.com'
);


-- ============================================
-- HOW TO RUN THIS SCRIPT
-- ============================================

/*
METHOD 1: Using SQLite CLI
1. Open terminal/command prompt
2. Navigate to backend folder: cd backend
3. Open database: sqlite3 smartfinance.db
4. Copy and paste specific DELETE command
5. Press Enter
6. Exit: .quit

METHOD 2: Using DB Browser for SQLite
1. Download DB Browser: https://sqlitebrowser.org/
2. Open smartfinance.db file (in backend folder)
3. Go to "Execute SQL" tab
4. Copy and paste DELETE command
5. Click "Execute" (play button)
6. Click "Write Changes" to save

METHOD 3: Python Script
1. Create delete_account.py:
*/

import sqlite3

def delete_account(email):
    conn = sqlite3.connect('backend/smartfinance.db')
    cursor = conn.cursor()

    # Check if account exists
    cursor.execute('SELECT user_id, full_name FROM Users WHERE email = ?', (email,))
    user = cursor.fetchone()

    if user:
        print(f"Found account: {user[1]} (ID: {user[0]})")
        confirm = input("Are you sure you want to delete? (yes/no): ")

        if confirm.lower() == 'yes':
            cursor.execute('DELETE FROM Users WHERE email = ?', (email,))
            conn.commit()
            print(f"✅ Account {email} deleted successfully!")
        else:
            print("❌ Deletion cancelled")
    else:
        print(f"❌ No account found with email: {email}")

    conn.close()

# Usage:
delete_account('elaina@gmail.com')

/*
Save as delete_account.py and run: python delete_account.py
*/


-- ============================================
-- SAFETY TIPS
-- ============================================

-- 1. Always check what you're deleting first:
SELECT * FROM Users WHERE email = 'elaina@gmail.com';

-- 2. Use transactions for safety (can rollback):
BEGIN TRANSACTION;
DELETE FROM Users WHERE email = 'elaina@gmail.com';
-- If you change your mind: ROLLBACK;
-- If it's correct: COMMIT;

-- 3. Create backup before mass deletions:
-- .backup backup.db (in SQLite CLI)


-- ============================================
-- RELATED DATA (Auto-deleted via CASCADE)
-- ============================================

-- When you delete a user, these are automatically deleted:
-- - All transactions
-- - All budgets
-- - All goals
-- - All recurring transactions
-- - All investments
-- - All achievements/gamification data
-- - All sessions
-- - All security logs

-- This is because foreign keys use ON DELETE CASCADE


-- ============================================
-- VIEW REMAINING ACCOUNTS AFTER DELETION
-- ============================================

SELECT
    user_id,
    email,
    full_name,
    phone_number,
    created_at,
    email_verified
FROM Users
ORDER BY created_at DESC;


-- ============================================
-- KEEP ONLY PRODUCTION ACCOUNTS
-- ============================================

-- Delete all test/temporary accounts, keep only real ones
-- (Uncomment and modify as needed)

-- DELETE FROM Users WHERE
--     email LIKE 'test%' OR
--     email LIKE 'temp%' OR
--     email LIKE 'demo%';

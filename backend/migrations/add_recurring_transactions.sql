-- ==============================================================================
-- Migration: add_recurring_transactions.sql
-- ==============================================================================
-- Creates the RecurringTransactions table to support automated scheduled transactions.
--
-- What are recurring transactions?
--   A recurring transaction is a template that automatically generates a new
--   regular transaction on a set schedule — so the user doesn't have to
--   manually log the same transaction every month.
--
-- Examples:
--   - Monthly rent: RM1,200 expense on the 1st of every month
--   - Weekly salary: RM800 income every Friday
--   - Yearly insurance: RM1,200 expense every January 15th
--
-- How it works:
--   1. User creates a recurring transaction with a frequency and start date
--   2. The backend checks NextExecution on each API call
--   3. When NextExecution <= today, a real Transaction row is created and
--      NextExecution is advanced by one period (e.g., +1 month)
--   4. Paused transactions (IsActive = FALSE) are skipped until resumed
--
-- HOW TO RUN:
--   mysql -u your_username -p your_database < add_recurring_transactions.sql
-- ==============================================================================
CREATE TABLE IF NOT EXISTS recurringtransactions (
    RecurringId     INT PRIMARY KEY AUTO_INCREMENT,   -- Unique ID for each recurring template
    UserId          INT NOT NULL,                     -- FK: which user owns this recurring transaction
    Name            VARCHAR(255) NOT NULL,             -- Display name e.g., "Monthly Rent", "Netflix Subscription"
    TransactionType VARCHAR(20) NOT NULL,              -- 'income' or 'expense'
    Category        VARCHAR(50) NOT NULL,              -- Category e.g., "Housing", "Entertainment"
    Amount          DECIMAL(15, 2) NOT NULL,           -- Amount in RM per occurrence
    Description     TEXT,                             -- Optional user notes
    Frequency       VARCHAR(20) NOT NULL,              -- How often it repeats: 'daily', 'weekly', 'monthly', 'yearly'
    StartDate       DATE NOT NULL,                     -- The date of the first occurrence
    EndDate         DATE,                              -- Optional end date (NULL = runs indefinitely)
    LastExecuted    DATE,                              -- The date the most recent transaction was auto-created (NULL = not yet)
    NextExecution   DATE NOT NULL,                     -- The next date a transaction will be auto-created
    IsActive        BOOLEAN DEFAULT TRUE,              -- FALSE = paused (no transactions created until resumed)
    CreatedAt       DATETIME DEFAULT CURRENT_TIMESTAMP,             -- When this recurring template was set up
    UpdatedAt       DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Last time it was edited
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    INDEX idx_user_id (UserId),             -- Index: speeds up "get all recurring transactions for a user"
    INDEX idx_next_execution (NextExecution), -- Index: speeds up the scheduler query "find all due transactions"
    INDEX idx_is_active (IsActive)          -- Index: speeds up filtering for active-only transactions
);

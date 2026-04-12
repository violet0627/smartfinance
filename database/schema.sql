-- ==============================================================================
-- schema.sql - SmartFinance Complete Database Schema
-- ==============================================================================
-- This file creates the full MySQL database for the SmartFinance application.
-- Run this ONCE to set up a fresh database with all required tables.
--
-- HOW TO RUN:
--   Option 1: mysql -u your_username -p < schema.sql
--   Option 2: Open MySQL Workbench, paste this file, and click Execute
--
-- DATABASE ENGINE: InnoDB
--   InnoDB is the standard MySQL storage engine. It supports:
--   - FOREIGN KEY constraints (links between tables are enforced)
--   - ACID transactions (if a multi-step operation fails, changes roll back)
--   Alternative: MyISAM — faster reads but NO foreign key support, so we use InnoDB.
--
-- CHARSET: utf8mb4 COLLATE utf8mb4_unicode_ci
--   utf8mb4 supports ALL Unicode characters including emojis (4-byte UTF-8).
--   Plain 'utf8' in MySQL is actually only 3-byte — it cannot store emojis.
--   utf8mb4_unicode_ci means case-insensitive comparisons using Unicode rules.
--
-- TABLE DEPENDENCY ORDER (must drop child tables before parents due to FK constraints):
--   UserAchievements → Achievements, Users
--   HabitStreaks     → Users
--   Achievements     (no parent)
--   Investments      → Users
--   BudgetCategories → Budgets
--   Budgets          → Users
--   Transactions     → Users
--   Users            (root table — no parent)
-- ==============================================================================

-- Create the database if it does not already exist
CREATE DATABASE IF NOT EXISTS smartfinance;

-- Switch to the smartfinance database for all following statements
USE smartfinance;

-- ==============================================================================
-- DROP TABLES (for clean reinstall)
-- ==============================================================================
-- Tables are dropped in REVERSE dependency order — child tables first.
-- If we dropped Users first, MySQL would throw a foreign key error because
-- UserAchievements, Transactions, etc. still reference it.
-- ==============================================================================
DROP TABLE IF EXISTS UserAchievements;   -- references Users + Achievements
DROP TABLE IF EXISTS HabitStreaks;       -- references Users
DROP TABLE IF EXISTS Achievements;       -- referenced by UserAchievements
DROP TABLE IF EXISTS Investments;        -- references Users
DROP TABLE IF EXISTS BudgetCategories;   -- references Budgets
DROP TABLE IF EXISTS Budgets;            -- references Users
DROP TABLE IF EXISTS Transactions;       -- references Users
DROP TABLE IF EXISTS Users;              -- root table (dropped last)


-- ==============================================================================
-- TABLE: Users
-- ==============================================================================
-- Stores every registered user account.
-- This is the ROOT table — all other tables link back here via UserId.
-- Relationship: One User has many Transactions, Budgets, Investments, Goals, etc.
-- ==============================================================================
CREATE TABLE Users (
    UserId        INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each user (auto-assigned, never reused)
    Email         VARCHAR(255) UNIQUE NOT NULL,    -- Login email — UNIQUE ensures no two accounts share an email
    PasswordHash  VARCHAR(255) NOT NULL,           -- bcrypt hash of the password — NEVER store plain-text passwords
    FullName      VARCHAR(255) NOT NULL,           -- Display name shown in the app
    PhoneNumber   VARCHAR(20),                     -- Optional phone number (nullable — no NOT NULL)
    CreatedAt     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- When the account was registered
    LastLogin     TIMESTAMP NULL,                  -- When the user last logged in (NULL = never logged in yet)
    ExperiencePts INT DEFAULT 0,                   -- Total XP earned through gamification (starts at 0)
    CurrentLevel  INT DEFAULT 1,                   -- Gamification level derived from ExperiencePts (starts at 1)
    INDEX idx_email (Email)                        -- Index on Email speeds up login queries (searched frequently)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- TABLE: Transactions
-- ==============================================================================
-- Stores every financial transaction — income and expenses.
-- This is the most-queried table in the app (used by analytics, reports, budgets).
-- Relationship: Many Transactions belong to ONE User (many-to-one).
-- ==============================================================================
CREATE TABLE Transactions (
    TransactionId   INT AUTO_INCREMENT PRIMARY KEY,         -- Unique ID for each transaction
    Amount          DECIMAL(10, 2) NOT NULL,                -- Transaction amount in RM (10 digits total, 2 decimal places)
                                                            -- e.g., 1234567890.12 is the max; DECIMAL is exact (not float)
    Category        VARCHAR(100) NOT NULL,                  -- Category name e.g., "Food & Dining", "Salary"
    Description     TEXT,                                   -- Optional user note about the transaction (nullable)
    TransactionDate DATE NOT NULL,                          -- The date the transaction happened (not when it was recorded)
    TransactionType ENUM('income', 'expense') NOT NULL,     -- ENUM restricts values to exactly 'income' or 'expense'
    CreatedAt       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- When this record was created in the database
    UserId          INT NOT NULL,                           -- FK: which user this transaction belongs to
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    -- ON DELETE CASCADE: if the user is deleted, all their transactions are automatically deleted too
    INDEX idx_user_date (UserId, TransactionDate),          -- Composite index: speeds up "get user's transactions by date" queries
    INDEX idx_category (Category)                           -- Index on Category: speeds up category-based filtering
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- TABLE: Budgets
-- ==============================================================================
-- Stores a user's monthly spending plan.
-- One user can have at most ONE budget per month (enforced by UNIQUE KEY).
-- Relationship: One Budget has many BudgetCategories (one-to-many).
-- ==============================================================================
CREATE TABLE Budgets (
    BudgetId     INT AUTO_INCREMENT PRIMARY KEY,                             -- Unique ID for each budget
    MonthYear    VARCHAR(7) NOT NULL,                                        -- The month this budget covers: "YYYY-MM" e.g., "2025-01"
    BudgetPeriod VARCHAR(50) NOT NULL,                                       -- Human-readable period e.g., "January 2025"
    TotalBudget  DECIMAL(10, 2) NOT NULL,                                    -- Total RM allocated for the month e.g., 3000.00
    CreatedAt    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                        -- When the budget was created
    UpdatedAt    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Auto-updated whenever the row changes
    UserId       INT NOT NULL,                                                -- FK: which user owns this budget
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    UNIQUE KEY unique_user_month (UserId, MonthYear),  -- Prevents creating two budgets for the same month
    INDEX idx_user_month (UserId, MonthYear)           -- Index: speeds up "get budget for user+month" queries
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- TABLE: BudgetCategories
-- ==============================================================================
-- Stores the per-category spending allocations within a budget.
-- Example: A RM3000 budget might have Food=RM500, Transport=RM300, Bills=RM700, etc.
-- SpentAmount is updated whenever a new expense transaction is added.
-- Relationship: Many BudgetCategories belong to ONE Budget (many-to-one).
-- ==============================================================================
CREATE TABLE BudgetCategories (
    BudgetCategoryId INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each category row
    CategoryName     VARCHAR(100) NOT NULL,            -- Category name e.g., "Food & Dining", "Transport"
    AllocatedAmount  DECIMAL(10, 2) NOT NULL,          -- How much RM was budgeted for this category
    SpentAmount      DECIMAL(10, 2) DEFAULT 0.00,      -- How much has actually been spent (updated by transactions)
    BudgetId         INT NOT NULL,                     -- FK: which budget this category belongs to
    FOREIGN KEY (BudgetId) REFERENCES Budgets(BudgetId) ON DELETE CASCADE,
    -- ON DELETE CASCADE: deleting a budget automatically deletes all its categories
    INDEX idx_budget (BudgetId)                        -- Index: speeds up "get all categories for a budget" queries
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- TABLE: Investments
-- ==============================================================================
-- Stores individual investment holdings in the user's portfolio.
-- Each row = one investment position (e.g., "10 shares of Apple at RM150 each").
-- Profit/loss is calculated at read time: (CurrentPrice - PurchasePrice) * Quantity.
-- Relationship: Many Investments belong to ONE User (many-to-one).
-- ==============================================================================
CREATE TABLE Investments (
    InvestmentId  INT AUTO_INCREMENT PRIMARY KEY,      -- Unique ID for each investment
    AssetName     VARCHAR(255) NOT NULL,               -- Full name e.g., "Apple Inc.", "Bitcoin", "KLCI ETF"
    AssetsType    VARCHAR(100) NOT NULL,               -- Asset class e.g., "Stocks", "Cryptocurrency", "ETF"
    StockSymbol   VARCHAR(20),                         -- Ticker symbol e.g., "AAPL", "BTC" (nullable — not all assets have one)
    Quantity      DECIMAL(15, 4) NOT NULL,             -- Number of units held (4 decimal places for crypto fractions)
    PurchasePrice DECIMAL(10, 2) NOT NULL,             -- Price per unit when purchased (cost basis)
    PurchaseDate  DATE NOT NULL,                       -- Date the investment was made
    CurrentPrice  DECIMAL(10, 2),                      -- Today's market price per unit (nullable — can be empty until updated)
    LastUpdated   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- When CurrentPrice was last changed
    Notes         TEXT,                                -- Optional user notes about this investment
    UserId        INT NOT NULL,                        -- FK: which user owns this investment
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    INDEX idx_user (UserId),                           -- Index: speeds up "get all investments for a user" queries
    INDEX idx_asset_type (AssetsType)                  -- Index: speeds up filtering by asset type (Stocks, Crypto, etc.)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- TABLE: Achievements
-- ==============================================================================
-- Master list of all possible achievements in the gamification system.
-- This table is populated ONCE at setup (see INSERT below) and rarely changes.
-- Think of it as a "catalogue" of achievements — users don't own rows here directly.
-- Relationship: One Achievement can be unlocked by MANY users (via UserAchievements).
-- ==============================================================================
CREATE TABLE Achievements (
    AchievementId   INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each achievement
    Name            VARCHAR(255) NOT NULL,            -- Display name e.g., "Budget Master"
    Description     TEXT,                             -- What the achievement is for e.g., "Stay within budget for a month"
    BadgeIcon       VARCHAR(255),                     -- Icon filename shown in the app e.g., "budget_master.png"
    XpReward        INT DEFAULT 0,                    -- XP added to user when this achievement is unlocked
    UnlockCriteria  TEXT,                             -- Human-readable description of how to unlock it
    DifficultyLevel ENUM('easy', 'medium', 'hard', 'expert') DEFAULT 'easy',  -- Difficulty tier shown in the app
    INDEX idx_difficulty (DifficultyLevel)            -- Index: speeds up filtering achievements by difficulty
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- TABLE: UserAchievements
-- ==============================================================================
-- Junction (link) table connecting Users and Achievements.
-- Tracks which achievements each user has unlocked and their progress towards each one.
-- Example: User #5 has unlocked "Budget Master" (IsUnlocked=TRUE) with Progress=100.
--
-- Why a junction table?
--   One User can unlock MANY Achievements.
--   One Achievement can be unlocked by MANY Users.
--   This is a Many-to-Many relationship — junction tables are the standard solution.
--
-- UNIQUE KEY unique_user_achievement: prevents inserting the same (user, achievement) pair twice.
-- ==============================================================================
CREATE TABLE UserAchievements (
    UserAchievementId INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each row
    IsUnlocked        BOOLEAN DEFAULT FALSE,            -- TRUE once the achievement criteria is met
    Progress          INT DEFAULT 0,                    -- 0-100: how far along the user is (e.g., 60 = 60% done)
    UserId            INT NOT NULL,                     -- FK: which user
    AchievementId     INT NOT NULL,                     -- FK: which achievement
    UnlockedAt        TIMESTAMP NULL,                   -- When it was unlocked (NULL = not yet unlocked)
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (AchievementId) REFERENCES Achievements(AchievementId) ON DELETE CASCADE,
    UNIQUE KEY unique_user_achievement (UserId, AchievementId),  -- One row per user-achievement pair
    INDEX idx_user (UserId)  -- Index: speeds up "get all achievements for a user" queries
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- TABLE: HabitStreaks
-- ==============================================================================
-- Tracks the user's daily activity streaks for gamification.
-- A "streak" is a count of consecutive days the user performed an activity.
-- StreakType distinguishes different tracked activities.
--
-- Streak types used in the app:
--   'daily_login'      — consecutive days the user opened the app
--   'transaction_log'  — consecutive days the user recorded a transaction
--
-- UNIQUE KEY unique_user_streak_type: one streak row per user per streak type.
-- ==============================================================================
CREATE TABLE HabitStreaks (
    StreakId       INT AUTO_INCREMENT PRIMARY KEY,   -- Unique ID for each streak row
    CurrentStreak  INT DEFAULT 0,                    -- Current consecutive days count (resets if broken)
    LongestStreak  INT DEFAULT 0,                    -- All-time personal best streak for this type
    LastActivity   DATE,                             -- The most recent date the activity was performed
    StreakType     VARCHAR(50) NOT NULL,              -- Which streak this row tracks e.g., 'daily_login'
    UserId         INT NOT NULL,                     -- FK: which user
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    UNIQUE KEY unique_user_streak_type (UserId, StreakType),  -- One row per user per streak type
    INDEX idx_user (UserId)  -- Index: speeds up "get all streaks for a user" queries
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==============================================================================
-- SEED DATA: Insert Default Achievements
-- ==============================================================================
-- These 8 achievements are available to ALL users from the start.
-- They cover the main features of SmartFinance — transactions, budgets,
-- investments, and habit streaks — to motivate continued app usage.
-- XP values increase with difficulty: easy=10-30, medium=50-75, hard=100-150, expert=200.
-- ==============================================================================
INSERT INTO Achievements (Name, Description, BadgeIcon, XpReward, UnlockCriteria, DifficultyLevel) VALUES
-- Easy achievements (first-time actions)
('First Step',          'Record your first transaction',       'first_step.png',      10,  'Record 1 transaction',              'easy'),
('Budget Beginner',     'Create your first budget',            'budget_beginner.png', 20,  'Create 1 budget',                   'easy'),
('Investment Initiate', 'Add your first investment',           'investment_start.png', 30, 'Add 1 investment',                  'easy'),
-- Medium achievements (sustained effort)
('Week Warrior',        'Maintain a 7-day tracking streak',    'week_warrior.png',    50,  'Track for 7 consecutive days',      'medium'),
('Expense Expert',      'Record 100 transactions',             'expense_expert.png',  75,  'Record 100 transactions',           'medium'),
-- Hard achievements (significant financial discipline)
('Budget Master',       'Stay within budget for a month',      'budget_master.png',   100, 'Complete a month within budget',    'hard'),
('Savings Star',        'Save 20% of your income',             'savings_star.png',    150, 'Save 20% monthly income',           'hard'),
-- Expert achievement (long-term commitment)
('Habit Hero',          'Maintain a 30-day tracking streak',   'habit_hero.png',      200, 'Track for 30 consecutive days',     'expert');


-- Confirm that setup completed successfully
SELECT 'Database schema created successfully!' AS Status;

-- SmartFinance Database Schema
-- Created for MySQL 8.0+

-- Create database
CREATE DATABASE IF NOT EXISTS smartfinance;
USE smartfinance;

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS UserAchievements;
DROP TABLE IF EXISTS HabitStreaks;
DROP TABLE IF EXISTS Achievements;
DROP TABLE IF EXISTS Investments;
DROP TABLE IF EXISTS BudgetCategories;
DROP TABLE IF EXISTS Budgets;
DROP TABLE IF EXISTS Transactions;
DROP TABLE IF EXISTS Users;

-- Users table
CREATE TABLE Users (
    UserId INT AUTO_INCREMENT PRIMARY KEY,
    Email VARCHAR(255) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    FullName VARCHAR(255) NOT NULL,
    PhoneNumber VARCHAR(20),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    LastLogin TIMESTAMP NULL,
    ExperiencePts INT DEFAULT 0,
    CurrentLevel INT DEFAULT 1,
    INDEX idx_email (Email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Transactions table
CREATE TABLE Transactions (
    TransactionId INT AUTO_INCREMENT PRIMARY KEY,
    Amount DECIMAL(10, 2) NOT NULL,
    Category VARCHAR(100) NOT NULL,
    Description TEXT,
    TransactionDate DATE NOT NULL,
    TransactionType ENUM('income', 'expense') NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UserId INT NOT NULL,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    INDEX idx_user_date (UserId, TransactionDate),
    INDEX idx_category (Category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Budgets table
CREATE TABLE Budgets (
    BudgetId INT AUTO_INCREMENT PRIMARY KEY,
    MonthYear VARCHAR(7) NOT NULL, -- Format: YYYY-MM
    BudgetPeriod VARCHAR(50) NOT NULL,
    TotalBudget DECIMAL(10, 2) NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UserId INT NOT NULL,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    UNIQUE KEY unique_user_month (UserId, MonthYear),
    INDEX idx_user_month (UserId, MonthYear)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- BudgetCategories table
CREATE TABLE BudgetCategories (
    BudgetCategoryId INT AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL,
    AllocatedAmount DECIMAL(10, 2) NOT NULL,
    SpentAmount DECIMAL(10, 2) DEFAULT 0.00,
    BudgetId INT NOT NULL,
    FOREIGN KEY (BudgetId) REFERENCES Budgets(BudgetId) ON DELETE CASCADE,
    INDEX idx_budget (BudgetId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Investments table
CREATE TABLE Investments (
    InvestmentId INT AUTO_INCREMENT PRIMARY KEY,
    AssetName VARCHAR(255) NOT NULL,
    AssetsType VARCHAR(100) NOT NULL,
    StockSymbol VARCHAR(20),
    Quantity DECIMAL(15, 4) NOT NULL,
    PurchasePrice DECIMAL(10, 2) NOT NULL,
    PurchaseDate DATE NOT NULL,
    CurrentPrice DECIMAL(10, 2),
    LastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    Notes TEXT,
    UserId INT NOT NULL,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    INDEX idx_user (UserId),
    INDEX idx_asset_type (AssetsType)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Achievements table
CREATE TABLE Achievements (
    AchievementId INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    BadgeIcon VARCHAR(255),
    XpReward INT DEFAULT 0,
    UnlockCriteria TEXT,
    DifficultyLevel ENUM('easy', 'medium', 'hard', 'expert') DEFAULT 'easy',
    INDEX idx_difficulty (DifficultyLevel)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- UserAchievements table (junction table)
CREATE TABLE UserAchievements (
    UserAchievementId INT AUTO_INCREMENT PRIMARY KEY,
    IsUnlocked BOOLEAN DEFAULT FALSE,
    Progress INT DEFAULT 0,
    UserId INT NOT NULL,
    AchievementId INT NOT NULL,
    UnlockedAt TIMESTAMP NULL,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (AchievementId) REFERENCES Achievements(AchievementId) ON DELETE CASCADE,
    UNIQUE KEY unique_user_achievement (UserId, AchievementId),
    INDEX idx_user (UserId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- HabitStreaks table
CREATE TABLE HabitStreaks (
    StreakId INT AUTO_INCREMENT PRIMARY KEY,
    CurrentStreak INT DEFAULT 0,
    LongestStreak INT DEFAULT 0,
    LastActivity DATE,
    StreakType VARCHAR(50) NOT NULL,
    UserId INT NOT NULL,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    UNIQUE KEY unique_user_streak_type (UserId, StreakType),
    INDEX idx_user (UserId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert sample achievements
INSERT INTO Achievements (Name, Description, BadgeIcon, XpReward, UnlockCriteria, DifficultyLevel) VALUES
('First Step', 'Record your first transaction', 'first_step.png', 10, 'Record 1 transaction', 'easy'),
('Budget Beginner', 'Create your first budget', 'budget_beginner.png', 20, 'Create 1 budget', 'easy'),
('Week Warrior', 'Maintain a 7-day tracking streak', 'week_warrior.png', 50, 'Track for 7 consecutive days', 'medium'),
('Investment Initiate', 'Add your first investment', 'investment_start.png', 30, 'Add 1 investment', 'easy'),
('Budget Master', 'Stay within budget for a month', 'budget_master.png', 100, 'Complete a month within budget', 'hard'),
('Habit Hero', 'Maintain a 30-day streak', 'habit_hero.png', 200, 'Track for 30 consecutive days', 'expert'),
('Savings Star', 'Save 20% of your income', 'savings_star.png', 150, 'Save 20% monthly income', 'hard'),
('Expense Expert', 'Record 100 transactions', 'expense_expert.png', 75, 'Record 100 transactions', 'medium');

-- Display success message
SELECT 'Database schema created successfully!' AS Status;

-- Migration: Add Two-Factor Authentication Support
-- Date: 2026-01-08
-- Description: Adds TwoFactorEnabled to Users table and creates TwoFactorAuths table

-- Step 1: Add TwoFactorEnabled column to Users table
ALTER TABLE Users
ADD COLUMN TwoFactorEnabled BOOLEAN DEFAULT FALSE AFTER EmailVerified;

-- Step 2: Create TwoFactorAuths table
CREATE TABLE IF NOT EXISTS TwoFactorAuths (
    TwoFactorId INT PRIMARY KEY AUTO_INCREMENT,
    UserId INT NOT NULL,
    Secret VARCHAR(500) NOT NULL,
    BackupCodes TEXT,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    LastUsedAt DATETIME,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    INDEX idx_user_id (UserId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Note: Run this migration with:
-- mysql -u your_username -p your_database < add_two_factor_auth.sql

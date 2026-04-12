-- ==============================================================================
-- Migration: add_two_factor_auth.sql
-- Date: 2026-01-08
-- ==============================================================================
-- Adds Two-Factor Authentication (2FA) support to the database.
--
-- Changes made:
--   1. Adds TwoFactorEnabled column to the existing Users table
--   2. Creates a new TwoFactorAuths table to store 2FA secrets and backup codes
--
-- What is 2FA?
--   After logging in with a password, the user must also enter a 6-digit code
--   from an authenticator app (e.g., Google Authenticator). This protects the
--   account even if the password is stolen.
--
-- HOW TO RUN:
--   mysql -u your_username -p your_database < add_two_factor_auth.sql
-- ==============================================================================


-- ==============================================================================
-- STEP 1: Add TwoFactorEnabled flag to Users table
-- ==============================================================================
-- TwoFactorEnabled = FALSE by default (2FA is optional, off until user enables it).
-- Placed AFTER EmailVerified so related security flags are grouped together.
-- ==============================================================================
ALTER TABLE Users
ADD COLUMN TwoFactorEnabled BOOLEAN DEFAULT FALSE AFTER EmailVerified;
-- BOOLEAN: TRUE = 2FA is active for this user, FALSE = 2FA is disabled


-- ==============================================================================
-- STEP 2: Create TwoFactorAuths table
-- ==============================================================================
-- Stores the TOTP secret and backup codes for each user who has enabled 2FA.
-- One user has at most ONE TwoFactorAuth record (one-to-one relationship).
--
-- TOTP (Time-based One-Time Password) flow:
--   1. Server generates a random Secret (base32-encoded string)
--   2. Secret is encoded in a QR code — user scans it with their authenticator app
--   3. App + server both use the same secret + current time to generate a 6-digit code
--   4. User enters the code; server verifies it matches
--
-- Backup codes: 8 one-time-use codes stored as hashed strings (like passwords).
--   Used when the user loses access to their authenticator app.
-- ==============================================================================
CREATE TABLE IF NOT EXISTS TwoFactorAuths (
    TwoFactorId  INT PRIMARY KEY AUTO_INCREMENT,  -- Unique ID for each 2FA record
    UserId       INT NOT NULL,                    -- FK: which user this secret belongs to
    Secret       VARCHAR(500) NOT NULL,           -- TOTP secret key (base32 string, ~32 chars but stored with room to spare)
    BackupCodes  TEXT,                            -- JSON array of hashed backup codes e.g., ["$2b$12$...", "$2b$12$..."]
    CreatedAt    DATETIME DEFAULT CURRENT_TIMESTAMP,  -- When 2FA was set up
    LastUsedAt   DATETIME,                        -- When 2FA was last successfully verified (NULL = never used)
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    -- ON DELETE CASCADE: if the user account is deleted, their 2FA record is deleted too
    INDEX idx_user_id (UserId)                    -- Index: speeds up finding a user's 2FA record by UserId
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

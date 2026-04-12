-- ==============================================================================
-- Migration: email_verification.sql
-- ==============================================================================
-- Adds email verification and password reset support to the database.
--
-- Changes made:
--   1. Adds EmailVerified column to the existing Users table
--   2. Creates EmailVerificationTokens table (for verifying new accounts)
--   3. Creates PasswordResetTokens table (for "Forgot Password" flow)
--
-- Why email verification?
--   Confirms the user actually owns the email they registered with.
--   Unverified users see a banner prompting them to verify before full access.
--
-- Token security model (both tables use the same approach):
--   - A random unique token is generated and emailed to the user
--   - Token has an expiry time (ExpiresAt) — expired tokens are rejected
--   - Token can only be used once (Used = TRUE after first use)
--   - Tokens are stored in full (not hashed) because they must be looked up by value
--
-- HOW TO RUN:
--   mysql -u your_username -p your_database < email_verification.sql
-- ==============================================================================


-- ==============================================================================
-- STEP 1: Add EmailVerified flag to Users table
-- ==============================================================================
-- EmailVerified = FALSE by default (all new registrations start unverified).
-- The app checks this flag to decide whether to show the verification banner.
-- ==============================================================================
ALTER TABLE Users
ADD COLUMN EmailVerified BOOLEAN DEFAULT FALSE AFTER Email;
-- BOOLEAN: TRUE = user has verified their email, FALSE = not yet verified


-- ==============================================================================
-- STEP 2: Create EmailVerificationTokens table
-- ==============================================================================
-- Stores one-time tokens sent to users to verify their email address.
-- Flow: Register → receive email → click link/enter token → EmailVerified = TRUE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS EmailVerificationTokens (
    TokenId   INT PRIMARY KEY AUTO_INCREMENT,           -- Unique ID for each token record
    UserId    INT NOT NULL,                             -- FK: which user this token was issued to
    Token     VARCHAR(500) NOT NULL,                    -- The actual token string (random, URL-safe)
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,       -- When the token was issued
    ExpiresAt DATETIME NOT NULL,                        -- After this time, the token is rejected (typically 24 hours)
    Used      BOOLEAN DEFAULT FALSE,                    -- TRUE = already used (prevents reuse of the same token)
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    -- ON DELETE CASCADE: if the user is deleted, their tokens are deleted too
    INDEX idx_token (Token(255)),   -- Index on first 255 chars of Token — speeds up token lookup queries
    INDEX idx_user_id (UserId)      -- Index: speeds up "get tokens for a user" queries
);


-- ==============================================================================
-- STEP 3: Create PasswordResetTokens table
-- ==============================================================================
-- Stores one-time tokens sent to users when they request a password reset.
-- Flow: "Forgot Password" → enter email → receive token → enter token + new password → reset
-- Same structure as EmailVerificationTokens — same security model applies.
-- ==============================================================================
CREATE TABLE IF NOT EXISTS PasswordResetTokens (
    TokenId   INT PRIMARY KEY AUTO_INCREMENT,           -- Unique ID for each token record
    UserId    INT NOT NULL,                             -- FK: which user requested the reset
    Token     VARCHAR(500) NOT NULL,                    -- The reset token string (random, URL-safe)
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,       -- When the reset was requested
    ExpiresAt DATETIME NOT NULL,                        -- Token expires after this time (typically 1 hour)
    Used      BOOLEAN DEFAULT FALSE,                    -- TRUE = token already consumed (prevents reuse)
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    INDEX idx_token (Token(255)),   -- Index on Token: speeds up token lookup at reset time
    INDEX idx_user_id (UserId)      -- Index: speeds up checking if user already has a pending reset
);

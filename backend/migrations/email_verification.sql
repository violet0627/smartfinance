-- Email Verification Migration
-- Adds email verification support to SmartFinance

-- Add EmailVerified column to Users table
ALTER TABLE Users
ADD COLUMN EmailVerified BOOLEAN DEFAULT FALSE AFTER Email;

-- Create EmailVerificationTokens table
CREATE TABLE IF NOT EXISTS EmailVerificationTokens (
    TokenId INT PRIMARY KEY AUTO_INCREMENT,
    UserId INT NOT NULL,
    Token VARCHAR(500) NOT NULL,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    ExpiresAt DATETIME NOT NULL,
    Used BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    INDEX idx_token (Token(255)),
    INDEX idx_user_id (UserId)
);

-- Create PasswordResetTokens table
CREATE TABLE IF NOT EXISTS PasswordResetTokens (
    TokenId INT PRIMARY KEY AUTO_INCREMENT,
    UserId INT NOT NULL,
    Token VARCHAR(500) NOT NULL,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    ExpiresAt DATETIME NOT NULL,
    Used BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    INDEX idx_token (Token(255)),
    INDEX idx_user_id (UserId)
);

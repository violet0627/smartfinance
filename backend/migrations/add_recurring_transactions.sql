-- Recurring Transactions Migration
-- Adds support for automated recurring transactions

CREATE TABLE IF NOT EXISTS recurringtransactions (
    RecurringId INT PRIMARY KEY AUTO_INCREMENT,
    UserId INT NOT NULL,
    Name VARCHAR(255) NOT NULL,
    TransactionType VARCHAR(20) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    Amount DECIMAL(15, 2) NOT NULL,
    Description TEXT,
    Frequency VARCHAR(20) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE,
    LastExecuted DATE,
    NextExecution DATE NOT NULL,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    INDEX idx_user_id (UserId),
    INDEX idx_next_execution (NextExecution),
    INDEX idx_is_active (IsActive)
);

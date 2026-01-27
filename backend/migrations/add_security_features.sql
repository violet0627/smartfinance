-- Security Features Migration
-- Adds session tracking and security activity logging

-- Create UserSessions table
CREATE TABLE IF NOT EXISTS usersessions (
    SessionId INT PRIMARY KEY AUTO_INCREMENT,
    UserId INT NOT NULL,
    DeviceName VARCHAR(255),
    DeviceType VARCHAR(50),
    IpAddress VARCHAR(45),
    UserAgent TEXT,
    LoginAt DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    LastActiveAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    IsActive BOOLEAN DEFAULT TRUE,
    RefreshToken VARCHAR(500),
    ExpiresAt DATETIME,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    INDEX idx_user_id (UserId),
    INDEX idx_is_active (IsActive)
);

-- Create SecurityLogs table
CREATE TABLE IF NOT EXISTS securitylogs (
    LogId INT PRIMARY KEY AUTO_INCREMENT,
    UserId INT NOT NULL,
    EventType VARCHAR(100) NOT NULL,
    EventDescription TEXT,
    IpAddress VARCHAR(45),
    DeviceInfo VARCHAR(255),
    Success BOOLEAN DEFAULT TRUE,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    INDEX idx_user_id (UserId),
    INDEX idx_event_type (EventType),
    INDEX idx_created_at (CreatedAt)
);

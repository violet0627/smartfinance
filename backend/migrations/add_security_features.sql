-- ==============================================================================
-- Migration: add_security_features.sql
-- ==============================================================================
-- Adds session tracking and security activity logging to the database.
--
-- Changes made:
--   1. Creates UserSessions table (tracks active login sessions per device)
--   2. Creates SecurityLogs table (audit trail of security-related events)
--
-- HOW TO RUN:
--   mysql -u your_username -p your_database < add_security_features.sql
-- ==============================================================================


-- ==============================================================================
-- TABLE: UserSessions
-- ==============================================================================
-- Tracks every active login session — one row per device the user is logged into.
-- This powers the "Active Sessions" feature in Security Settings, where users can:
--   - See all devices currently logged in ("Samsung Galaxy S24, logged in 2 hours ago")
--   - Remotely log out a specific device
--   - Log out all other devices at once
--
-- JWT refresh tokens are stored here, linked to a specific session.
-- When a session is revoked (IsActive = FALSE), its refresh token becomes invalid.
-- ==============================================================================
CREATE TABLE IF NOT EXISTS usersessions (
    SessionId      INT PRIMARY KEY AUTO_INCREMENT,   -- Unique ID for each session
    UserId         INT NOT NULL,                     -- FK: which user is logged in
    DeviceName     VARCHAR(255),                     -- Human-readable device name e.g., "Samsung Galaxy S24"
    DeviceType     VARCHAR(50),                      -- Device category: 'mobile', 'tablet', 'desktop'
    IpAddress      VARCHAR(45),                      -- IP address at login time (45 chars supports IPv6)
    UserAgent      TEXT,                             -- Full browser/app user-agent string (for device fingerprinting)
    LoginAt        DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,  -- When this session was created (login time)
    LastActiveAt   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Auto-updated on each API call
    IsActive       BOOLEAN DEFAULT TRUE,             -- FALSE = session was revoked (logged out remotely)
    RefreshToken   VARCHAR(500),                     -- JWT refresh token for this session (used to get new access tokens)
    ExpiresAt      DATETIME,                         -- When this session/refresh token expires (30 days from login)
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    INDEX idx_user_id (UserId),        -- Index: speeds up "get all sessions for a user" queries
    INDEX idx_is_active (IsActive)     -- Index: speeds up "get all active sessions" queries
);


-- ==============================================================================
-- TABLE: SecurityLogs
-- ==============================================================================
-- Audit trail recording all security-relevant events on user accounts.
-- This powers the "Recent Activity" section in Security Settings.
-- Helps users spot unauthorized access (e.g., unexpected logins from unknown IPs).
--
-- Event types logged:
--   'login'              — successful login
--   'login_failed'       — failed login attempt (wrong password)
--   'password_change'    — user changed their password
--   '2fa_enabled'        — user turned on two-factor authentication
--   '2fa_disabled'       — user turned off two-factor authentication
--   'session_terminated' — user logged out another device remotely
--   'account_updated'    — profile details were changed
-- ==============================================================================
CREATE TABLE IF NOT EXISTS securitylogs (
    LogId            INT PRIMARY KEY AUTO_INCREMENT,  -- Unique ID for each log entry
    UserId           INT NOT NULL,                    -- FK: which user's account this event relates to
    EventType        VARCHAR(100) NOT NULL,           -- Category of the event (see event types above)
    EventDescription TEXT,                            -- Human-readable description e.g., "Login from new device"
    IpAddress        VARCHAR(45),                     -- IP address where the event originated
    DeviceInfo       VARCHAR(255),                    -- Device description at the time of the event
    Success          BOOLEAN DEFAULT TRUE,            -- TRUE = event succeeded, FALSE = it failed (e.g., wrong password)
    CreatedAt        DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,  -- Exact timestamp of the event
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    INDEX idx_user_id (UserId),          -- Index: speeds up "get security history for a user" queries
    INDEX idx_event_type (EventType),    -- Index: speeds up filtering by event type
    INDEX idx_created_at (CreatedAt)     -- Index: speeds up sorting/filtering by time
);

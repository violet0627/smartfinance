-- ==============================================================================
-- create_goals_table.sql - Create the Goals Table
-- ==============================================================================
-- Run this script if you get the error:
--   "Table 'smartfinance.goals' doesn't exist"
--
-- This was added as a separate migration because the Goals feature was
-- implemented after the initial schema.sql was written.
--
-- HOW TO RUN:
--   Option 1: mysql -u your_username -p smartfinance < create_goals_table.sql
--   Option 2: Open MySQL Workbench, paste this file, and click Execute
-- ==============================================================================

-- Make sure we are working in the right database
USE smartfinance;

-- ==============================================================================
-- TABLE: Goals
-- ==============================================================================
-- Stores financial savings goals for each user.
-- A goal is a target the user wants to save toward (e.g., emergency fund, car).
--
-- Progress tracking:
--   CurrentAmount starts at 0 and increases as the user adds contributions.
--   When CurrentAmount >= TargetAmount, Status is set to 'completed'.
--
-- Priority levels:
--   'low'    — nice-to-have (e.g., "New headphones")
--   'medium' — important but not urgent (e.g., "Vacation")
--   'high'   — critical financial goal (e.g., "Emergency fund", "House down payment")
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `Goals` (
    `GoalId`        INT NOT NULL AUTO_INCREMENT,     -- Unique ID for each goal
    `UserId`        INT NOT NULL,                    -- FK: which user owns this goal
    `GoalName`      VARCHAR(100) NOT NULL,           -- Display name e.g., "Emergency Fund", "Japan Trip"
    `Description`   TEXT NULL,                       -- Optional details about the goal (nullable)
    `TargetAmount`  DECIMAL(15,2) NOT NULL,          -- How much RM the user wants to save e.g., 10000.00
    `CurrentAmount` DECIMAL(15,2) DEFAULT 0.00,      -- How much has been saved so far (updated on each contribution)
    `StartDate`     DATE NOT NULL DEFAULT (CURRENT_DATE),  -- When the user started working toward this goal
    `Deadline`      DATE NOT NULL,                   -- Target completion date
    `Status`        ENUM('active', 'completed', 'abandoned') DEFAULT 'active',
    -- 'active'    = goal is in progress
    -- 'completed' = CurrentAmount >= TargetAmount
    -- 'abandoned' = user gave up on the goal (manually set)
    `Category`      VARCHAR(50) NULL,                -- Goal category e.g., "Emergency Fund", "Travel", "Education"
    `Priority`      ENUM('low', 'medium', 'high') DEFAULT 'medium',  -- How important this goal is to the user
    `CreatedAt`     DATETIME DEFAULT CURRENT_TIMESTAMP,              -- When the goal was created
    `UpdatedAt`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Last modified time
    PRIMARY KEY (`GoalId`),
    CONSTRAINT `fk_goals_user` FOREIGN KEY (`UserId`) REFERENCES `Users` (`UserId`) ON DELETE CASCADE,
    -- ON DELETE CASCADE: if the user is deleted, all their goals are deleted too
    INDEX `idx_user_goals` (`UserId`),   -- Index: speeds up "get all goals for a user" queries
    INDEX `idx_goal_status` (`Status`)   -- Index: speeds up filtering by status (active/completed/abandoned)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Verify the table was created successfully
SELECT 'Goals table created successfully!' AS message;
SHOW TABLES LIKE 'Goals';    -- Should show 'Goals' in the results
DESCRIBE Goals;              -- Shows all column definitions to confirm structure

-- Create Goals Table
-- Run this in MySQL Workbench to fix the "Table 'smartfinance.goals' doesn't exist" error

USE smartfinance;

CREATE TABLE IF NOT EXISTS `Goals` (
  `GoalId` INT NOT NULL AUTO_INCREMENT,
  `UserId` INT NOT NULL,
  `GoalName` VARCHAR(100) NOT NULL,
  `Description` TEXT NULL,
  `TargetAmount` DECIMAL(15,2) NOT NULL,
  `CurrentAmount` DECIMAL(15,2) DEFAULT 0.00,
  `StartDate` DATE NOT NULL DEFAULT (CURRENT_DATE),
  `Deadline` DATE NOT NULL,
  `Status` ENUM('active', 'completed', 'abandoned') DEFAULT 'active',
  `Category` VARCHAR(50) NULL,
  `Priority` ENUM('low', 'medium', 'high') DEFAULT 'medium',
  `CreatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `UpdatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`GoalId`),
  CONSTRAINT `fk_goals_user` FOREIGN KEY (`UserId`) REFERENCES `Users` (`UserId`) ON DELETE CASCADE,
  INDEX `idx_user_goals` (`UserId`),
  INDEX `idx_goal_status` (`Status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Verify table was created
SELECT 'Goals table created successfully!' AS message;
SHOW TABLES LIKE 'Goals';
DESCRIBE Goals;

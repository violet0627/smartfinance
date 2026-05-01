-- seed_achievements.sql
-- Inserts the default achievement definitions.
-- Run AFTER db.create_all() has created the Achievements table.
-- Safe to run multiple times because INSERT IGNORE skips duplicates.

USE smartfinance;

INSERT IGNORE INTO Achievements (Name, Description, BadgeIcon, XpReward, UnlockCriteria, DifficultyLevel) VALUES
('First Step',          'Record your first transaction',       'first_step.png',       10,  'Record 1 transaction',              'easy'),
('Budget Beginner',     'Create your first budget',            'budget_beginner.png',  20,  'Create 1 budget',                   'easy'),
('Investment Initiate', 'Add your first investment',           'investment_start.png', 30,  'Add 1 investment',                  'easy'),
('Week Warrior',        'Maintain a 7-day tracking streak',    'week_warrior.png',     50,  'Track for 7 consecutive days',      'medium'),
('Expense Expert',      'Record 100 transactions',             'expense_expert.png',   75,  'Record 100 transactions',           'medium'),
('Budget Master',       'Stay within budget for a month',      'budget_master.png',    100, 'Complete a month within budget',    'hard'),
('Savings Star',        'Save 20% of your income',             'savings_star.png',     150, 'Save 20% monthly income',           'hard'),
('Habit Hero',          'Maintain a 30-day tracking streak',   'habit_hero.png',       200, 'Track for 30 consecutive days',     'expert');

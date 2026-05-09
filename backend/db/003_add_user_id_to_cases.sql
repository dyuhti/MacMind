-- Add user_id column and foreign key to cases table
-- This migration adds user association to support user-based data isolation

-- Add the user_id column to the cases table
ALTER TABLE cases ADD COLUMN user_id INTEGER;

-- Add the foreign key constraint
ALTER TABLE cases 
ADD CONSTRAINT fk_cases_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Create index for faster queries by user
CREATE INDEX idx_cases_user_id ON cases(user_id);

-- Update the column to be NOT NULL after data is properly associated
-- Note: If there are existing cases, you may need to associate them with a specific user first
-- For now, we'll set them to user_id = 1 (the first user) if they don't have an assignment
UPDATE cases SET user_id = 1 WHERE user_id IS NULL;
ALTER TABLE cases MODIFY COLUMN user_id INTEGER NOT NULL;

-- Add user_id columns to oxygen tables for user-based data isolation
-- This migration adds user ownership to oxygen calculations and timer history

ALTER TABLE oxygen_calculations ADD COLUMN user_id INTEGER;
ALTER TABLE oxygen_timer_history ADD COLUMN user_id INTEGER;

ALTER TABLE oxygen_calculations
ADD CONSTRAINT fk_oxygen_calculations_user_id
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE oxygen_timer_history
ADD CONSTRAINT fk_oxygen_timer_history_user_id
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

CREATE INDEX idx_oxygen_calculations_user_id ON oxygen_calculations(user_id);
CREATE INDEX idx_oxygen_timer_history_user_id ON oxygen_timer_history(user_id);

-- After backfilling existing rows, you can enforce NOT NULL if desired.

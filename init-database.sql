-- Initialize batch codes database
PRAGMA foreign_keys = ON;

-- Table to store generated batch codes
CREATE TABLE IF NOT EXISTS batch_codes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code VARCHAR(10) NOT NULL UNIQUE,
  monday_item_id VARCHAR(50) NOT NULL,
  monday_board_id VARCHAR(50) NOT NULL,
  item_name TEXT,
  generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_code ON batch_codes(code);
CREATE INDEX IF NOT EXISTS idx_monday_item ON batch_codes(monday_item_id);
CREATE INDEX IF NOT EXISTS idx_generated_at ON batch_codes(generated_at);

-- Table to track webhook processing
CREATE TABLE IF NOT EXISTS webhook_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_type VARCHAR(50),
  monday_item_id VARCHAR(50),
  payload TEXT,
  status VARCHAR(20),
  error_message TEXT,
  processing_time_ms INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_webhook_status ON webhook_logs(status);
CREATE INDEX IF NOT EXISTS idx_webhook_created ON webhook_logs(created_at);

-- Insert initial test data
INSERT OR IGNORE INTO batch_codes (code, monday_item_id, monday_board_id, item_name) 
VALUES ('TEST1', 'test-item-1', 'test-board-1', 'Test Item');

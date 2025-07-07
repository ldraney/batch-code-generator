import sqlite3 from 'sqlite3';
import { promisify } from 'util';
import path from 'path';

export interface BatchCode {
  id?: number;
  code: string;
  monday_item_id: string;
  monday_board_id: string;
  item_name?: string;
  generated_at?: Date;
  updated_at?: Date;
}

export interface WebhookLog {
  id?: number;
  event_type: string;
  monday_item_id?: string;
  payload: string;
  status: 'success' | 'error' | 'skipped';
  error_message?: string;
  processing_time_ms: number;
  created_at?: Date;
}

export class BatchCodeDatabase {
  private db: sqlite3.Database;
  private dbPath: string;

  constructor(dbPath?: string) {
    this.dbPath = dbPath || process.env.DATABASE_PATH || 'data/batch_codes.db';
    this.db = new sqlite3.Database(this.dbPath);
  }

  /**
   * Initialize database with required tables
   */
  async initialize(): Promise<void> {
    const runAsync = promisify(this.db.run.bind(this.db));

    await runAsync(`
      CREATE TABLE IF NOT EXISTS batch_codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code VARCHAR(10) NOT NULL UNIQUE,
        monday_item_id VARCHAR(50) NOT NULL,
        monday_board_id VARCHAR(50) NOT NULL,
        item_name TEXT,
        generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await runAsync(`CREATE INDEX IF NOT EXISTS idx_code ON batch_codes(code)`);
    await runAsync(`CREATE INDEX IF NOT EXISTS idx_monday_item ON batch_codes(monday_item_id)`);

    await runAsync(`
      CREATE TABLE IF NOT EXISTS webhook_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type VARCHAR(50),
        monday_item_id VARCHAR(50),
        payload TEXT,
        status VARCHAR(20),
        error_message TEXT,
        processing_time_ms INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await runAsync(`CREATE INDEX IF NOT EXISTS idx_webhook_status ON webhook_logs(status)`);
  }

  /**
   * Save a generated batch code
   */
  async saveBatchCode(batchCode: BatchCode): Promise<number> {
    const runAsync = promisify(this.db.run.bind(this.db));
    
    const result = await runAsync(
      `INSERT INTO batch_codes (code, monday_item_id, monday_board_id, item_name) 
       VALUES (?, ?, ?, ?)`,
      [batchCode.code, batchCode.monday_item_id, batchCode.monday_board_id, batchCode.item_name]
    );

    return (result as any).lastID;
  }

  /**
   * Check if a batch code already exists
   */
  async batchCodeExists(code: string): Promise<boolean> {
    const getAsync = promisify(this.db.get.bind(this.db));
    
    const result = await getAsync(
      'SELECT 1 FROM batch_codes WHERE code = ? LIMIT 1',
      [code]
    );

    return !!result;
  }

  /**
   * Check if an item already has a batch code
   */
  async getItemBatchCode(mondayItemId: string): Promise<string | null> {
    const getAsync = promisify(this.db.get.bind(this.db));
    
    const result = await getAsync(
      'SELECT code FROM batch_codes WHERE monday_item_id = ? LIMIT 1',
      [mondayItemId]
    ) as { code: string } | undefined;

    return result?.code || null;
  }

  /**
   * Log webhook processing
   */
  async logWebhook(log: WebhookLog): Promise<number> {
    const runAsync = promisify(this.db.run.bind(this.db));
    
    const result = await runAsync(
      `INSERT INTO webhook_logs (event_type, monday_item_id, payload, status, error_message, processing_time_ms) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [log.event_type, log.monday_item_id, log.payload, log.status, log.error_message, log.processing_time_ms]
    );

    return (result as any).lastID;
  }

  /**
   * Get batch code statistics
   */
  async getStats(): Promise<any> {
    const getAsync = promisify(this.db.get.bind(this.db));
    
    const totalCodes = await getAsync('SELECT COUNT(*) as count FROM batch_codes') as { count: number };
    const recentCodes = await getAsync(
      `SELECT COUNT(*) as count FROM batch_codes 
       WHERE generated_at >= datetime('now', '-24 hours')`
    ) as { count: number };
    
    const successfulWebhooks = await getAsync(
      `SELECT COUNT(*) as count FROM webhook_logs 
       WHERE status = 'success' AND created_at >= datetime('now', '-24 hours')`
    ) as { count: number };

    return {
      totalCodes: totalCodes.count,
      codesLast24h: recentCodes.count,
      successfulWebhooksLast24h: successfulWebhooks.count
    };
  }

  /**
   * Close database connection
   */
  async close(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.db.close((err) => {
        if (err) reject(err);
        else resolve();
      });
    });
  }
}

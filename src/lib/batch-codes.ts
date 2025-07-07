import { BatchCodeDatabase } from './database';

const BATCH_CODE_LENGTH = 5;
const CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
const MAX_RETRIES = 10;

// Database instance
let db: BatchCodeDatabase | null = null;

async function getDatabase(): Promise<BatchCodeDatabase> {
  if (!db) {
    db = new BatchCodeDatabase();
    await db.initialize();
  }
  return db;
}

/**
 * Generates a unique 5-character batch code like "TP6YM"
 */
export async function generateUniqueBatchCode(): Promise<string> {
  const database = await getDatabase();
  let attempts = 0;
  
  while (attempts < MAX_RETRIES) {
    const code = Array.from({ length: BATCH_CODE_LENGTH }, () => 
      CHARACTERS.charAt(Math.floor(Math.random() * CHARACTERS.length))
    ).join('');
    
    const exists = await database.batchCodeExists(code);
    if (!exists) {
      return code;
    }
    
    attempts++;
  }
  
  // Fallback with timestamp if all random attempts fail
  const timestamp = Date.now().toString(36).toUpperCase().slice(-3);
  const random = Math.random().toString(36).toUpperCase().slice(-2);
  return `${timestamp}${random}`.padEnd(BATCH_CODE_LENGTH, '0');
}

/**
 * Save batch code to database
 */
export async function saveBatchCode(
  code: string,
  mondayItemId: string,
  mondayBoardId: string,
  itemName?: string
): Promise<void> {
  const database = await getDatabase();
  await database.saveBatchCode({
    code,
    monday_item_id: mondayItemId,
    monday_board_id: mondayBoardId,
    item_name: itemName
  });
}

/**
 * Check if Monday.com item already has a batch code
 */
export async function getExistingBatchCode(mondayItemId: string): Promise<string | null> {
  const database = await getDatabase();
  return await database.getItemBatchCode(mondayItemId);
}

/**
 * Get batch code generation statistics
 */
export async function getBatchCodeStats() {
  const database = await getDatabase();
  return await database.getStats();
}

import { generateUniqueBatchCode, saveBatchCode, getExistingBatchCode } from './batch-codes';
import { MondayClient, MondayWebhookPayload, normalizeMondayWebhook } from './monday';
import { BatchCodeDatabase } from './database';

// Import metrics with error handling
let recordCodeGeneration: any, recordError: any;
try {
  const metrics = require('@/lib/metrics');
  recordCodeGeneration = metrics.recordCodeGeneration;
  recordError = metrics.recordError;
} catch (error) {
  console.warn('Metrics module not available:', error);
  recordCodeGeneration = () => {};
  recordError = () => {};
}

// Import Sentry with error handling
let captureWebhookError: any;
try {
  const sentry = require('@/lib/sentry');
  captureWebhookError = sentry.captureWebhookError;
} catch (error) {
  console.warn('Sentry module not available:', error);
  captureWebhookError = (error: Error, context: any) => {
    console.error('Webhook error:', error, context);
  };
}

export class BatchCodeProcessor {
  private mondayClient: MondayClient;
  private batchCodeColumnId: string;
  private database: BatchCodeDatabase;

  constructor(mondayApiKey: string, batchCodeColumnId: string) {
    this.mondayClient = new MondayClient(mondayApiKey);
    this.batchCodeColumnId = batchCodeColumnId;
    this.database = new BatchCodeDatabase();
  }

  async initialize(): Promise<void> {
    await this.database.initialize();
  }

  /**
   * Process Monday.com webhook and generate batch code
   */
async processWebhook(payload: MondayWebhookPayload): Promise<any> {
    const startTime = Date.now();

    try {
        if (payload.challenge) {
            console.log('🔐 Webhook challenge received:', payload.challenge);
            return { challenge: payload.challenge };
        }

        if (!payload.event) {
            throw new Error('No event data in webhook payload');
        }

        const normalizedEvent = normalizeMondayWebhook(payload);

        if (!normalizedEvent) {
            console.log(`⏭️ Skipping unsupported event type: ${payload.event.type}`);
            return { message: 'Event type not supported', type: payload.event.type };
        }

        if (normalizedEvent.type !== 'create_item') {
            console.log(`⏭️ Skipping event type: ${normalizedEvent.type}`);
            return { message: 'Event type not processed', type: normalizedEvent.type };
        }

        const { item_id, item_name, board_id } = normalizedEvent.data;
        console.log(`🎯 Processing new item: ${item_name} (ID: ${item_id})`);

        // Always generate a new code
        const batchCode = await generateUniqueBatchCode();
        console.log(`🎲 Generated batch code: ${batchCode}`);

        // Update on Monday immediately
        await this.mondayClient.updateItemColumn(
            item_id,
            this.batchCodeColumnId,
            batchCode
        );

        console.log(`✅ Updated Monday.com item ${item_id} with batch code: ${batchCode}`);

        const processingTime = (Date.now() - startTime) / 1000;
        recordCodeGeneration('batch_code', true, processingTime);

        return {
            success: true,
            message: 'Batch code generated and assigned',
            batchCode,
            itemId: item_id,
            itemName: item_name,
            boardId: board_id,
            processingTime: Date.now() - startTime
        };

    } catch (error) {
        console.error('❌ Error processing batch code:', error);
        recordError('batch_code_generation');
        captureWebhookError(error as Error, {
            payload,
            processor: 'BatchCodeProcessor'
        });
        throw error;
    }
  }

  /**
   * Test Monday.com API connection
   */
  async testConnection(): Promise<boolean> {
    return await this.mondayClient.testConnection();
  }

  /**
   * Get processing statistics
   */
  async getStats(): Promise<any> {
    return await this.database.getStats();
  }
}

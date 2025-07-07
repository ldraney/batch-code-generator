import { generateUniqueBatchCode, saveBatchCode, getExistingBatchCode } from './batch-codes';
import { MondayClient, MondayWebhookPayload } from './monday';
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
      // Handle webhook verification challenge
      if (payload.challenge) {
        console.log('🔐 Webhook challenge received:', payload.challenge);
        return { challenge: payload.challenge };
      }

      if (!payload.event) {
        throw new Error('No event data in webhook payload');
      }

      const { event } = payload;
      
      // Log webhook processing
      await this.database.logWebhook({
        event_type: event.type,
        monday_item_id: event.data.item_id,
        payload: JSON.stringify(payload),
        status: 'success',
        processing_time_ms: 0 // Will update at the end
      });

      // Only process item creation events
      if (event.type !== 'create_item') {
        console.log(`⏭️ Skipping event type: ${event.type}`);
        return { message: 'Event type not processed', type: event.type };
      }

      const { item_id, item_name, board_id } = event.data;
      
      console.log(`🎯 Processing new item: ${item_name} (ID: ${item_id})`);

      // Check if item already has a batch code in our database
      const existingBatchCode = await getExistingBatchCode(item_id);
      
      if (existingBatchCode) {
        console.log(`✅ Item already has batch code: ${existingBatchCode}`);
        return { 
          message: 'Item already has batch code', 
          batchCode: existingBatchCode,
          itemId: item_id,
          fromDatabase: true
        };
      }

      // Generate new unique batch code
      const batchCode = await generateUniqueBatchCode();
      console.log(`🎲 Generated batch code: ${batchCode}`);

      // Save to database first
      await saveBatchCode(batchCode, item_id, board_id, item_name);
      console.log(`💾 Saved batch code to database`);

      // Update Monday.com item with batch code
      await this.mondayClient.updateItemColumn(
        item_id,
        this.batchCodeColumnId,
        batchCode
      );

      console.log(`✅ Updated Monday.com item ${item_id} with batch code: ${batchCode}`);

      // Record metrics
      const processingTime = (Date.now() - startTime) / 1000;
      recordCodeGeneration('batch_code', true, processingTime);

      // Update webhook log with success
      await this.database.logWebhook({
        event_type: event.type,
        monday_item_id: item_id,
        payload: JSON.stringify(payload),
        status: 'success',
        processing_time_ms: Date.now() - startTime
      });

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
      
      // Log error to database
      if (payload.event) {
        await this.database.logWebhook({
          event_type: payload.event.type,
          monday_item_id: payload.event.data.item_id,
          payload: JSON.stringify(payload),
          status: 'error',
          error_message: error instanceof Error ? error.message : 'Unknown error',
          processing_time_ms: Date.now() - startTime
        });
      }
      
      // Record error metrics
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

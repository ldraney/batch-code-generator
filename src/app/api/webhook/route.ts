import { NextRequest, NextResponse } from 'next/server';
import { BatchCodeProcessor } from '@/lib/batch-code-processor';
import { MondayWebhookSchema } from '@/lib/monday';

// Import metrics with error handling
let recordWebhookRequest: any, recordError: any;
try {
  const metrics = require('@/lib/metrics');
  recordWebhookRequest = metrics.recordWebhookRequest;
  recordError = metrics.recordError;
} catch (error) {
  console.warn('Metrics module not available:', error);
  recordWebhookRequest = () => {};
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

export async function POST(request: NextRequest) {
  const startTime = Date.now();

  try {
    console.log('📨 Monday.com webhook received');

    // Get environment variables
    const mondayApiKey = process.env.MONDAY_API_KEY;
    const batchCodeColumnId = process.env.MONDAY_BATCH_CODE_COLUMN_ID;
    const webhookSecret = process.env.MONDAY_WEBHOOK_SECRET;

    if (!mondayApiKey || !batchCodeColumnId) {
      throw new Error('Missing required environment variables');
    }

    // Verify webhook signature (if using Monday.com webhook secrets)
    if (webhookSecret) {
      const signature = request.headers.get('x-monday-signature-256');
      // Add signature verification logic here if needed
    }

    // Parse and validate payload
    const body = await request.json();
    console.log('📋 Webhook payload:', JSON.stringify(body, null, 2));

    const payload = MondayWebhookSchema.parse(body);

    // Process the webhook
    const processor = new BatchCodeProcessor(mondayApiKey, batchCodeColumnId);
    await processor.initialize();
    const result = await processor.processWebhook(payload);

    recordWebhookRequest('POST', '200', '/api/webhook');

    console.log('✅ Webhook processed successfully:', result);
    return NextResponse.json(result, { status: 200 });

  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.error('❌ Webhook processing error:', error);

    captureWebhookError(error as Error, { 
      url: request.url,
      timestamp: new Date().toISOString() 
    });

    recordWebhookRequest('POST', '500', '/api/webhook');
    recordError('webhook_processing');

    return NextResponse.json(
      { 
        error: errorMessage,
        timestamp: new Date().toISOString()
      },
      { status: 500 }
    );
  }
}

// Keep the existing GET method for testing
export async function GET() {
  return NextResponse.json(
    {
      message: 'Monday.com Batch Code Generator webhook endpoint',
      supportedEvents: ['create_item'],
      status: 'active',
      timestamp: new Date().toISOString(),
    },
    { status: 200 }
  );
}

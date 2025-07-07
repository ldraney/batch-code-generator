import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { recordWebhookRequest, recordCodeGeneration, incrementActiveJobs, decrementActiveJobs, recordError } from '@/lib/metrics';

// Import Sentry conditionally to avoid errors if not configured
let captureWebhookError: ((error: Error, context: Record<string, any>) => void) | null = null;
try {
  const sentry = require('@/lib/sentry');
  captureWebhookError = sentry.captureWebhookError;
} catch (error) {
  console.warn('Sentry not available:', error);
}

// Webhook payload schema
const WebhookPayloadSchema = z.object({
  event: z.string(),
  data: z.object({
    type: z.string(),
    content: z.string().optional(),
    language: z.string().optional(),
    template: z.string().optional(),
    batch_id: z.string().optional(),
  }),
  timestamp: z.string(),
});

type WebhookPayload = z.infer<typeof WebhookPayloadSchema>;

export async function POST(request: NextRequest) {
  const startTime = Date.now();
  
  try {
    // Verify webhook secret
    const signature = request.headers.get('x-webhook-signature');
    if (!signature || !verifyWebhookSignature(signature)) {
      recordWebhookRequest('POST', '401', '/api/webhook');
      return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
    }

    // Parse and validate payload
    const body = await request.json();
    const payload = WebhookPayloadSchema.parse(body);

    // Handle different webhook events
    const result = await handleWebhookEvent(payload);
    
    recordWebhookRequest('POST', '200', '/api/webhook');
    recordCodeGeneration(payload.data.type, true, (Date.now() - startTime) / 1000);
    
    return NextResponse.json(result, { status: 200 });
    
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    
    // Log error and capture in Sentry if available
    console.error('Webhook error:', error);
    if (captureWebhookError) {
      captureWebhookError(error as Error, { request: request.url });
    }
    
    recordWebhookRequest('POST', '500', '/api/webhook');
    recordError(error instanceof z.ZodError ? 'validation' : 'processing');
    
    return NextResponse.json(
      { error: errorMessage },
      { status: 500 }
    );
  }
}

async function handleWebhookEvent(payload: WebhookPayload) {
  incrementActiveJobs();
  
  try {
    switch (payload.event) {
      case 'code_generation_request':
        return await handleCodeGenerationRequest(payload.data);
      case 'batch_job_request':
        return await handleBatchJobRequest(payload.data);
      default:
        throw new Error(`Unknown event type: ${payload.event}`);
    }
  } finally {
    decrementActiveJobs();
  }
}

async function handleCodeGenerationRequest(data: WebhookPayload['data']) {
  // Simulate code generation logic
  await new Promise(resolve => setTimeout(resolve, 100));
  
  return {
    success: true,
    message: 'Code generation started',
    job_id: `gen_${Date.now()}`,
    type: data.type,
    language: data.language || 'javascript',
  };
}

async function handleBatchJobRequest(data: WebhookPayload['data']) {
  // Simulate batch job processing
  await new Promise(resolve => setTimeout(resolve, 500));
  
  return {
    success: true,
    message: 'Batch job queued',
    batch_id: data.batch_id || `batch_${Date.now()}`,
    estimated_completion: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
  };
}

function verifyWebhookSignature(signature: string): boolean {
  // Simple signature verification - in production, use proper HMAC
  const expectedSignature = process.env.WEBHOOK_SECRET || 'dev-secret-123';
  return signature === expectedSignature;
}

export async function GET() {
  return NextResponse.json(
    { 
      message: 'Webhook endpoint is active',
      supportedEvents: ['code_generation_request', 'batch_job_request'],
      timestamp: new Date().toISOString(),
    },
    { status: 200 }
  );
}

#!/bin/bash

echo "🔧 Setup Script Mod 2: Fixing module syntax and Sentry CLI issues..."

# Fix sentry.ts module syntax
echo "📝 Fixing sentry.ts module syntax..."
cat > src/lib/sentry.ts << 'EOF'
import * as Sentry from '@sentry/nextjs';

// Only initialize utility functions if Sentry is available
const isSentryEnabled = !!process.env.SENTRY_DSN;

export function captureWebhookError(error: Error, context: Record<string, any>) {
  if (isSentryEnabled) {
    try {
      Sentry.withScope((scope) => {
        scope.setTag('component', 'webhook');
        scope.setContext('webhook_data', context);
        Sentry.captureException(error);
      });
    } catch (sentryError) {
      console.warn('Sentry error capture failed:', sentryError);
      console.error('Original webhook error:', error, context);
    }
  } else {
    console.error('Webhook error (Sentry not configured):', error, context);
  }
}

export function captureMetrics(name: string, value: number, tags?: Record<string, string>) {
  if (isSentryEnabled) {
    try {
      Sentry.addBreadcrumb({
        message: `Metric: ${name}`,
        category: 'metric',
        data: { value, ...tags },
        level: 'info',
      });
    } catch (sentryError) {
      console.warn('Sentry metric capture failed:', sentryError);
      console.log('Metric (fallback):', name, value, tags);
    }
  } else {
    console.log('Metric (Sentry not configured):', name, value, tags);
  }
}

export function initSentry() {
  if (isSentryEnabled) {
    console.log('Sentry is configured and will be initialized by config files');
  } else {
    console.log('Sentry not configured - running without error tracking');
  }
}
EOF

# Update next.config.js to completely disable Sentry uploads in development
echo "⚙️ Updating Next.js config to disable Sentry CLI..."
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverComponentsExternalPackages: ['prom-client'],
  },
  // Ensure API routes work properly with monitoring
  async rewrites() {
    return [
      {
        source: '/metrics',
        destination: '/api/metrics',
      },
    ];
  },
  // Health check for load balancers
  async headers() {
    return [
      {
        source: '/api/health',
        headers: [
          {
            key: 'Cache-Control',
            value: 'no-store, max-age=0',
          },
        ],
      },
    ];
  },
};

// Only apply Sentry config if we're in production AND have all Sentry env vars
const shouldUseSentry = process.env.NODE_ENV === 'production' 
  && process.env.SENTRY_DSN 
  && process.env.SENTRY_ORG 
  && process.env.SENTRY_PROJECT;

if (shouldUseSentry) {
  const { withSentryConfig } = require('@sentry/nextjs');
  
  const sentryWebpackPluginOptions = {
    // Silence Sentry build warnings
    silent: true,
    
    // Hide source maps in production
    hideSourceMaps: true,
    
    // Organization and project
    org: process.env.SENTRY_ORG,
    project: process.env.SENTRY_PROJECT,
    
    // Auth token for uploads
    authToken: process.env.SENTRY_AUTH_TOKEN,
  };

  module.exports = withSentryConfig(nextConfig, sentryWebpackPluginOptions);
} else {
  console.log('Sentry disabled - running without error tracking');
  module.exports = nextConfig;
}
EOF

# Update Sentry config files to be conditional
echo "🔧 Updating Sentry client config..."
cat > sentry.client.config.ts << 'EOF'
import * as Sentry from '@sentry/nextjs';

// Only initialize if DSN is provided
if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    
    // Replay may only be enabled for the client-side
    integrations: [
      new Sentry.Replay(),
    ],

    // Set tracesSampleRate to 1.0 to capture 100%
    // of the transactions for performance monitoring.
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,

    // Capture Replay for 10% of all sessions,
    // plus for 100% of sessions with an error
    replaysSessionSampleRate: 0.1,
    replaysOnErrorSampleRate: 1.0,

    // Debug should be false in production
    debug: process.env.NODE_ENV === 'development',

    // Environment
    environment: process.env.NODE_ENV || 'development',
  });
} else {
  console.log('Sentry client: DSN not provided, skipping initialization');
}
EOF

echo "🔧 Updating Sentry server config..."
cat > sentry.server.config.ts << 'EOF'
import * as Sentry from '@sentry/nextjs';

// Only initialize if DSN is provided
if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,

    // Set tracesSampleRate to 1.0 to capture 100%
    // of the transactions for performance monitoring.
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,

    // Debug should be false in production
    debug: process.env.NODE_ENV === 'development',

    // Environment
    environment: process.env.NODE_ENV || 'development',
  });
} else {
  console.log('Sentry server: DSN not provided, skipping initialization');
}
EOF

echo "🔧 Updating Sentry edge config..."
cat > sentry.edge.config.ts << 'EOF'
import * as Sentry from '@sentry/nextjs';

// Only initialize if DSN is provided
if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,

    // Set tracesSampleRate to 1.0 to capture 100%
    // of the transactions for performance monitoring.
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,

    // Debug should be false in production
    debug: process.env.NODE_ENV === 'development',

    // Environment
    environment: process.env.NODE_ENV || 'development',
  });
} else {
  console.log('Sentry edge: DSN not provided, skipping initialization');
}
EOF

# Clean up any build artifacts that might be causing issues
echo "🧹 Cleaning build artifacts..."
rm -rf .next
rm -rf node_modules/.cache

# Update webhook route to fix the import issue
echo "🔌 Updating webhook route..."
cat > src/app/api/webhook/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { recordWebhookRequest, recordCodeGeneration, incrementActiveJobs, decrementActiveJobs, recordError } from '@/lib/metrics';
import { captureWebhookError } from '@/lib/sentry';

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
    
    // Log error and capture in Sentry
    console.error('Webhook error:', error);
    captureWebhookError(error as Error, { request: request.url });
    
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
EOF

echo ""
echo "✅ Setup Script Mod 2 Complete!"
echo ""
echo "🔧 Changes made:"
echo "- Fixed sentry.ts module syntax (proper ES6 imports/exports)"
echo "- Disabled Sentry CLI uploads in development"
echo "- Made all Sentry configs conditional on DSN presence"
echo "- Cleaned build artifacts"
echo "- Updated webhook route imports"
echo ""
echo "🚀 Try running again:"
echo "npm run build"
echo "npm run dev"
echo ""
echo "🎯 App should now build and run cleanly without Sentry errors!"

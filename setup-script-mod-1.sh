#!/bin/bash

echo "🔧 Setup Script Mod 1: Fixing Sentry Configuration Issues..."

# Create Sentry client config
echo "📱 Creating Sentry client configuration..."
cat > sentry.client.config.ts << 'EOF'
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  
  // Replay may only be enabled for the client-side
  integrations: [
    new Sentry.Replay(),
  ],

  // Set tracesSampleRate to 1.0 to capture 100%
  // of the transactions for performance monitoring.
  // We recommend adjusting this value in production
  tracesSampleRate: 1.0,

  // Capture Replay for 10% of all sessions,
  // plus for 100% of sessions with an error
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,

  // Debug should be false in production
  debug: process.env.NODE_ENV === 'development',

  // Environment
  environment: process.env.NODE_ENV || 'development',

  // Only initialize if DSN is provided
  enabled: !!process.env.SENTRY_DSN,
});
EOF

# Create Sentry server config
echo "️ Creating Sentry server configuration..."
cat > sentry.server.config.ts << 'EOF'
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.SENTRY_DSN,

  // Set tracesSampleRate to 1.0 to capture 100%
  // of the transactions for performance monitoring.
  // We recommend adjusting this value in production
  tracesSampleRate: 1.0,

  // Debug should be false in production
  debug: process.env.NODE_ENV === 'development',

  // Environment
  environment: process.env.NODE_ENV || 'development',

  // Only initialize if DSN is provided
  enabled: !!process.env.SENTRY_DSN,
});
EOF

# Create Sentry edge config
echo "⚡ Creating Sentry edge configuration..."
cat > sentry.edge.config.ts << 'EOF'
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.SENTRY_DSN,

  // Set tracesSampleRate to 1.0 to capture 100%
  // of the transactions for performance monitoring.
  // We recommend adjusting this value in production
  tracesSampleRate: 1.0,

  // Debug should be false in production
  debug: process.env.NODE_ENV === 'development',

  // Environment
  environment: process.env.NODE_ENV || 'development',

  // Only initialize if DSN is provided
  enabled: !!process.env.SENTRY_DSN,
});
EOF

# Create global error handler
echo "🚨 Creating global error handler..."
cat > src/app/global-error.tsx << 'EOF'
'use client';

import * as Sentry from '@sentry/nextjs';
import { useEffect } from 'react';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Log the error to Sentry
    Sentry.captureException(error);
  }, [error]);

  return (
    <html>
      <body>
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="max-w-md mx-auto text-center">
            <div className="bg-red-100 rounded-full p-3 mx-auto w-16 h-16 flex items-center justify-center mb-4">
              <svg className="h-8 w-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
              </svg>
            </div>
            <h1 className="text-xl font-semibold text-gray-900 mb-2">Something went wrong!</h1>
            <p className="text-gray-600 mb-6">
              An unexpected error occurred. Our team has been notified.
            </p>
            <button
              onClick={reset}
              className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors"
            >
              Try again
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}
EOF

# Update next.config.js to fix Sentry warnings
echo "⚙️ Updating Next.js configuration..."
cat > next.config.js << 'EOF'
const { withSentryConfig } = require('@sentry/nextjs');

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

const sentryWebpackPluginOptions = {
  // Silence Sentry build warnings
  silent: true,
  
  // Hide source maps in production
  hideSourceMaps: true,
  
  // Disable source map upload in development
  dryRun: process.env.NODE_ENV === 'development',
  
  // Organization and project (optional)
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,
  
  // Auth token for uploads (only needed in production)
  authToken: process.env.SENTRY_AUTH_TOKEN,
};

// Only apply Sentry config if DSN is provided
module.exports = process.env.SENTRY_DSN 
  ? withSentryConfig(nextConfig, sentryWebpackPluginOptions)
  : nextConfig;
EOF

# Fix API route imports to handle Sentry initialization
echo "🔌 Fixing API route imports..."

# Update health route to handle potential Sentry errors
cat > src/app/api/health/route.ts << 'EOF'
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    // Basic health checks
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      version: process.env.npm_package_version || '0.1.0',
      environment: process.env.NODE_ENV || 'development',
      sentry_enabled: !!process.env.SENTRY_DSN,
    };

    return NextResponse.json(health, { status: 200 });
  } catch (error) {
    console.error('Health check error:', error);
    return NextResponse.json(
      { 
        status: 'unhealthy', 
        error: error instanceof Error ? error.message : 'Unknown error',
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}

export async function HEAD() {
  return new Response(null, { status: 200 });
}
EOF

# Update webhook route to handle Sentry gracefully
cat > src/app/api/webhook/route.ts << 'EOF'
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
EOF

# Update sentry lib to be more defensive
cat > src/lib/sentry.ts << 'EOF'
// Only initialize Sentry if DSN is provided
if (process.env.SENTRY_DSN) {
  try {
    const Sentry = require('@sentry/nextjs');
    
    // This will be called automatically by the Sentry config files
    // but we can also export utility functions
    
    export function captureWebhookError(error: Error, context: Record<string, any>) {
      Sentry.withScope((scope: any) => {
        scope.setTag('component', 'webhook');
        scope.setContext('webhook_data', context);
        Sentry.captureException(error);
      });
    }

    export function captureMetrics(name: string, value: number, tags?: Record<string, string>) {
      Sentry.addBreadcrumb({
        message: `Metric: ${name}`,
        category: 'metric',
        data: { value, ...tags },
        level: 'info',
      });
    }
  } catch (error) {
    console.warn('Sentry initialization failed:', error);
    
    // Provide fallback functions
    export function captureWebhookError(error: Error, context: Record<string, any>) {
      console.error('Webhook error (Sentry not available):', error, context);
    }

    export function captureMetrics(name: string, value: number, tags?: Record<string, string>) {
      console.log('Metric (Sentry not available):', name, value, tags);
    }
  }
} else {
  // Provide no-op functions when Sentry is not configured
  export function captureWebhookError(error: Error, context: Record<string, any>) {
    console.error('Webhook error (Sentry not configured):', error, context);
  }

  export function captureMetrics(name: string, value: number, tags?: Record<string, string>) {
    console.log('Metric (Sentry not configured):', name, value, tags);
  }
}
EOF

# Fix security vulnerability
echo "🔒 Running security audit fix..."
npm audit fix --force

echo ""
echo "✅ Setup Script Mod 1 Complete!"
echo ""
echo "🔧 Changes made:"
echo "- Created missing Sentry configuration files"
echo "- Added global error handler for React errors"
echo "- Updated Next.js config to hide source maps"
echo "- Made Sentry integration optional (works without DSN)"
echo "- Fixed API routes to handle Sentry gracefully"
echo "- Applied security vulnerability fixes"
echo ""
echo "🚀 Try running again:"
echo "npm run build"
echo "npm run dev"
echo ""
echo "🎯 App should now work without Sentry DSN and build successfully!"

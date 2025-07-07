#!/bin/bash

echo "🔧 Fixing Sentry transaction API..."

# Fix sentry.ts with modern Sentry API
cat > src/lib/sentry.ts << 'EOF'
import * as Sentry from '@sentry/nextjs';

// Check if Sentry is properly configured
export const isSentryEnabled = !!process.env.SENTRY_DSN;

// Enhanced error capture for webhooks
export function captureWebhookError(
  error: Error, 
  context: {
    request?: string;
    payload?: any;
    headers?: Record<string, string>;
    userId?: string;
  }
) {
  if (!isSentryEnabled) {
    console.error('Webhook error (Sentry not configured):', error, context);
    return;
  }

  Sentry.withScope((scope) => {
    scope.setTag('error_type', 'webhook');
    scope.setTag('component', 'webhook_handler');
    
    // Add context for debugging
    scope.setContext('webhook_data', {
      request_url: context.request,
      payload_size: context.payload ? JSON.stringify(context.payload).length : 0,
      timestamp: new Date().toISOString(),
    });
    
    // Add headers (without sensitive data)
    if (context.headers) {
      const safeHeaders = Object.fromEntries(
        Object.entries(context.headers).filter(([key]) => 
          !key.toLowerCase().includes('authorization') &&
          !key.toLowerCase().includes('secret') &&
          !key.toLowerCase().includes('token')
        )
      );
      scope.setContext('headers', safeHeaders);
    }
    
    // Add user context if available
    if (context.userId) {
      scope.setUser({ id: context.userId });
    }
    
    scope.setLevel('error');
    Sentry.captureException(error);
  });
}

// Enhanced metric capture with business context
export function captureBusinessMetric(
  name: string, 
  value: number, 
  tags?: Record<string, string>,
  extra?: Record<string, any>
) {
  if (!isSentryEnabled) {
    console.log(`Metric (Sentry not configured): ${name}=${value}`, tags);
    return;
  }

  Sentry.addBreadcrumb({
    message: `Business Metric: ${name}`,
    category: 'metric',
    data: { 
      value, 
      unit: tags?.unit || 'count',
      timestamp: new Date().toISOString(),
      ...tags,
      ...extra 
    },
    level: 'info',
  });
}

// Performance monitoring for code generation using modern Sentry API
export function trackCodeGeneration(
  operation: string,
  metadata: {
    type: string;
    language?: string;
    duration: number;
    success: boolean;
    error?: string;
  }
) {
  if (!isSentryEnabled) {
    console.log(`Code Generation Tracking: ${operation}`, metadata);
    return;
  }

  // Use modern Sentry span API instead of deprecated startTransaction
  Sentry.withScope((scope) => {
    scope.setTag('operation', operation);
    scope.setTag('type', metadata.type);
    scope.setTag('language', metadata.language || 'unknown');
    scope.setTag('success', metadata.success.toString());
    
    scope.setContext('code_generation', {
      operation,
      type: metadata.type,
      language: metadata.language,
      duration: metadata.duration,
      success: metadata.success,
      error: metadata.error,
      timestamp: new Date().toISOString(),
    });

    // Create a span for the operation
    const span = Sentry.getCurrentHub().getScope()?.getSpan();
    if (span) {
      const childSpan = span.startChild({
        op: 'code_generation',
        description: `${operation}: ${metadata.type}`,
        data: {
          type: metadata.type,
          language: metadata.language,
          duration: metadata.duration,
        },
      });

      if (!metadata.success && metadata.error) {
        childSpan.setTag('error', metadata.error);
        childSpan.setStatus('internal_error');
      } else {
        childSpan.setStatus('ok');
      }

      childSpan.finish();
    }

    // Add breadcrumb for tracking
    Sentry.addBreadcrumb({
      message: `Code Generation: ${operation}`,
      category: 'code_generation',
      data: metadata,
      level: metadata.success ? 'info' : 'error',
    });

    // Capture exception if operation failed
    if (!metadata.success && metadata.error) {
      Sentry.captureException(new Error(`Code generation failed: ${metadata.error}`));
    }
  });
}

// Initialize performance monitoring
export function initPerformanceMonitoring() {
  if (!isSentryEnabled) {
    console.log('Performance monitoring: Sentry not configured');
    return;
  }

  console.log('Performance monitoring: Sentry initialized');
}

// Utility function to capture custom events
export function captureCustomEvent(
  name: string,
  data?: Record<string, any>,
  level: 'debug' | 'info' | 'warning' | 'error' = 'info'
) {
  if (!isSentryEnabled) {
    console.log(`Custom Event (Sentry not configured): ${name}`, data);
    return;
  }

  Sentry.addBreadcrumb({
    message: name,
    category: 'custom',
    data: {
      ...data,
      timestamp: new Date().toISOString(),
    },
    level,
  });
}

// Helper to start a performance span (modern API)
export function startPerformanceSpan(name: string, operation: string) {
  if (!isSentryEnabled) {
    return {
      setTag: () => {},
      setData: () => {},
      setStatus: () => {},
      finish: () => {},
    };
  }

  const span = Sentry.getCurrentHub().getScope()?.getSpan();
  if (span) {
    return span.startChild({
      op: operation,
      description: name,
    });
  }

  // Return a mock span if no active span
  return {
    setTag: () => {},
    setData: () => {},
    setStatus: () => {},
    finish: () => {},
  };
}
EOF

echo "✅ Fixed Sentry transaction API!"
echo ""
echo "🔧 Changes made:"
echo "- Replaced deprecated startTransaction with modern span API"
echo "- Added proper error handling and fallbacks"
echo "- Enhanced performance tracking with spans"
echo "- Added utility functions for custom events"
echo "- Better TypeScript compatibility"
echo ""
echo "🚀 Now try:"
echo "npm run build   # Should compile successfully!"

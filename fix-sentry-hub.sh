#!/bin/bash

echo "🔧 Fixing Sentry hub API with modern approach..."

# Fix sentry.ts with completely modern Sentry API
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

// Simplified performance monitoring for code generation
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

  // Use modern Sentry withScope for context
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

// Performance timing utility (simple approach)
export function measurePerformance<T>(
  name: string,
  operation: () => T | Promise<T>
): T | Promise<T> {
  if (!isSentryEnabled) {
    return operation();
  }

  const startTime = Date.now();
  
  try {
    const result = operation();
    
    // Handle both sync and async operations
    if (result instanceof Promise) {
      return result.then((value) => {
        const duration = Date.now() - startTime;
        captureBusinessMetric(`performance.${name}`, duration, { unit: 'ms' });
        return value;
      }).catch((error) => {
        const duration = Date.now() - startTime;
        captureBusinessMetric(`performance.${name}.error`, duration, { unit: 'ms' });
        throw error;
      });
    } else {
      const duration = Date.now() - startTime;
      captureBusinessMetric(`performance.${name}`, duration, { unit: 'ms' });
      return result;
    }
  } catch (error) {
    const duration = Date.now() - startTime;
    captureBusinessMetric(`performance.${name}.error`, duration, { unit: 'ms' });
    throw error;
  }
}

// Enhanced error capture with automatic context
export function captureError(
  error: Error,
  context?: {
    component?: string;
    operation?: string;
    userId?: string;
    extra?: Record<string, any>;
  }
) {
  if (!isSentryEnabled) {
    console.error('Error (Sentry not configured):', error, context);
    return;
  }

  Sentry.withScope((scope) => {
    if (context?.component) {
      scope.setTag('component', context.component);
    }
    
    if (context?.operation) {
      scope.setTag('operation', context.operation);
    }
    
    if (context?.userId) {
      scope.setUser({ id: context.userId });
    }
    
    if (context?.extra) {
      scope.setContext('additional_info', context.extra);
    }
    
    scope.setLevel('error');
    Sentry.captureException(error);
  });
}

// Simple health check for Sentry
export function healthCheck(): { sentry: boolean; message: string } {
  if (!isSentryEnabled) {
    return {
      sentry: false,
      message: 'Sentry not configured (missing SENTRY_DSN)'
    };
  }
  
  return {
    sentry: true,
    message: 'Sentry initialized and ready'
  };
}
EOF

echo "✅ Fixed Sentry hub API!"
echo ""
echo "🔧 Changes made:"
echo "- Removed all deprecated APIs (getCurrentHub, startTransaction)"
echo "- Simplified to use only stable Sentry APIs"
echo "- Added measurePerformance utility for timing"
echo "- Enhanced error capture with better context"
echo "- Added health check for Sentry status"
echo "- Focus on breadcrumbs and context over complex spans"
echo ""
echo "🚀 Now try:"
echo "npm run build   # Should be completely clean!"

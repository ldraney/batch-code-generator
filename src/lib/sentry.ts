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

// Performance monitoring for code generation
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

  const transaction = Sentry.startTransaction({
    name: `code_generation.${operation}`,
    op: 'code_generation',
    tags: {
      type: metadata.type,
      language: metadata.language || 'unknown',
      success: metadata.success.toString(),
    },
    data: {
      duration: metadata.duration,
      timestamp: new Date().toISOString(),
    },
  });

  if (!metadata.success && metadata.error) {
    transaction.setTag('error', metadata.error);
    transaction.setStatus('internal_error');
  } else {
    transaction.setStatus('ok');
  }

  transaction.finish();
}

// Initialize performance monitoring
export function initPerformanceMonitoring() {
  if (!isSentryEnabled) {
    console.log('Performance monitoring: Sentry not configured');
    return;
  }

  console.log('Performance monitoring: Sentry initialized');
}

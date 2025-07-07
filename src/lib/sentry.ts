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

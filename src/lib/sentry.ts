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

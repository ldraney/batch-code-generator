import * as Sentry from '@sentry/nextjs';

export function initSentry() {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    tracesSampleRate: 1.0,
    debug: process.env.NODE_ENV === 'development',
    integrations: [
      new Sentry.Integrations.Http({ tracing: true }),
    ],
    environment: process.env.NODE_ENV,
    beforeSend(event) {
      if (event.request?.url?.includes('/api/health')) {
        return null;
      }
      return event;
    },
  });
}

export function captureWebhookError(error: Error, context: Record<string, any>) {
  Sentry.withScope((scope) => {
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

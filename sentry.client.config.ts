import * as Sentry from '@sentry/nextjs';

const SENTRY_DSN = process.env.NEXT_PUBLIC_SENTRY_DSN || process.env.SENTRY_DSN;

if (SENTRY_DSN) {
  Sentry.init({
    dsn: SENTRY_DSN,
    
    // Performance monitoring
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
    
    // Enhanced error context
    beforeSend(event, hint) {
      // Add custom context for better debugging
      if (event.exception) {
        event.tags = {
          ...event.tags,
          component: 'client',
        };
      }
      return event;
    },
    
    // Environment setup
    environment: process.env.NODE_ENV || 'development',
    release: process.env.VERCEL_GIT_COMMIT_SHA || 'dev',
    
    // Debug in development
    debug: process.env.NODE_ENV === 'development',
  });
}

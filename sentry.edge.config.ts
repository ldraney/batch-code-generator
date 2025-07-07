import * as Sentry from '@sentry/nextjs';

const SENTRY_DSN = process.env.SENTRY_DSN;

if (SENTRY_DSN) {
  Sentry.init({
    dsn: SENTRY_DSN,
    
    // Performance monitoring (lighter for edge)
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.05 : 1.0,
    
    // Environment setup
    environment: process.env.NODE_ENV || 'development',
    release: process.env.VERCEL_GIT_COMMIT_SHA || process.env.FLY_ALLOC_ID || 'dev',
    
    // Edge-specific context
    beforeSend(event, hint) {
      if (event.exception) {
        event.tags = {
          ...event.tags,
          component: 'edge',
        };
      }
      return event;
    },
    
    // Debug in development
    debug: process.env.NODE_ENV === 'development',
  });
}

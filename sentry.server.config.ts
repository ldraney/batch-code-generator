import * as Sentry from '@sentry/nextjs';

const SENTRY_DSN = process.env.SENTRY_DSN;

if (SENTRY_DSN) {
  Sentry.init({
    dsn: SENTRY_DSN,
    
    // Performance monitoring
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
    
    // Environment setup
    environment: process.env.NODE_ENV || 'development',
    release: process.env.VERCEL_GIT_COMMIT_SHA || process.env.FLY_ALLOC_ID || 'dev',
    
    // Enhanced error context
    beforeSend(event, hint) {
      // Add server-specific context
      if (event.exception) {
        event.tags = {
          ...event.tags,
          component: 'server',
          node_version: process.version,
          platform: process.platform,
        };
        
        // Add memory usage context
        event.contexts = {
          ...event.contexts,
          runtime: {
            name: 'node',
            version: process.version,
          },
          memory: process.memoryUsage(),
        };
      }
      return event;
    },
    
    // Debug in development
    debug: process.env.NODE_ENV === 'development',
  });
}

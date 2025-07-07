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

// Only apply Sentry config if we're in production AND have all Sentry env vars
const shouldUseSentry = process.env.NODE_ENV === 'production' 
  && process.env.SENTRY_DSN 
  && process.env.SENTRY_ORG 
  && process.env.SENTRY_PROJECT;

if (shouldUseSentry) {
  const { withSentryConfig } = require('@sentry/nextjs');
  
  const sentryWebpackPluginOptions = {
    // Silence Sentry build warnings
    silent: true,
    
    // Hide source maps in production
    hideSourceMaps: true,
    
    // Organization and project
    org: process.env.SENTRY_ORG,
    project: process.env.SENTRY_PROJECT,
    
    // Auth token for uploads
    authToken: process.env.SENTRY_AUTH_TOKEN,
  };

  module.exports = withSentryConfig(nextConfig, sentryWebpackPluginOptions);
} else {
  console.log('Sentry disabled - running without error tracking');
  module.exports = nextConfig;
}

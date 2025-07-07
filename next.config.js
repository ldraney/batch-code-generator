const { withSentryConfig } = require('@sentry/nextjs');

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

const sentryWebpackPluginOptions = {
  // Silence Sentry build warnings
  silent: true,
  
  // Hide source maps in production
  hideSourceMaps: true,
  
  // Disable source map upload in development
  dryRun: process.env.NODE_ENV === 'development',
  
  // Organization and project (optional)
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,
  
  // Auth token for uploads (only needed in production)
  authToken: process.env.SENTRY_AUTH_TOKEN,
};

// Only apply Sentry config if DSN is provided
module.exports = process.env.SENTRY_DSN 
  ? withSentryConfig(nextConfig, sentryWebpackPluginOptions)
  : nextConfig;

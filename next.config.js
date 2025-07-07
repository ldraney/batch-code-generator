const { withSentryConfig } = require('@sentry/nextjs');

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Output for better Docker builds and Fly.io
  output: 'standalone',
  
  // Experimental features
  experimental: {
    serverComponentsExternalPackages: ['prom-client'],
    instrumentationHook: true,
  },
  
  // API route optimization
  async rewrites() {
    return [
      {
        source: '/metrics',
        destination: '/api/metrics',
      },
      {
        source: '/health',
        destination: '/api/health',
      },
    ];
  },
  
  // Headers for monitoring and health checks
  async headers() {
    return [
      {
        source: '/api/health',
        headers: [
          {
            key: 'Cache-Control',
            value: 'no-store, max-age=0',
          },
          {
            key: 'X-Health-Check',
            value: 'true',
          },
        ],
      },
      {
        source: '/api/metrics',
        headers: [
          {
            key: 'Cache-Control',
            value: 'no-store, max-age=0',
          },
        ],
      },
    ];
  },
  
  // Webpack optimization for metrics
  webpack: (config, { isServer }) => {
    if (isServer) {
      config.externals.push('prom-client');
    }
    return config;
  },
};

// Sentry configuration
const sentryWebpackPluginOptions = {
  // Suppress all Sentry CLI logs
  silent: true,
  
  // Hide source maps from public
  hideSourceMaps: true,
  
  // Disable dry run for proper source map uploads
  dryRun: false,
  
  // Automatically tree-shake Sentry logger statements
  disableLogger: true,
  
  // Upload source maps for better error tracking
  widenClientFileUpload: true,
  
  // Transpile SDK to work with older browsers
  transpileClientSDK: true,
  
  // Route browser requests through tunneling
  tunnelRoute: '/monitoring/sentry',
  
  // Organization and project from environment
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,
  
  // Auth token for uploads
  authToken: process.env.SENTRY_AUTH_TOKEN,
};

// Only apply Sentry config if DSN is provided
module.exports = process.env.SENTRY_DSN
  ? withSentryConfig(nextConfig, sentryWebpackPluginOptions)
  : nextConfig;

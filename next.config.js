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


// Injected content via Sentry wizard below

// const { withSentryConfig } = require("@sentry/nextjs");

module.exports = withSentryConfig(
  module.exports,
  {
    // For all available options, see:
    // https://www.npmjs.com/package/@sentry/webpack-plugin#options

    org: "pure-earth-labs-devops",
    project: "javascript-nextjs",

    // Only print logs for uploading source maps in CI
    silent: !process.env.CI,

    // For all available options, see:
    // https://docs.sentry.io/platforms/javascript/guides/nextjs/manual-setup/

    // Upload a larger set of source maps for prettier stack traces (increases build time)
    widenClientFileUpload: true,

    // Route browser requests to Sentry through a Next.js rewrite to circumvent ad-blockers.
    // This can increase your server load as well as your hosting bill.
    // Note: Check that the configured route will not match with your Next.js middleware, otherwise reporting of client-
    // side errors will fail.
    tunnelRoute: "/monitoring",

    // Automatically tree-shake Sentry logger statements to reduce bundle size
    disableLogger: true,

    // Enables automatic instrumentation of Vercel Cron Monitors. (Does not yet work with App Router route handlers.)
    // See the following for more information:
    // https://docs.sentry.io/product/crons/
    // https://vercel.com/docs/cron-jobs
    automaticVercelMonitors: true,
  }
);

#!/bin/bash

echo "🔧 Fixing final issues for clean build..."
echo "Addressing: Sentry Replay, Playwright types, deprecation warnings"

# Fix Sentry client config - remove Replay integration (not available in this version)
echo "📱 Fixing Sentry client configuration..."
cat > sentry.client.config.ts << 'EOF'
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
EOF

# Create modern instrumentation files (Next.js 13+ way)
echo "🔧 Creating modern instrumentation files..."
cat > instrumentation.ts << 'EOF'
export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    await import('./sentry.server.config');
  }

  if (process.env.NEXT_RUNTIME === 'edge') {
    await import('./sentry.edge.config');
  }
}
EOF

# Create client instrumentation
mkdir -p src/app
cat > src/app/instrumentation-client.ts << 'EOF'
import * as Sentry from '@sentry/nextjs';

const SENTRY_DSN = process.env.NEXT_PUBLIC_SENTRY_DSN || process.env.SENTRY_DSN;

if (SENTRY_DSN) {
  Sentry.init({
    dsn: SENTRY_DSN,
    
    // Performance monitoring
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
    
    // Environment setup
    environment: process.env.NODE_ENV || 'development',
    release: process.env.VERCEL_GIT_COMMIT_SHA || 'dev',
    
    // Enhanced error context
    beforeSend(event, hint) {
      if (event.exception) {
        event.tags = {
          ...event.tags,
          component: 'client',
        };
      }
      return event;
    },
    
    // Debug in development
    debug: process.env.NODE_ENV === 'development',
  });
}
EOF

# Fix Playwright config to make it optional for builds
echo "🎭 Fixing Playwright configuration..."
cat > playwright.config.ts << 'EOF'
// This file is only used when running E2E tests
// It won't interfere with Next.js builds

import type { PlaywrightTestConfig } from '@playwright/test';

const config: PlaywrightTestConfig = {
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },

  projects: [
    {
      name: 'chromium',
      use: { 
        ...{ name: 'Desktop Chrome' } // Simplified device config
      },
    },
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
};

export default config;
EOF

# Move Playwright config out of TypeScript compilation path
mv playwright.config.ts playwright.config.js
cat > playwright.config.js << 'EOF'
// Playwright configuration (JavaScript to avoid TypeScript compilation issues)
module.exports = {
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },

  projects: [
    {
      name: 'chromium',
      use: {},
    },
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
};
EOF

# Update TypeScript config to exclude test files from build
echo "📝 Updating TypeScript configuration..."
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/components/*": ["./src/components/*"],
      "@/lib/*": ["./src/lib/*"],
      "@/types/*": ["./src/types/*"]
    }
  },
  "include": [
    "next-env.d.ts", 
    "**/*.ts", 
    "**/*.tsx", 
    ".next/types/**/*.ts",
    "instrumentation.ts"
  ],
  "exclude": [
    "node_modules",
    "tests/**/*",
    "playwright.config.*",
    "jest.config.*",
    "*.config.js"
  ]
}
EOF

# Install Playwright properly (but exclude from build)
echo "🎭 Installing Playwright properly..."
npm install --save-dev @playwright/test

# Update package.json to separate test deps from build deps
echo "📦 Updating test scripts..."
npm pkg set scripts.test:e2e:install="npx playwright install"

# Clean build artifacts
echo "🧹 Cleaning build artifacts..."
rm -rf .next
rm -rf node_modules/.cache

echo ""
echo "✅ Final fixes complete!"
echo ""
echo "🔧 Changes made:"
echo "- Removed Sentry Replay integration (not available in this version)"
echo "- Created modern instrumentation files for Next.js 13+"
echo "- Fixed Playwright config to not interfere with builds"
echo "- Updated TypeScript config to exclude test files"
echo "- Properly installed Playwright"
echo ""
echo "🚀 Now try:"
echo "npm run build   # Should build cleanly!"
echo "npm run dev     # Should start without warnings"
echo ""
echo "🎯 Ready for Docker and Fly.io deployment!"

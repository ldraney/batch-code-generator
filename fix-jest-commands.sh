#!/bin/bash

echo "🔧 Fixing Jest command issues..."

# Install Jest and related dependencies properly
echo "📦 Installing Jest properly..."
npm install --save-dev \
  jest \
  @types/jest \
  jest-environment-jsdom \
  @testing-library/react \
  @testing-library/jest-dom \
  @testing-library/user-event \
  ts-jest

# Fix package.json scripts to use npm test instead of direct jest
echo "📝 Fixing package.json scripts..."
npm pkg set scripts.test="jest"
npm pkg set scripts.test:watch="jest --watch"
npm pkg set scripts.test:coverage="jest --coverage"
npm pkg set scripts.test:integration="jest --testPathPattern=integration"
npm pkg set scripts.test:smoke="jest tests/regression/smoke"
npm pkg set scripts.test:contracts="jest tests/regression/api"
npm pkg set scripts.test:performance="jest tests/regression/performance"

# Update the regression test script to use npm test
echo "🏃 Updating test-regression.sh script..."
cat > scripts/test-regression.sh << 'EOF'
#!/bin/bash

set -e

echo "🧪 Running Regression Test Suite..."

# Environment variables
export NODE_ENV=test
export TEST_BASE_URL=${TEST_BASE_URL:-http://localhost:3000}

echo "🎯 Testing against: $TEST_BASE_URL"

# Check if server is running
if ! curl -s "$TEST_BASE_URL/api/health" > /dev/null; then
    echo "❌ Server not responding at $TEST_BASE_URL"
    echo "💡 Start the server first: npm run dev (or npm start for prod build)"
    exit 1
fi

echo "✅ Server is responding"

# Run different test suites using npm run
echo ""
echo "📋 Running API Contract Tests..."
npm run test:contracts

echo ""
echo "⚡ Running Performance Tests..."
npm run test:performance

echo ""
echo "💨 Running Smoke Tests..."
npm run test:smoke

echo ""
echo "👁️ Running Visual Regression Tests..."
npm run test:visual

echo ""
echo "🎉 All regression tests completed!"
EOF

# Update the baseline capture script
echo "📸 Updating capture-baselines.sh script..."
cat > scripts/capture-baselines.sh << 'EOF'
#!/bin/bash

echo "📸 Capturing baseline screenshots and performance metrics..."

# Ensure server is running
if ! curl -s "http://localhost:3000/api/health" > /dev/null; then
    echo "❌ Server not running. Please start with 'npm run dev' first."
    exit 1
fi

echo "📷 Capturing visual baselines..."
npx playwright test tests/regression/visual --update-snapshots

echo "📊 Capturing performance baselines..."
npm run test:performance

echo "✅ Baselines captured! Commit these to version control."
echo "💡 Run 'npm run test:regression' to validate against baselines."
EOF

# Create a simplified Jest config that doesn't conflict with Next.js
echo "⚙️ Creating updated Jest configuration..."
cat > jest.config.js << 'EOF'
const nextJest = require('next/jest')

const createJestConfig = nextJest({
  // Provide the path to your Next.js app to load next.config.js and .env files
  dir: './',
})

// Add any custom config to be passed to Jest
const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  moduleNameMapping: {
    // Handle module aliases
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  testEnvironment: 'jest-environment-jsdom',
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.{js,jsx,ts,tsx}',
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70,
    },
  },
  testMatch: [
    '<rootDir>/src/**/__tests__/**/*.{js,jsx,ts,tsx}',
    '<rootDir>/src/**/*.{test,spec}.{js,jsx,ts,tsx}',
    '<rootDir>/tests/**/*.{test,spec}.{js,jsx,ts,tsx}',
  ],
  // Handle supertest and other Node.js modules
  testEnvironment: 'node',
  // Override for specific test types
  projects: [
    {
      displayName: 'node',
      testEnvironment: 'node',
      testMatch: [
        '<rootDir>/tests/**/*.{test,spec}.{js,jsx,ts,tsx}',
        '<rootDir>/src/app/api/**/*.{test,spec}.{js,jsx,ts,tsx}',
        '<rootDir>/src/lib/**/*.{test,spec}.{js,jsx,ts,tsx}',
      ],
    },
    {
      displayName: 'jsdom',
      testEnvironment: 'jsdom',
      setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
      testMatch: [
        '<rootDir>/src/components/**/*.{test,spec}.{js,jsx,ts,tsx}',
      ],
    },
  ],
}

// createJestConfig is exported this way to ensure that next/jest can load the Next.js config which is async
module.exports = createJestConfig(customJestConfig)
EOF

# Update jest.setup.js to be more robust
echo "🔧 Updating Jest setup..."
cat > jest.setup.js << 'EOF'
// Only import testing-library for jsdom environment
if (typeof window !== 'undefined') {
  import('@testing-library/jest-dom')
}

// Mock environment variables
process.env.WEBHOOK_SECRET = 'test-secret-123'
process.env.NODE_ENV = 'test'

// Mock Sentry for all tests
jest.mock('@sentry/nextjs', () => ({
  init: jest.fn(),
  captureException: jest.fn(),
  withScope: jest.fn((callback) => callback({
    setTag: jest.fn(),
    setContext: jest.fn(),
    setUser: jest.fn(),
    setLevel: jest.fn(),
  })),
  addBreadcrumb: jest.fn(),
  getCurrentHub: jest.fn(() => ({
    getScope: jest.fn(() => ({
      getSpan: jest.fn(),
    })),
  })),
}))

// Mock fetch for Node.js tests
if (typeof fetch === 'undefined') {
  global.fetch = jest.fn()
}

// Reduce console noise in tests
const originalConsole = global.console
global.console = {
  ...console,
  log: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}

// Restore console for debugging when needed
if (process.env.DEBUG_TESTS) {
  global.console = originalConsole
}
EOF

echo ""
echo "✅ Jest command issues fixed!"
echo ""
echo "🔧 Changes made:"
echo "- Installed Jest and dependencies properly"
echo "- Fixed package.json scripts to use npm run instead of direct jest"
echo "- Updated test runner scripts"
echo "- Improved Jest configuration for both Node.js and browser tests"
echo "- Enhanced Jest setup with better mocking"
echo ""
echo "📋 Files affected:"
echo "- package.json (test scripts)"
echo "- scripts/test-regression.sh"
echo "- scripts/capture-baselines.sh"
echo "- jest.config.js"
echo "- jest.setup.js"
echo ""
echo "🚀 Now try:"
echo "npm test                    # Should work!"
echo "npm run test:regression     # Should work!"
echo "npm run capture:baselines   # Should work!"

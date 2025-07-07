#!/bin/bash

# Quick fix for the environment variable issue
echo "🔧 Quick Fix for Environment Variables..."

# First, let's see what's currently in the jest.setup files
echo "📋 Current setup files:"
echo "jest.setup.js exists: $([ -f jest.setup.js ] && echo "YES" || echo "NO")"
echo "jest.setup.unit.js exists: $([ -f jest.setup.unit.js ] && echo "YES" || echo "NO")"

# Check what configuration jest is actually using
echo ""
echo "📋 Checking Jest configuration..."

# Let's fix the jest.setup.unit.js to force the correct environment variable
cat > jest.setup.unit.js << 'EOF'
// Unit test specific setup - FORCE test environment variables
console.log('🔧 Setting up UNIT TEST environment variables...')

// FORCE these values for unit tests
process.env.NODE_ENV = 'test'
process.env.WEBHOOK_SECRET = 'test-secret-123'
process.env.SENTRY_DSN = 'https://fake-dsn@sentry.io/fake-project'

console.log('✅ Unit test env vars set:', {
  NODE_ENV: process.env.NODE_ENV,
  WEBHOOK_SECRET: process.env.WEBHOOK_SECRET
})

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
EOF

# Update the jest.config.unit.js to make sure it uses the right setup file
cat > jest.config.unit.js << 'EOF'
const nextJest = require('next/jest')

const createJestConfig = nextJest({
  dir: './',
})

const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.unit.js'],
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  testEnvironment: 'node',
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.{js,jsx,ts,tsx}',
  ],
  testMatch: [
    '<rootDir>/src/**/__tests__/**/*.{js,jsx,ts,tsx}',
    '<rootDir>/src/**/*.{test,spec}.{js,jsx,ts,tsx}',
    '<rootDir>/tests/jest-tests/unit/**/*.{test,spec}.{js,jsx,ts,tsx}',
  ],
  testPathIgnorePatterns: [
    '<rootDir>/.next/',
    '<rootDir>/node_modules/',
    '<rootDir>/tests/playwright-tests/',
    '<rootDir>/tests/load/',
    '<rootDir>/tests/jest-tests/integration/',
    '<rootDir>/tests/jest-tests/regression/',
  ],
  modulePathIgnorePatterns: [
    '<rootDir>/.next/',
  ],
  clearMocks: true,
  restoreMocks: true,
  haste: {
    enableSymlinks: false,
  },
}

module.exports = createJestConfig(customJestConfig)
EOF

# Make sure the main jest.setup.js doesn't interfere with unit tests
cat > jest.setup.js << 'EOF'
// Main Jest setup - used by integration tests
console.log('🔧 Setting up INTEGRATION TEST environment variables...')

// Only set if not already set (for integration tests)
if (!process.env.WEBHOOK_SECRET) {
  process.env.WEBHOOK_SECRET = process.env.CI ? 'test-secret-123' : 'dev-secret-123'
}

if (!process.env.NODE_ENV) {
  process.env.NODE_ENV = 'test'
}

if (!process.env.SENTRY_DSN) {
  process.env.SENTRY_DSN = 'https://fake-dsn@sentry.io/fake-project'
}

console.log('✅ Integration test env vars:', {
  NODE_ENV: process.env.NODE_ENV,
  WEBHOOK_SECRET: process.env.WEBHOOK_SECRET,
  CI: process.env.CI
})

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
EOF

# Test immediately to see if it's working
echo ""
echo "🧪 Testing the fix..."
echo "Running unit tests with explicit config..."

# Run unit tests with the specific config
npm run test:unit

echo ""
echo "✅ Quick fix applied!"
echo "If unit tests are still failing, the issue might be that jest.config.js is being used instead."
echo ""
echo "💡 Try running: npx jest --config jest.config.unit.js tests/jest-tests/unit/basic.test.ts"

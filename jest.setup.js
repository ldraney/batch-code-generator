// Jest setup - standardized for all tests
console.log('🔧 Setting up TEST environment variables...')

// Use test-secret-123 for ALL tests (unit, integration, smoke, etc.)
process.env.NODE_ENV = 'test'
process.env.WEBHOOK_SECRET = 'test-secret-123'  // Consistent for all tests
process.env.SENTRY_DSN = 'https://fake-dsn@sentry.io/fake-project'

console.log('✅ Test env vars set:', {
  NODE_ENV: process.env.NODE_ENV,
  WEBHOOK_SECRET: process.env.WEBHOOK_SECRET
})

// Only import testing-library for jsdom environment
if (typeof window !== 'undefined') {
  import('@testing-library/jest-dom')
}

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

// Reduce console noise in tests unless debugging
if (!process.env.DEBUG_TESTS) {
  const originalConsole = global.console
  global.console = {
    ...console,
    log: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  }
}

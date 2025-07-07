// Only import testing-library for jsdom environment
if (typeof window !== 'undefined') {
  import('@testing-library/jest-dom')
}

// Mock environment variables for both local and CI
process.env.WEBHOOK_SECRET = process.env.CI ? 'test-secret-123' : 'dev-secret-123'
process.env.NODE_ENV = 'test'
process.env.SENTRY_DSN = 'https://fake-dsn@sentry.io/fake-project'

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

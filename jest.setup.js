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

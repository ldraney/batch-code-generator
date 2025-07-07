import '@testing-library/jest-dom'

// Mock environment variables
process.env.WEBHOOK_SECRET = 'test-secret-123'
process.env.NODE_ENV = 'test'

// Mock Sentry
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
  startTransaction: jest.fn(() => ({
    setTag: jest.fn(),
    setStatus: jest.fn(),
    finish: jest.fn(),
  })),
}))

// Mock fetch for API tests
global.fetch = jest.fn()

// Console spy to reduce noise in tests
global.console = {
  ...console,
  log: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}

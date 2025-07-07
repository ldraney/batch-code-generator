import { captureWebhookError, captureBusinessMetric, trackCodeGeneration } from '../sentry'

describe('Sentry Utilities', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('captureWebhookError', () => {
    it('should handle errors gracefully when Sentry is not configured', () => {
      expect(() => {
        captureWebhookError(new Error('Test error'), {
          request: '/api/webhook',
          payload: { test: 'data' },
        })
      }).not.toThrow()
    })
  })

  describe('captureBusinessMetric', () => {
    it('should handle metrics gracefully when Sentry is not configured', () => {
      expect(() => {
        captureBusinessMetric('test_metric', 42, { unit: 'count' })
      }).not.toThrow()
    })
  })

  describe('trackCodeGeneration', () => {
    it('should track successful code generation', () => {
      expect(() => {
        trackCodeGeneration('create_component', {
          type: 'react',
          language: 'typescript',
          duration: 1500,
          success: true,
        })
      }).not.toThrow()
    })

    it('should track failed code generation', () => {
      expect(() => {
        trackCodeGeneration('create_component', {
          type: 'react',
          language: 'typescript',
          duration: 500,
          success: false,
          error: 'Invalid template',
        })
      }).not.toThrow()
    })
  })
})

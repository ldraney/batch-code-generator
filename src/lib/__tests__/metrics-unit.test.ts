/**
 * Unit tests for metrics functions (without testing Prometheus output)
 */

describe('Metrics Functions', () => {
  it('should export all required functions', () => {
    const metrics = require('../metrics')
    
    expect(typeof metrics.recordWebhookRequest).toBe('function')
    expect(typeof metrics.recordCodeGeneration).toBe('function')
    expect(typeof metrics.incrementActiveJobs).toBe('function')
    expect(typeof metrics.decrementActiveJobs).toBe('function')
    expect(typeof metrics.recordError).toBe('function')
    expect(typeof metrics.recordBatchJob).toBe('function')
    expect(metrics.register).toBeDefined()
  })

  it('should not throw when recording metrics', () => {
    const {
      recordWebhookRequest,
      recordCodeGeneration,
      incrementActiveJobs,
      decrementActiveJobs,
      recordError,
      recordBatchJob
    } = require('../metrics')
    
    expect(() => recordWebhookRequest('POST', '200', '/api/webhook')).not.toThrow()
    expect(() => recordCodeGeneration('component', true, 1.5)).not.toThrow()
    expect(() => incrementActiveJobs()).not.toThrow()
    expect(() => decrementActiveJobs()).not.toThrow()
    expect(() => recordError('test_error')).not.toThrow()
    expect(() => recordBatchJob('success', 'type', 10)).not.toThrow()
  })

  it('should handle edge cases gracefully', () => {
    const { recordWebhookRequest, recordCodeGeneration } = require('../metrics')
    
    // Test with edge case values
    expect(() => recordWebhookRequest('', '', '')).not.toThrow()
    expect(() => recordCodeGeneration('', false, 0)).not.toThrow()
    expect(() => recordCodeGeneration('test', true, -1)).not.toThrow()
  })
})

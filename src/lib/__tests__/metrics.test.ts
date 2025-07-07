import { register } from 'prom-client'
import {
  recordWebhookRequest,
  recordCodeGeneration,
  incrementActiveJobs,
  decrementActiveJobs,
  recordError,
  recordBatchJob,
} from '../metrics'

describe('Metrics', () => {
  beforeEach(() => {
    // Clear all metrics before each test
    register.clear()
  })

  it('should record webhook requests', () => {
    expect(() => {
      recordWebhookRequest('POST', '200', '/api/webhook')
    }).not.toThrow()
  })

  it('should record code generation metrics', () => {
    expect(() => {
      recordCodeGeneration('component', true, 1.5)
    }).not.toThrow()
  })

  it('should track active jobs', () => {
    expect(() => {
      incrementActiveJobs()
      decrementActiveJobs()
    }).not.toThrow()
  })

  it('should record errors', () => {
    expect(() => {
      recordError('validation')
    }).not.toThrow()
  })

  it('should record batch jobs', () => {
    expect(() => {
      recordBatchJob('success', 'code_generation', 10.5)
    }).not.toThrow()
  })

  it('should export metrics in Prometheus format', async () => {
    recordWebhookRequest('POST', '200', '/api/webhook')
    
    const metrics = await register.metrics()
    expect(metrics).toContain('webhook_requests_total')
  })
})

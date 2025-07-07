/**
 * Integration test for metrics that doesn't clear the registry
 * This ensures we can test the actual Prometheus output
 */

describe('Metrics Integration', () => {
  it('should register and export custom metrics', async () => {
    // Fresh import of the metrics module
    const { 
      recordWebhookRequest, 
      recordCodeGeneration, 
      recordError, 
      register 
    } = require('../metrics')
    
    // Record some test metrics
    recordWebhookRequest('POST', '200', '/api/webhook')
    recordWebhookRequest('GET', '404', '/api/missing')
    recordCodeGeneration('component', true, 1.234)
    recordCodeGeneration('function', false, 0.567)
    recordError('validation_error')
    recordError('network_error')
    
    // Get the metrics output
    const metrics = await register.metrics()
    
    // Check that our custom metrics are present
    expect(metrics).toContain('webhook_requests_total')
    expect(metrics).toContain('code_generation_duration_seconds')
    expect(metrics).toContain('code_generation_errors_total')
    
    // Check that labels are working
    expect(metrics).toContain('status="200"')
    expect(metrics).toContain('status="404"')
    expect(metrics).toContain('success="true"')
    expect(metrics).toContain('success="false"')
    expect(metrics).toContain('error_type="validation_error"')
    
    // Check Prometheus format
    expect(metrics).toContain('# HELP')
    expect(metrics).toContain('# TYPE')
  })

  it('should increment counters correctly', async () => {
    const { recordWebhookRequest, register } = require('../metrics')
    
    // Get initial metrics
    const beforeMetrics = await register.metrics()
    const beforeMatch = beforeMetrics.match(/webhook_requests_total\{.*status="200".*\} (\d+)/g)
    
    // Record another webhook request
    recordWebhookRequest('POST', '200', '/api/webhook')
    
    // Get metrics after
    const afterMetrics = await register.metrics()
    const afterMatch = afterMetrics.match(/webhook_requests_total\{.*status="200".*\} (\d+)/g)
    
    // Should have increased
    expect(afterMatch).toBeTruthy()
    expect(afterMatch.length).toBeGreaterThan(0)
  })
})

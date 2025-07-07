import request from 'supertest'

describe('Smoke Tests - Environment Validation', () => {
  const baseURL = process.env.TEST_BASE_URL || 'http://localhost:3000'
  
  describe('Critical Path Smoke Tests', () => {
    it('application should be responding', async () => {
      const response = await request(baseURL)
        .get('/api/health')
        .timeout(5000)
      
      expect(response.status).toBe(200)
      expect(response.body.status).toBe('healthy')
    })

    it('metrics endpoint should be accessible', async () => {
      const response = await request(baseURL)
        .get('/api/metrics')
        .timeout(5000)
      
      expect(response.status).toBe(200)
      expect(response.text).toContain('# HELP')
    })

    it('webhook should process requests', async () => {
      const response = await request(baseURL)
        .post('/api/webhook')
        .set('x-webhook-signature', 'dev-secret-123')
        .send({
          event: 'code_generation_request',
          data: { type: 'smoke-test' },
          timestamp: new Date().toISOString()
        })
        .timeout(5000)
      
      expect(response.status).toBe(200)
      expect(response.body.success).toBe(true)
    })

    it('main page should load', async () => {
      const response = await request(baseURL)
        .get('/')
        .timeout(5000)
      
      expect(response.status).toBe(200)
      expect(response.text).toContain('Batch Code Generator')
    })
  })

  describe('Environment Configuration', () => {
    it('should have correct environment variables', async () => {
      const response = await request(baseURL)
        .get('/api/health')
      
      const { environment } = response.body
      expect(['development', 'staging', 'production']).toContain(environment)
    })

    it('should have monitoring configured', async () => {
      const healthResponse = await request(baseURL).get('/api/health')
      const metricsResponse = await request(baseURL).get('/api/metrics')
      
      expect(healthResponse.status).toBe(200)
      expect(metricsResponse.status).toBe(200)
      
      // Sentry should be configured in production
      if (healthResponse.body.environment === 'production') {
        expect(healthResponse.body.sentry).toBe(true)
      }
    })
  })
})

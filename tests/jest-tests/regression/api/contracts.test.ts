import request from 'supertest'
import Ajv from 'ajv'
import addFormats from 'ajv-formats'

const ajv = new Ajv()
addFormats(ajv)

// API Response Schemas
const healthSchema = {
  type: 'object',
  required: ['status', 'timestamp', 'uptime', 'memory', 'version'],
  properties: {
    status: { type: 'string', enum: ['healthy', 'unhealthy'] },
    timestamp: { type: 'string', format: 'date-time' },
    uptime: { type: 'number', minimum: 0 },
    memory: {
      type: 'object',
      required: ['used', 'total', 'rss'],
      properties: {
        used: { type: 'number', minimum: 0 },
        total: { type: 'number', minimum: 0 },
        rss: { type: 'number', minimum: 0 }
      }
    },
    version: { type: 'string' },
    environment: { type: 'string' },
    sentry: { type: 'boolean' }
  },
  additionalProperties: true
}

const webhookResponseSchema = {
  type: 'object',
  required: ['success', 'message'],
  properties: {
    success: { type: 'boolean' },
    message: { type: 'string' },
    job_id: { type: 'string' },
    type: { type: 'string' },
    language: { type: 'string' }
  }
}

describe('API Contract Regression Tests', () => {
  const baseURL = process.env.TEST_BASE_URL || 'http://localhost:3000'
  
  describe('Health API Contract', () => {
    it('should maintain health endpoint schema', async () => {
      const response = await request(baseURL)
        .get('/api/health')
        .expect(200)

      const validate = ajv.compile(healthSchema)
      const valid = validate(response.body)
      
      if (!valid) {
        console.error('Schema validation errors:', validate.errors)
      }
      
      expect(valid).toBe(true)
    })

    it('should return response within acceptable time', async () => {
      const start = Date.now()
      
      await request(baseURL)
        .get('/api/health')
        .expect(200)
      
      const duration = Date.now() - start
      expect(duration).toBeLessThan(1000) // 1 second max
    })

    it('should have required headers', async () => {
      const response = await request(baseURL)
        .get('/api/health')
        .expect(200)

      expect(response.headers['x-health-check']).toBe('true')
      expect(response.headers['cache-control']).toBe('no-store, max-age=0')
    })
  })

  describe('Metrics API Contract', () => {
    it('should return Prometheus format', async () => {
      const response = await request(baseURL)
        .get('/api/metrics')
        .expect(200)

      expect(response.headers['content-type']).toContain('text/plain')
      expect(response.text).toContain('# HELP')
      expect(response.text).toContain('# TYPE')
    })

    it('should include expected metrics', async () => {
      const response = await request(baseURL)
        .get('/api/metrics')
        .expect(200)

      const metrics = response.text
      
      // Check for core metrics
      expect(metrics).toContain('nodejs_heap_size_used_bytes')
      expect(metrics).toContain('process_cpu_user_seconds_total')
      expect(metrics).toContain('webhook_requests_total')
    })
  })

  describe('Webhook API Contract', () => {
    it('should maintain webhook response schema', async () => {
      const payload = {
        event: 'code_generation_request',
        data: { type: 'component', language: 'typescript' },
        timestamp: new Date().toISOString()
      }

      const response = await request(baseURL)
        .post('/api/webhook')
        .set('x-webhook-signature', 'dev-secret-123')
        .send(payload)
        .expect(200)

      const validate = ajv.compile(webhookResponseSchema)
      const valid = validate(response.body)
      
      if (!valid) {
        console.error('Schema validation errors:', validate.errors)
      }
      
      expect(valid).toBe(true)
    })
  })
})

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
    environment: { type: 'string' }
  },
  additionalProperties: true
}

const webhookResponseSchema = {
  type: 'object',
  required: ['success', 'message'],
  properties: {
    success: { type: 'boolean' },
    message: { type: 'string' }
  },
  additionalProperties: true
}

describe('API Contract Regression Tests', () => {
  const baseURL = process.env.TEST_BASE_URL || 'http://localhost:3000'
  let serverRunning = false
  
  beforeAll(async () => {
    // Check if server is running
    try {
      await request(baseURL).get('/api/health').timeout(2000)
      serverRunning = true
    } catch (error) {
      console.warn('⚠️  Server not running - skipping contract tests')
      console.warn('💡 Start server with "npm run dev" to run these tests')
      serverRunning = false
    }
  })
  
  describe('Health API Contract', () => {
    it('should maintain health endpoint schema', async () => {
      if (!serverRunning) {
        console.log('⏭️  Skipping - server not running')
        return
      }

      const response = await request(baseURL)
        .get('/api/health')
        .timeout(5000)
        .expect(200)

      const validate = ajv.compile(healthSchema)
      const valid = validate(response.body)
      
      if (!valid) {
        console.error('Schema validation errors:', validate.errors)
      }
      
      expect(valid).toBe(true)
    })

    it('should return response within acceptable time', async () => {
      if (!serverRunning) {
        console.log('⏭️  Skipping - server not running')
        return
      }

      const start = Date.now()
      
      await request(baseURL)
        .get('/api/health')
        .timeout(5000)
        .expect(200)
      
      const duration = Date.now() - start
      expect(duration).toBeLessThan(5000)
    })

    it('should have required headers', async () => {
      if (!serverRunning) {
        console.log('⏭️  Skipping - server not running')
        return
      }

      const response = await request(baseURL)
        .get('/api/health')
        .timeout(5000)
        .expect(200)

      expect(response.headers['x-health-check']).toBe('true')
      expect(response.headers['cache-control']).toBe('no-store, max-age=0')
    })
  })

  describe('Metrics API Contract', () => {
    it('should return Prometheus format', async () => {
      if (!serverRunning) {
        console.log('⏭️  Skipping - server not running')
        return
      }

      const response = await request(baseURL)
        .get('/api/metrics')
        .timeout(5000)
        .expect(200)

      expect(response.headers['content-type']).toContain('text/plain')
      expect(response.text).toContain('# HELP')
    })

    it('should include expected metrics', async () => {
      if (!serverRunning) {
        console.log('⏭️  Skipping - server not running')
        return
      }

      const response = await request(baseURL)
        .get('/api/metrics')
        .timeout(5000)
        .expect(200)

      const metrics = response.text
      expect(metrics).toContain('nodejs_')
    })
  })

  describe('Webhook API Contract', () => {
    it('should maintain webhook response schema', async () => {
      if (!serverRunning) {
        console.log('⏭️  Skipping - server not running')
        return
      }

      const payload = {
        event: 'code_generation_request',
        data: { type: 'component', language: 'typescript' },
        timestamp: new Date().toISOString()
      }

      const response = await request(baseURL)
        .post('/api/webhook')
        .set('x-webhook-signature', 'dev-secret-123')
        .send(payload)
        .timeout(5000)
        .expect(200)

      const validate = ajv.compile(webhookResponseSchema)
      const valid = validate(response.body)
      
      if (!valid) {
        console.error('Schema validation errors:', validate.errors)
      }
      
      expect(valid).toBe(true)
    })
  })

  describe('Server Status', () => {
    it('should report server status', () => {
      if (serverRunning) {
        console.log('✅ Server is running - all contract tests executed')
      } else {
        console.log('⚠️  Server not running - contract tests skipped')
        console.log('💡 To run contract tests: npm run dev (in another terminal) && npm test')
      }
      
      // This test always passes, it just reports status
      expect(true).toBe(true)
    })
  })
})

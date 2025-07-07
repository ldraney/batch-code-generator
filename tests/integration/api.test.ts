import request from 'supertest'
import { createServer } from 'http'
import next from 'next'

const app = next({ dev: false, dir: '.' })
const handle = app.getRequestHandler()

describe('API Integration Tests', () => {
  let server: any

  beforeAll(async () => {
    await app.prepare()
    server = createServer((req, res) => handle(req, res))
  })

  afterAll(() => {
    server?.close()
  })

  describe('Health Endpoint', () => {
    it('GET /api/health returns healthy status', async () => {
      const response = await request(server)
        .get('/api/health')
        .expect(200)

      expect(response.body.status).toBe('healthy')
      expect(response.headers['x-health-check']).toBe('true')
    })

    it('HEAD /api/health returns 200', async () => {
      await request(server)
        .head('/api/health')
        .expect(200)
    })
  })

  describe('Metrics Endpoint', () => {
    it('GET /api/metrics returns Prometheus format', async () => {
      const response = await request(server)
        .get('/api/metrics')
        .expect(200)

      expect(response.headers['content-type']).toContain('text/plain')
      expect(response.text).toContain('# HELP')
    })
  })

  describe('Webhook Endpoint', () => {
    it('POST /api/webhook with valid payload succeeds', async () => {
      const payload = {
        event: 'code_generation_request',
        data: {
          type: 'component',
          language: 'typescript',
        },
        timestamp: new Date().toISOString(),
      }

      const response = await request(server)
        .post('/api/webhook')
        .set('x-webhook-signature', 'test-secret-123')
        .send(payload)
        .expect(200)

      expect(response.body.success).toBe(true)
    })

    it('POST /api/webhook without signature fails', async () => {
      const payload = {
        event: 'code_generation_request',
        data: { type: 'component' },
        timestamp: new Date().toISOString(),
      }

      await request(server)
        .post('/api/webhook')
        .send(payload)
        .expect(401)
    })
  })
})

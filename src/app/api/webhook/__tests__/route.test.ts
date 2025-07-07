import { GET, POST } from '../route'
import { NextRequest } from 'next/server'

// Mock metrics
jest.mock('@/lib/metrics', () => ({
  recordWebhookRequest: jest.fn(),
  recordCodeGeneration: jest.fn(),
  incrementActiveJobs: jest.fn(),
  decrementActiveJobs: jest.fn(),
  recordError: jest.fn(),
}))

describe('/api/webhook', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('GET', () => {
    it('should return webhook info', async () => {
      const response = await GET()
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.message).toBe('Webhook endpoint is active')
      expect(data.supportedEvents).toContain('code_generation_request')
      expect(data.supportedEvents).toContain('batch_job_request')
    })
  })

  describe('POST', () => {
    const createRequest = (payload: any, signature?: string) => {
      return new NextRequest('http://localhost/api/webhook', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-webhook-signature': signature || 'test-secret-123',
        },
        body: JSON.stringify(payload),
      })
    }

    it('should handle valid code generation request', async () => {
      const payload = {
        event: 'code_generation_request',
        data: {
          type: 'component',
          language: 'typescript',
        },
        timestamp: new Date().toISOString(),
      }

      const request = createRequest(payload)
      const response = await POST(request)
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.success).toBe(true)
      expect(data.message).toBe('Code generation started')
      expect(data).toHaveProperty('job_id')
    })

    it('should handle valid batch job request', async () => {
      const payload = {
        event: 'batch_job_request',
        data: {
          type: 'batch',
          batch_id: 'test-batch-123',
        },
        timestamp: new Date().toISOString(),
      }

      const request = createRequest(payload)
      const response = await POST(request)
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.success).toBe(true)
      expect(data.message).toBe('Batch job queued')
      expect(data).toHaveProperty('batch_id')
    })

    it('should reject invalid signature', async () => {
      const payload = {
        event: 'code_generation_request',
        data: { type: 'component' },
        timestamp: new Date().toISOString(),
      }

      const request = createRequest(payload, 'invalid-signature')
      const response = await POST(request)

      expect(response.status).toBe(401)
    })

    it('should reject invalid payload', async () => {
      const payload = {
        event: 'invalid_event',
        // missing required data
        timestamp: new Date().toISOString(),
      }

      const request = createRequest(payload)
      const response = await POST(request)

      expect(response.status).toBe(500)
    })
  })
})

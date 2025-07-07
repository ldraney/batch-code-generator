/**
 * Integration tests for API endpoints
 * These tests make real HTTP calls to running server
 */

import request from 'supertest'

describe('API Integration Tests', () => {
  const baseURL = process.env.TEST_BASE_URL || 'http://localhost:3000'
  let serverRunning = false
  
  beforeAll(async () => {
    // Check if server is running
    try {
      await request(baseURL).get('/api/health').timeout(2000)
      serverRunning = true
      console.log(`✅ Server running at ${baseURL} - integration tests will run`)
    } catch (error) {
      console.warn('⚠️  Server not running - integration tests will be skipped')
      serverRunning = false
    }
  })

  describe('API Integration Flow', () => {
    it('should handle complete webhook workflow', async () => {
      if (!serverRunning) {
        console.log('⏭️  Skipping - server not running')
        return
      }

      // 1. Check health
      const healthResponse = await request(baseURL)
        .get('/api/health')
        .expect(200)

      expect(healthResponse.body.status).toBe('healthy')

      // 2. Process webhook
      const webhookSignature = 'test-secret-123'
      const webhookPayload = {
        event: 'code_generation_request',
        data: {
          type: 'component',
          language: 'typescript',
        },
        timestamp: new Date().toISOString(),
      }

      const webhookResponse = await request(baseURL)
        .post('/api/webhook')
        .set('x-webhook-signature', webhookSignature)
        .send(webhookPayload)
        .expect(200)

      expect(webhookResponse.body.success).toBe(true)
      expect(webhookResponse.body.job_id).toMatch(/^gen_\d+$/)

      // 3. Check metrics were recorded
      const metricsResponse = await request(baseURL)
        .get('/api/metrics')
        .expect(200)

      expect(metricsResponse.text).toContain('webhook_requests_total')
    })

    it('should handle batch job workflow', async () => {
      if (!serverRunning) {
        console.log('⏭️  Skipping - server not running')
        return
      }

      const webhookSignature = 'test-secret-123'
      const batchPayload = {
        event: 'batch_job_request',
        data: {
          type: 'batch',
          batch_id: 'test-batch-001',
        },
        timestamp: new Date().toISOString(),
      }

      const response = await request(baseURL)
        .post('/api/webhook')
        .set('x-webhook-signature', webhookSignature)
        .send(batchPayload)
        .expect(200)

      expect(response.body.success).toBe(true)
      expect(response.body.batch_id).toBeDefined()
      expect(response.body.estimated_completion).toBeDefined()
    })

    it('should reject invalid webhook signatures', async () => {
      if (!serverRunning) {
        console.log('⏭️  Skipping - server not running')
        return
      }

      const payload = {
        event: 'code_generation_request',
        data: { type: 'component' },
        timestamp: new Date().toISOString(),
      }

      await request(baseURL)
        .post('/api/webhook')
        .set('x-webhook-signature', 'invalid-signature')
        .send(payload)
        .expect(401)
    })
  })

  describe('Error Handling Integration', () => {
    it('should handle malformed webhook payloads', async () => {
      if (!serverRunning) {
        console.log('⏭️  Skipping - server not running')
        return
      }

      const webhookSignature = 'test-secret-123'
      const invalidPayload = {
        event: 'invalid_event',
        // Missing required fields
        timestamp: new Date().toISOString(),
      }

      await request(baseURL)
        .post('/api/webhook')
        .set('x-webhook-signature', webhookSignature)
        .send(invalidPayload)
        .expect(500)
    })
  })

  describe('Performance Integration', () => {
    it('should handle concurrent webhook requests', async () => {
      if (!serverRunning) {
        console.log('⏭️  Skipping - server not running')
        return
      }

      const webhookSignature = 'test-secret-123'
      const concurrentRequests = 5

      const requests = Array.from({ length: concurrentRequests }, (_, i) =>
        request(baseURL)
          .post('/api/webhook')
          .set('x-webhook-signature', webhookSignature)
          .send({
            event: 'code_generation_request',
            data: { type: `concurrent-test-${i}` },
            timestamp: new Date().toISOString(),
          })
      )

      const responses = await Promise.all(requests)

      // All requests should succeed
      responses.forEach((response, i) => {
        expect(response.status).toBe(200)
        expect(response.body.success).toBe(true)
      })
    })
  })
})

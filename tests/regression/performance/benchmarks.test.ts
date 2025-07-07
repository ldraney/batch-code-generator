import request from 'supertest'
import fs from 'fs/promises'
import path from 'path'

interface PerformanceBenchmark {
  endpoint: string
  method: string
  maxResponseTime: number
  maxMemoryIncrease: number
}

const benchmarks: PerformanceBenchmark[] = [
  { endpoint: '/api/health', method: 'GET', maxResponseTime: 100, maxMemoryIncrease: 1 },
  { endpoint: '/api/metrics', method: 'GET', maxResponseTime: 500, maxMemoryIncrease: 2 },
  { endpoint: '/api/webhook', method: 'POST', maxResponseTime: 200, maxMemoryIncrease: 5 }
]

describe('Performance Regression Tests', () => {
  const baseURL = process.env.TEST_BASE_URL || 'http://localhost:3000'
  const baselinePath = path.join(__dirname, '../../baselines/performance')

  beforeAll(async () => {
    // Ensure baseline directory exists
    await fs.mkdir(baselinePath, { recursive: true })
  })

  describe('Response Time Regression', () => {
    benchmarks.forEach(({ endpoint, method, maxResponseTime }) => {
      it(`${method} ${endpoint} should respond within ${maxResponseTime}ms`, async () => {
        const measurements: number[] = []
        
        // Take 10 measurements
        for (let i = 0; i < 10; i++) {
          const start = Date.now()
          
          if (method === 'GET') {
            await request(baseURL).get(endpoint)
          } else if (method === 'POST' && endpoint === '/api/webhook') {
            await request(baseURL)
              .post(endpoint)
              .set('x-webhook-signature', 'dev-secret-123')
              .send({
                event: 'code_generation_request',
                data: { type: 'test' },
                timestamp: new Date().toISOString()
              })
          }
          
          measurements.push(Date.now() - start)
        }
        
        const avgResponseTime = measurements.reduce((a, b) => a + b) / measurements.length
        const p95ResponseTime = measurements.sort()[Math.floor(measurements.length * 0.95)]
        
        console.log(`${endpoint} - Avg: ${avgResponseTime}ms, P95: ${p95ResponseTime}ms`)
        
        // Both average and P95 should be under threshold
        expect(avgResponseTime).toBeLessThan(maxResponseTime)
        expect(p95ResponseTime).toBeLessThan(maxResponseTime * 2)
      })
    })
  })

  describe('Memory Usage Regression', () => {
    it('should not have significant memory leaks', async () => {
      const initialMemory = process.memoryUsage().heapUsed
      
      // Make 100 requests to stress test
      const requests = Array.from({ length: 100 }, () => 
        request(baseURL).get('/api/health')
      )
      
      await Promise.all(requests)
      
      // Force garbage collection if available
      if (global.gc) {
        global.gc()
      }
      
      const finalMemory = process.memoryUsage().heapUsed
      const memoryIncrease = (finalMemory - initialMemory) / 1024 / 1024 // MB
      
      console.log(`Memory increase: ${memoryIncrease.toFixed(2)}MB`)
      
      // Should not increase by more than 10MB
      expect(memoryIncrease).toBeLessThan(10)
    })
  })

  describe('Concurrent Request Handling', () => {
    it('should handle concurrent webhook requests', async () => {
      const concurrentRequests = 20
      const requests = Array.from({ length: concurrentRequests }, (_, i) =>
        request(baseURL)
          .post('/api/webhook')
          .set('x-webhook-signature', 'dev-secret-123')
          .send({
            event: 'code_generation_request',
            data: { type: `test-${i}` },
            timestamp: new Date().toISOString()
          })
      )
      
      const start = Date.now()
      const responses = await Promise.all(requests)
      const duration = Date.now() - start
      
      // All requests should succeed
      responses.forEach((response, i) => {
        expect(response.status).toBe(200)
        expect(response.body.success).toBe(true)
      })
      
      // Should complete within reasonable time
      expect(duration).toBeLessThan(5000) // 5 seconds for 20 requests
      
      console.log(`${concurrentRequests} concurrent requests completed in ${duration}ms`)
    })
  })
})

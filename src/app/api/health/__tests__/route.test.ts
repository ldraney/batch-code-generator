import { GET, HEAD } from '../route'
import { NextRequest } from 'next/server'

describe('/api/health', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('GET', () => {
    it('should return healthy status', async () => {
      const response = await GET()
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.status).toBe('healthy')
      expect(data).toHaveProperty('timestamp')
      expect(data).toHaveProperty('uptime')
      expect(data).toHaveProperty('memory')
      expect(data).toHaveProperty('version')
    })

    it('should include system information', async () => {
      const response = await GET()
      const data = await response.json()

      expect(data.memory).toHaveProperty('used')
      expect(data.memory).toHaveProperty('total')
      expect(data.memory).toHaveProperty('rss')
      expect(data).toHaveProperty('platform')
      expect(data).toHaveProperty('nodeVersion')
    })

    it('should have correct headers', async () => {
      const response = await GET()
      
      expect(response.headers.get('Cache-Control')).toBe('no-store, max-age=0')
      expect(response.headers.get('X-Health-Check')).toBe('true')
    })
  })

  describe('HEAD', () => {
    it('should return 200 status', async () => {
      const response = await HEAD()
      
      expect(response.status).toBe(200)
      expect(response.headers.get('X-Health-Check')).toBe('true')
    })
  })
})

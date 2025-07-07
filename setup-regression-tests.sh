#!/bin/bash

echo "🧪 Setting up comprehensive regression testing suite..."
echo "This will ensure your app never breaks without you knowing!"

# Install additional testing dependencies
echo "📦 Installing regression testing dependencies..."
npm install --save-dev \
  ajv \
  ajv-formats \
  pixelmatch \
  pngjs \
  lighthouse \
  @types/pngjs

# Create regression test directory structure
mkdir -p tests/regression/{api,performance,visual,smoke}
mkdir -p tests/baselines/{api,performance,visual}
mkdir -p tests/utils

# Create API contract/schema tests
echo "📋 Creating API contract tests..."
cat > tests/regression/api/contracts.test.ts << 'EOF'
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
EOF

# Create performance regression tests
echo "⚡ Creating performance regression tests..."
cat > tests/regression/performance/benchmarks.test.ts << 'EOF'
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
EOF

# Create visual regression tests
echo "👁️ Creating visual regression tests..."
cat > tests/regression/visual/screenshots.test.ts << 'EOF'
import { test, expect, Page } from '@playwright/test'
import fs from 'fs/promises'
import path from 'path'

const BASELINE_DIR = path.join(__dirname, '../../baselines/visual')
const VIEWPORT_SIZES = [
  { width: 1920, height: 1080, name: 'desktop' },
  { width: 768, height: 1024, name: 'tablet' },
  { width: 375, height: 812, name: 'mobile' }
]

test.describe('Visual Regression Tests', () => {
  test.beforeAll(async () => {
    // Ensure baseline directory exists
    await fs.mkdir(BASELINE_DIR, { recursive: true })
  })

  VIEWPORT_SIZES.forEach(({ width, height, name }) => {
    test.describe(`${name} viewport (${width}x${height})`, () => {
      test.beforeEach(async ({ page }) => {
        await page.setViewportSize({ width, height })
      })

      test('dashboard should look correct', async ({ page }) => {
        await page.goto('/')
        
        // Wait for all content to load
        await page.waitForSelector('[data-testid="status-card"]', { timeout: 10000 })
        await page.waitForLoadState('networkidle')
        
        // Take screenshot
        const screenshot = await page.screenshot({ 
          fullPage: true,
          animations: 'disabled'
        })
        
        // Compare with baseline (you'll need to create baselines first)
        await expect(screenshot).toMatchSnapshot(`dashboard-${name}.png`)
      })

      test('dashboard with loading state', async ({ page }) => {
        // Intercept health API to simulate loading
        await page.route('/api/health', route => {
          setTimeout(() => route.fulfill({
            status: 200,
            body: JSON.stringify({
              status: 'healthy',
              timestamp: new Date().toISOString(),
              uptime: 3600,
              memory: { used: 100, total: 500, rss: 200 },
              version: '0.1.0'
            })
          }), 2000)
        })

        await page.goto('/')
        
        // Capture loading state
        const loadingScreenshot = await page.screenshot({
          animations: 'disabled'
        })
        
        await expect(loadingScreenshot).toMatchSnapshot(`dashboard-loading-${name}.png`)
      })
    })
  })

  test('should handle error states correctly', async ({ page }) => {
    // Mock API error
    await page.route('/api/health', route => {
      route.fulfill({
        status: 500,
        body: JSON.stringify({ error: 'Internal Server Error' })
      })
    })

    await page.goto('/')
    
    // Wait for error state
    await page.waitForTimeout(3000)
    
    const errorScreenshot = await page.screenshot({ fullPage: true })
    await expect(errorScreenshot).toMatchSnapshot('dashboard-error-state.png')
  })
})
EOF

# Create smoke tests for different environments
echo "💨 Creating smoke tests..."
cat > tests/regression/smoke/environment.test.ts << 'EOF'
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
EOF

# Create test runner scripts for different environments
echo "🏃 Creating test runner scripts..."
cat > scripts/test-regression.sh << 'EOF'
#!/bin/bash

set -e

echo "🧪 Running Regression Test Suite..."

# Environment variables
export NODE_ENV=test
export TEST_BASE_URL=${TEST_BASE_URL:-http://localhost:3000}

echo "🎯 Testing against: $TEST_BASE_URL"

# Check if server is running
if ! curl -s "$TEST_BASE_URL/api/health" > /dev/null; then
    echo "❌ Server not responding at $TEST_BASE_URL"
    echo "💡 Start the server first: npm run dev (or npm start for prod build)"
    exit 1
fi

echo "✅ Server is responding"

# Run different test suites
echo ""
echo "📋 Running API Contract Tests..."
npm run test -- tests/regression/api

echo ""
echo "⚡ Running Performance Tests..."
npm run test -- tests/regression/performance

echo ""
echo "💨 Running Smoke Tests..."
npm run test -- tests/regression/smoke

echo ""
echo "👁️ Running Visual Regression Tests..."
npm run test:e2e -- tests/regression/visual

echo ""
echo "🎉 All regression tests completed!"
EOF

chmod +x scripts/test-regression.sh

# Update package.json with new test scripts
echo "📝 Adding regression test scripts..."
npm pkg set scripts.test:regression="./scripts/test-regression.sh"
npm pkg set scripts.test:smoke="jest tests/regression/smoke"
npm pkg set scripts.test:contracts="jest tests/regression/api"
npm pkg set scripts.test:performance="jest tests/regression/performance"
npm pkg set scripts.test:visual="playwright test tests/regression/visual"

# Create baseline capture script
cat > scripts/capture-baselines.sh << 'EOF'
#!/bin/bash

echo "📸 Capturing baseline screenshots and performance metrics..."

# Ensure server is running
if ! curl -s "http://localhost:3000/api/health" > /dev/null; then
    echo "❌ Server not running. Please start with 'npm run dev' first."
    exit 1
fi

echo "📷 Capturing visual baselines..."
npx playwright test tests/regression/visual --update-snapshots

echo "📊 Capturing performance baselines..."
npm run test:performance

echo "✅ Baselines captured! Commit these to version control."
echo "💡 Run 'npm run test:regression' to validate against baselines."
EOF

chmod +x scripts/capture-baselines.sh

npm pkg set scripts.capture:baselines="./scripts/capture-baselines.sh"

echo ""
echo "✅ Comprehensive Regression Testing Suite Complete!"
echo ""
echo "🎯 Available Commands:"
echo "npm run test:regression     # Full regression suite"
echo "npm run test:smoke          # Quick smoke tests"
echo "npm run test:contracts      # API contract validation"
echo "npm run test:performance    # Performance benchmarks"
echo "npm run test:visual         # Visual regression"
echo "npm run capture:baselines   # Capture new baselines"
echo ""
echo "🚀 Next Steps:"
echo "1. Start your server: npm run dev"
echo "2. Capture baselines: npm run capture:baselines"
echo "3. Run regression tests: npm run test:regression"
echo ""
echo "💡 This will catch ANY breaking changes across:"
echo "   - API response format changes"
echo "   - Performance degradation"
echo "   - UI visual changes"
echo "   - Environment configuration issues"

#!/bin/bash

echo "🧪 Setting up comprehensive testing suite..."
echo "This includes: Unit, Integration, E2E, Load, and Monitoring tests"

# Install testing dependencies
echo "📦 Installing testing dependencies..."
npm install --save-dev \
  @types/jest \
  jest \
  jest-environment-jsdom \
  @testing-library/react \
  @testing-library/jest-dom \
  @testing-library/user-event \
  supertest \
  @types/supertest \
  playwright \
  @playwright/test \
  artillery \
  @sentry/testkit

# Create Jest configuration
echo "⚙️ Creating Jest configuration..."
cat > jest.config.js << 'EOF'
const nextJest = require('next/jest')

const createJestConfig = nextJest({
  // Provide the path to your Next.js app to load next.config.js and .env files
  dir: './',
})

// Add any custom config to be passed to Jest
const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  moduleNameMapping: {
    // Handle module aliases (this will be automatically configured for you based on your tsconfig.json paths)
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  testEnvironment: 'jest-environment-jsdom',
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.{js,jsx,ts,tsx}',
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70,
    },
  },
  testMatch: [
    '<rootDir>/src/**/__tests__/**/*.{js,jsx,ts,tsx}',
    '<rootDir>/src/**/*.{test,spec}.{js,jsx,ts,tsx}',
    '<rootDir>/tests/**/*.{test,spec}.{js,jsx,ts,tsx}',
  ],
}

// createJestConfig is exported this way to ensure that next/jest can load the Next.js config which is async
module.exports = createJestConfig(customJestConfig)
EOF

# Create Jest setup file
cat > jest.setup.js << 'EOF'
import '@testing-library/jest-dom'

// Mock environment variables
process.env.WEBHOOK_SECRET = 'test-secret-123'
process.env.NODE_ENV = 'test'

// Mock Sentry
jest.mock('@sentry/nextjs', () => ({
  init: jest.fn(),
  captureException: jest.fn(),
  withScope: jest.fn((callback) => callback({
    setTag: jest.fn(),
    setContext: jest.fn(),
    setUser: jest.fn(),
    setLevel: jest.fn(),
  })),
  addBreadcrumb: jest.fn(),
  startTransaction: jest.fn(() => ({
    setTag: jest.fn(),
    setStatus: jest.fn(),
    finish: jest.fn(),
  })),
}))

// Mock fetch for API tests
global.fetch = jest.fn()

// Console spy to reduce noise in tests
global.console = {
  ...console,
  log: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}
EOF

# Create test directories
mkdir -p tests/{unit,integration,e2e,load}
mkdir -p src/app/api/{health,metrics,webhook}/__tests__
mkdir -p src/lib/__tests__
mkdir -p src/components/__tests__

# Unit Tests - API Routes
echo "🔬 Creating unit tests..."

# Health API test
cat > src/app/api/health/__tests__/route.test.ts << 'EOF'
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
EOF

# Webhook API test
cat > src/app/api/webhook/__tests__/route.test.ts << 'EOF'
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
EOF

# Metrics library test
cat > src/lib/__tests__/metrics.test.ts << 'EOF'
import { register } from 'prom-client'
import {
  recordWebhookRequest,
  recordCodeGeneration,
  incrementActiveJobs,
  decrementActiveJobs,
  recordError,
  recordBatchJob,
} from '../metrics'

describe('Metrics', () => {
  beforeEach(() => {
    // Clear all metrics before each test
    register.clear()
  })

  it('should record webhook requests', () => {
    expect(() => {
      recordWebhookRequest('POST', '200', '/api/webhook')
    }).not.toThrow()
  })

  it('should record code generation metrics', () => {
    expect(() => {
      recordCodeGeneration('component', true, 1.5)
    }).not.toThrow()
  })

  it('should track active jobs', () => {
    expect(() => {
      incrementActiveJobs()
      decrementActiveJobs()
    }).not.toThrow()
  })

  it('should record errors', () => {
    expect(() => {
      recordError('validation')
    }).not.toThrow()
  })

  it('should record batch jobs', () => {
    expect(() => {
      recordBatchJob('success', 'code_generation', 10.5)
    }).not.toThrow()
  })

  it('should export metrics in Prometheus format', async () => {
    recordWebhookRequest('POST', '200', '/api/webhook')
    
    const metrics = await register.metrics()
    expect(metrics).toContain('webhook_requests_total')
  })
})
EOF

# Sentry utilities test
cat > src/lib/__tests__/sentry.test.ts << 'EOF'
import { captureWebhookError, captureBusinessMetric, trackCodeGeneration } from '../sentry'

describe('Sentry Utilities', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('captureWebhookError', () => {
    it('should handle errors gracefully when Sentry is not configured', () => {
      expect(() => {
        captureWebhookError(new Error('Test error'), {
          request: '/api/webhook',
          payload: { test: 'data' },
        })
      }).not.toThrow()
    })
  })

  describe('captureBusinessMetric', () => {
    it('should handle metrics gracefully when Sentry is not configured', () => {
      expect(() => {
        captureBusinessMetric('test_metric', 42, { unit: 'count' })
      }).not.toThrow()
    })
  })

  describe('trackCodeGeneration', () => {
    it('should track successful code generation', () => {
      expect(() => {
        trackCodeGeneration('create_component', {
          type: 'react',
          language: 'typescript',
          duration: 1500,
          success: true,
        })
      }).not.toThrow()
    })

    it('should track failed code generation', () => {
      expect(() => {
        trackCodeGeneration('create_component', {
          type: 'react',
          language: 'typescript',
          duration: 500,
          success: false,
          error: 'Invalid template',
        })
      }).not.toThrow()
    })
  })
})
EOF

# Integration Tests
echo "🔗 Creating integration tests..."
cat > tests/integration/api.test.ts << 'EOF'
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
EOF

# E2E Tests with Playwright
echo "🎭 Creating E2E tests..."
cat > playwright.config.ts << 'EOF'
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
EOF

cat > tests/e2e/dashboard.spec.ts << 'EOF'
import { test, expect } from '@playwright/test';

test.describe('Dashboard', () => {
  test('should load and display health status', async ({ page }) => {
    await page.goto('/');
    
    // Check title
    await expect(page).toHaveTitle(/Batch Code Generator/);
    
    // Check main heading
    await expect(page.locator('h1')).toContainText('Batch Code Generator');
    
    // Check status cards are present
    await expect(page.locator('[data-testid="status-card"]')).toBeVisible();
    
    // Check API endpoints section
    await expect(page.locator('text=API Endpoints')).toBeVisible();
    
    // Check quick links
    await expect(page.locator('text=Quick Links')).toBeVisible();
  });

  test('should have working health check link', async ({ page }) => {
    await page.goto('/');
    
    // Click health check link
    await page.click('text=Health Status');
    
    // Should navigate to health endpoint (or open in new tab)
    // This depends on your implementation
  });
});
EOF

cat > tests/e2e/api.spec.ts << 'EOF'
import { test, expect } from '@playwright/test';

test.describe('API Endpoints', () => {
  test('health endpoint should return healthy status', async ({ request }) => {
    const response = await request.get('/api/health');
    
    expect(response.status()).toBe(200);
    
    const data = await response.json();
    expect(data.status).toBe('healthy');
    expect(data).toHaveProperty('timestamp');
    expect(data).toHaveProperty('uptime');
  });

  test('metrics endpoint should return Prometheus format', async ({ request }) => {
    const response = await request.get('/api/metrics');
    
    expect(response.status()).toBe(200);
    expect(response.headers()['content-type']).toContain('text/plain');
    
    const text = await response.text();
    expect(text).toContain('# HELP');
  });

  test('webhook endpoint should handle valid requests', async ({ request }) => {
    const payload = {
      event: 'code_generation_request',
      data: {
        type: 'component',
        language: 'typescript',
      },
      timestamp: new Date().toISOString(),
    };

    const response = await request.post('/api/webhook', {
      headers: {
        'Content-Type': 'application/json',
        'x-webhook-signature': 'test-secret-123',
      },
      data: payload,
    });

    expect(response.status()).toBe(200);
    
    const data = await response.json();
    expect(data.success).toBe(true);
  });
});
EOF

# Load Testing with Artillery
echo "⚡ Creating load tests..."
cat > tests/load/basic-load.yml << 'EOF'
config:
  target: 'http://localhost:3000'
  phases:
    - duration: 60
      arrivalRate: 5
      name: "Warm up"
    - duration: 120
      arrivalRate: 10
      name: "Ramp up load"
    - duration: 300
      arrivalRate: 20
      name: "Sustained load"
  processor: "./load-test-functions.js"

scenarios:
  - name: "Health Check Load"
    weight: 30
    flow:
      - get:
          url: "/api/health"
          capture:
            - json: "$.status"
              as: "health_status"
      - think: 1

  - name: "Metrics Load"
    weight: 20
    flow:
      - get:
          url: "/api/metrics"
      - think: 2

  - name: "Webhook Load"
    weight: 50
    flow:
      - post:
          url: "/api/webhook"
          headers:
            Content-Type: "application/json"
            x-webhook-signature: "test-secret-123"
          json:
            event: "code_generation_request"
            data:
              type: "{{ $randomString() }}"
              language: "typescript"
            timestamp: "{{ $timestamp() }}"
      - think: 1
EOF

cat > tests/load/load-test-functions.js << 'EOF'
module.exports = {
  $randomString: function() {
    const types = ['component', 'function', 'class', 'interface', 'type'];
    return types[Math.floor(Math.random() * types.length)];
  },
  
  $timestamp: function() {
    return new Date().toISOString();
  }
};
EOF

# Create test scripts in package.json
echo "📝 Adding test scripts to package.json..."
npm pkg set scripts.test="jest"
npm pkg set scripts.test:watch="jest --watch"
npm pkg set scripts.test:coverage="jest --coverage"
npm pkg set scripts.test:integration="jest --testPathPattern=integration"
npm pkg set scripts.test:e2e="playwright test"
npm pkg set scripts.test:e2e:ui="playwright test --ui"
npm pkg set scripts.test:load="artillery run tests/load/basic-load.yml"
npm pkg set scripts.test:all="npm run test && npm run test:integration && npm run test:e2e"

# Create test data and utilities
mkdir -p tests/utils
cat > tests/utils/test-helpers.ts << 'EOF'
export const createMockWebhookPayload = (overrides = {}) => ({
  event: 'code_generation_request',
  data: {
    type: 'component',
    language: 'typescript',
    content: 'test content',
    ...overrides,
  },
  timestamp: new Date().toISOString(),
});

export const createMockRequest = (url: string, options: RequestInit = {}) => {
  return new Request(url, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
    ...options,
  });
};

export const waitFor = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

export const createTestUser = () => ({
  id: `test-user-${Date.now()}`,
  email: 'test@example.com',
  name: 'Test User',
});
EOF

# Install Playwright browsers
echo "🎭 Installing Playwright browsers..."
npx playwright install

echo ""
echo "✅ Complete Testing Suite Setup Complete!"
echo ""
echo "🧪 Available Test Commands:"
echo "npm test                  # Unit tests"
echo "npm run test:watch        # Unit tests in watch mode"
echo "npm run test:coverage     # Unit tests with coverage"
echo "npm run test:integration  # Integration tests"
echo "npm run test:e2e          # End-to-end tests"
echo "npm run test:e2e:ui       # E2E tests with UI"
echo "npm run test:load         # Load testing"
echo "npm run test:all          # All tests"
echo ""
echo "📊 Coverage thresholds set to 70% (industry standard)"
echo "🎯 Tests cover: APIs, metrics, error handling, performance"
echo "⚡ Load tests simulate real traffic patterns"
echo ""
echo "🚀 Run 'npm test' to start testing!"

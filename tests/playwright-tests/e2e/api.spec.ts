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

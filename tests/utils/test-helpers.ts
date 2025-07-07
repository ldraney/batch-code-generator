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

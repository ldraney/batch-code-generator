describe('Smoke Tests - Basic Environment', () => {
  it('should have test environment configured', () => {
    expect(process.env.NODE_ENV).toBe('test')
    expect(process.env.WEBHOOK_SECRET).toBe('test-secret-123')
  })

  it('should have basic Node.js functionality', () => {
    expect(typeof process.version).toBe('string')
    expect(process.version).toMatch(/^v\d+\.\d+\.\d+/)
  })
})

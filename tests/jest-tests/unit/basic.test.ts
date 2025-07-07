describe('Basic Test Setup', () => {
  it('should run Jest tests', () => {
    expect(true).toBe(true)
  })

  it('should handle TypeScript', () => {
    const greeting: string = 'Hello, TypeScript!'
    expect(greeting).toContain('TypeScript')
  })

  it('should have environment variables', () => {
    expect(process.env.NODE_ENV).toBe('test')
    expect(process.env.WEBHOOK_SECRET).toBe('test-secret-123')
  })
})

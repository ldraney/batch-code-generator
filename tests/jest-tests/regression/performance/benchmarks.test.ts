describe('Performance Regression Tests', () => {
  it('should measure function execution time', () => {
    const start = Date.now()
    
    // Simple synchronous operation
    const result = Array.from({ length: 1000 }, (_, i) => i * 2)
    
    const duration = Date.now() - start
    
    expect(result.length).toBe(1000)
    expect(duration).toBeLessThan(100) // Should be very fast
  })

  it('should not have memory leaks in simple operations', () => {
    const initialMemory = process.memoryUsage().heapUsed
    
    // Create and cleanup some objects
    for (let i = 0; i < 1000; i++) {
      const obj = { data: new Array(100).fill(i) }
      // Let it go out of scope
    }
    
    // Force garbage collection if available
    if (global.gc) {
      global.gc()
    }
    
    const finalMemory = process.memoryUsage().heapUsed
    const memoryIncrease = finalMemory - initialMemory
    
    // Should not increase significantly
    expect(memoryIncrease).toBeLessThan(1024 * 1024) // 1MB
  })
})

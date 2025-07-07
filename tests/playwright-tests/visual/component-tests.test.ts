import { test, expect } from '@playwright/test'

test.describe('Component Regression Tests', () => {
  test('dashboard structure should be complete and correct', async ({ page }) => {
    await page.goto('/')
    
    // Wait for dashboard to load
    await page.waitForSelector('[data-testid="dashboard"]', { timeout: 10000 })
    
    // Core dashboard structure
    await expect(page.locator('[data-testid="dashboard"]')).toBeVisible()
    await expect(page.locator('h1')).toContainText('Batch Code Generator')
    
    // Status cards section
    await expect(page.locator('[data-testid="status-cards"]')).toBeVisible()
    const statusCards = page.locator('[data-testid="status-card"]')
    await expect(statusCards).toHaveCount(3)
    
    // Verify each status card has the expected content structure
    await expect(statusCards.nth(0)).toContainText('Status')
    await expect(statusCards.nth(1)).toContainText('Uptime')
    await expect(statusCards.nth(2)).toContainText('Memory Used')
    
    // API endpoints section
    await expect(page.locator('[data-testid="api-endpoints"]')).toBeVisible()
    await expect(page.locator('[data-testid="api-endpoints"] h2')).toContainText('API Endpoints')
    
    // Check API endpoint documentation is present
    await expect(page.locator('text=POST /api/webhook')).toBeVisible()
    await expect(page.locator('text=GET /api/health')).toBeVisible()
    await expect(page.locator('text=GET /api/metrics')).toBeVisible()
    
    // Quick links section
    await expect(page.locator('[data-testid="quick-links"]')).toBeVisible()
    await expect(page.locator('[data-testid="quick-links"] h2')).toContainText('Quick Links')
    
    // Footer
    await expect(page.locator('[data-testid="footer"]')).toBeVisible()
    await expect(page.locator('[data-testid="footer"]')).toContainText('Version:')
  })

  test('dashboard should load real health data', async ({ page }) => {
    await page.goto('/')
    
    // Wait for health data to load
    await page.waitForSelector('[data-testid="status-card"]', { timeout: 10000 })
    await page.waitForTimeout(3000) // Give time for API call
    
    // Status should not be "Unknown" (means API loaded)
    const statusCard = page.locator('[data-testid="status-card"]').first()
    await expect(statusCard).not.toContainText('Unknown')
    await expect(statusCard).toContainText('healthy')
    
    // Uptime should show time format (means data loaded)
    const uptimeCard = page.locator('[data-testid="status-card"]').nth(1)
    await expect(uptimeCard).toContainText(/\d+[hms]/) // Should contain hours/minutes/seconds
    
    // Memory should show MB format (means data loaded)
    const memoryCard = page.locator('[data-testid="status-card"]').nth(2)
    await expect(memoryCard).toContainText('MB')
  })

  test('quick links should be functional', async ({ page }) => {
    await page.goto('/')
    await page.waitForSelector('[data-testid="quick-links"]', { timeout: 10000 })
    
    // Check health link exists and has correct href
    const healthLink = page.locator('a[href="/api/health"]')
    await expect(healthLink).toBeVisible()
    await expect(healthLink).toContainText('Health Status')
    
    // Check metrics link exists and has correct href
    const metricsLink = page.locator('a[href="/api/metrics"]')
    await expect(metricsLink).toBeVisible()
    await expect(metricsLink).toContainText('Metrics')
  })

  test('loading states should work correctly', async ({ page }) => {
    // Slow down the health API to test loading state
    await page.route('/api/health', async route => {
      await new Promise(resolve => setTimeout(resolve, 2000))
      await route.continue()
    })

    await page.goto('/')
    
    // Should show loading state initially
    await expect(page.locator('[data-testid="loading-state"]')).toBeVisible()
    await expect(page.locator('[data-testid="loading-state"]')).toContainText('Loading...')
    
    // Then should show dashboard after loading
    await page.waitForSelector('[data-testid="dashboard"]', { timeout: 15000 })
    await expect(page.locator('[data-testid="loading-state"]')).not.toBeVisible()
    await expect(page.locator('[data-testid="dashboard"]')).toBeVisible()
  })

  test('responsive design should work on different viewports', async ({ page }) => {
    await page.goto('/')
    await page.waitForSelector('[data-testid="status-cards"]', { timeout: 10000 })
    
    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 812 })
    await page.waitForTimeout(1000)
    
    // All components should still be visible
    await expect(page.locator('[data-testid="status-cards"]')).toBeVisible()
    await expect(page.locator('[data-testid="status-card"]')).toHaveCount(3)
    await expect(page.locator('[data-testid="api-endpoints"]')).toBeVisible()
    await expect(page.locator('[data-testid="quick-links"]')).toBeVisible()
    
    // Test tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 })
    await page.waitForTimeout(1000)
    
    // All components should still be visible
    await expect(page.locator('[data-testid="status-cards"]')).toBeVisible()
    await expect(page.locator('[data-testid="status-card"]')).toHaveCount(3)
    
    // Test desktop viewport
    await page.setViewportSize({ width: 1920, height: 1080 })
    await page.waitForTimeout(1000)
    
    // All components should still be visible
    await expect(page.locator('[data-testid="status-cards"]')).toBeVisible()
    await expect(page.locator('[data-testid="status-card"]')).toHaveCount(3)
  })

  test('dashboard should handle API failures gracefully', async ({ page }) => {
    // Mock API to return error
    await page.route('/api/health', route => {
      route.fulfill({
        status: 500,
        body: JSON.stringify({ error: 'Internal Server Error' })
      })
    })

    await page.goto('/')
    
    // Dashboard should still load (it loads first, then makes API call)
    await page.waitForSelector('[data-testid="dashboard"]', { timeout: 10000 })
    
    // Main structure should be present even with API error
    await expect(page.locator('[data-testid="status-cards"]')).toBeVisible()
    await expect(page.locator('[data-testid="api-endpoints"]')).toBeVisible()
    await expect(page.locator('[data-testid="quick-links"]')).toBeVisible()
    
    // Page should not crash (dashboard still visible)
    await expect(page.locator('[data-testid="dashboard"]')).toBeVisible()
    
    // Should show 3 status cards even if they show error states
    await expect(page.locator('[data-testid="status-card"]')).toHaveCount(3)
  })

  test('all critical navigation and content should be accessible', async ({ page }) => {
    await page.goto('/')
    await page.waitForSelector('[data-testid="dashboard"]', { timeout: 10000 })
    
    // Test keyboard navigation (accessibility)
    await page.keyboard.press('Tab')
    await page.keyboard.press('Tab')
    
    // Page should be keyboard accessible (no JavaScript errors)
    const pageErrors: string[] = []
    page.on('pageerror', error => pageErrors.push(error.message))
    
    // Wait a bit to catch any errors
    await page.waitForTimeout(2000)
    
    // Should not have any JavaScript errors
    expect(pageErrors).toEqual([])
    
    // All text content should be readable (not empty)
    const mainHeading = await page.locator('h1').textContent()
    expect(mainHeading).toBeTruthy()
    expect(mainHeading?.length).toBeGreaterThan(5)
  })
})

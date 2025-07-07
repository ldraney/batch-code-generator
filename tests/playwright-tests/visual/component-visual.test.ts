import { test, expect } from '@playwright/test'

test.describe('Component Visual Tests (CI-Friendly)', () => {
  test('dashboard should load and display all components', async ({ page }) => {
    await page.goto('/')
    
    // Wait for the dashboard to load
    await page.waitForSelector('[data-testid="status-card"]', { timeout: 10000 })
    
    // Check that all major components are present
    await expect(page.locator('[data-testid="dashboard"]')).toBeVisible()
    await expect(page.locator('[data-testid="status-cards"]')).toBeVisible()
    await expect(page.locator('[data-testid="api-endpoints"]')).toBeVisible()
    await expect(page.locator('[data-testid="quick-links"]')).toBeVisible()
    
    // Check we have exactly 3 status cards
    const statusCards = page.locator('[data-testid="status-card"]')
    await expect(statusCards).toHaveCount(3)
    
    // Check main heading
    await expect(page.locator('h1')).toContainText('Batch Code Generator')
  })

  test('dashboard should show real health data', async ({ page }) => {
    await page.goto('/')
    
    // Wait for health data to load
    await page.waitForSelector('[data-testid="status-card"]', { timeout: 10000 })
    await page.waitForTimeout(2000) // Wait for API call
    
    // Check that we have real data (not just placeholders)
    const statusCard = page.locator('[data-testid="status-card"]').first()
    await expect(statusCard).not.toContainText('Unknown')
    
    // Should show either 'healthy' or some status
    const statusText = await statusCard.textContent()
    expect(statusText).toMatch(/(healthy|Status)/i)
  })

  test('dashboard should be responsive', async ({ page }) => {
    // Test different viewport sizes
    const viewports = [
      { width: 375, height: 812, name: 'mobile' },
      { width: 768, height: 1024, name: 'tablet' },
      { width: 1920, height: 1080, name: 'desktop' }
    ]

    for (const viewport of viewports) {
      await page.setViewportSize(viewport)
      await page.goto('/')
      await page.waitForSelector('[data-testid="status-card"]', { timeout: 10000 })
      
      // Should still show all 3 status cards on all screen sizes
      await expect(page.locator('[data-testid="status-card"]')).toHaveCount(3)
      
      console.log(`✅ ${viewport.name} viewport (${viewport.width}x${viewport.height}) - OK`)
    }
  })

  test('API endpoints section should be present', async ({ page }) => {
    await page.goto('/')
    await page.waitForSelector('[data-testid="api-endpoints"]', { timeout: 10000 })
    
    // Check API endpoints are documented
    const apiSection = page.locator('[data-testid="api-endpoints"]')
    await expect(apiSection).toContainText('POST /api/webhook')
    await expect(apiSection).toContainText('GET /api/health')
    await expect(apiSection).toContainText('GET /api/metrics')
  })
})

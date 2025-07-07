import { test, expect } from '@playwright/test'

test.describe('Visual Regression Tests', () => {
  test('dashboard should load and display content', async ({ page }) => {
    await page.goto('/')
    
    // Wait for the dashboard to load (look for any status card)
    await page.waitForSelector('[data-testid="status-card"]', { timeout: 10000 })
    
    // Wait for content to be stable
    await page.waitForTimeout(2000)
    
    // Take a screenshot
    await expect(page).toHaveScreenshot('dashboard-main.png', {
      fullPage: true,
      animations: 'disabled'
    })
  })

  test('dashboard should show loading state', async ({ page }) => {
    // Intercept health API to add delay
    await page.route('/api/health', async route => {
      await new Promise(resolve => setTimeout(resolve, 1000))
      await route.continue()
    })

    await page.goto('/')
    
    // Should show loading state briefly
    await page.waitForSelector('[data-testid="loading-state"]', { timeout: 5000 })
    
    // Take screenshot of loading state
    await expect(page).toHaveScreenshot('dashboard-loading.png', {
      animations: 'disabled'
    })
  })

  test('dashboard components should be present', async ({ page }) => {
    await page.goto('/')
    
    // Wait for dashboard
    await page.waitForSelector('[data-testid="dashboard"]', { timeout: 10000 })
    
    // Check all major components are present
    await expect(page.locator('[data-testid="status-cards"]')).toBeVisible()
    await expect(page.locator('[data-testid="api-endpoints"]')).toBeVisible()
    await expect(page.locator('[data-testid="quick-links"]')).toBeVisible()
    await expect(page.locator('[data-testid="footer"]')).toBeVisible()
    
    // Check we have status cards
    const statusCards = page.locator('[data-testid="status-card"]')
    await expect(statusCards).toHaveCount(3)
  })
})

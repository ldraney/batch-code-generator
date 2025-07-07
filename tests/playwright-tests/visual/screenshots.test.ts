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

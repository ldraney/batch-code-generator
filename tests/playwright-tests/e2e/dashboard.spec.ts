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

// debug-api-failure.js
// Run with: node debug-api-failure.js

const { chromium } = require('@playwright/test');

async function debugApiFailure() {
  console.log('🔍 Starting API failure debug session...');
  
  const browser = await chromium.launch({ 
    headless: false,
    slowMo: 1000 
  });
  
  const page = await browser.newPage();
  
  // Listen for console logs and errors
  page.on('console', msg => {
    console.log(`🔍 Console [${msg.type()}]:`, msg.text());
  });
  
  page.on('pageerror', error => {
    console.error('❌ Page Error:', error.message);
  });
  
  page.on('requestfailed', request => {
    console.log(`❌ Failed Request: ${request.url()} - ${request.failure()?.errorText}`);
  });
  
  try {
    console.log('🚫 Setting up API failure mock...');
    
    // Mock the API to fail EXACTLY like the test does
    await page.route('/api/health', route => {
      console.log('🎯 API call intercepted, returning 500 error');
      route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Internal Server Error' })
      });
    });
    
    console.log('📱 Navigating to localhost:3000...');
    await page.goto('http://localhost:3000');
    
    console.log('⏰ Waiting 5 seconds to see what happens...');
    await page.waitForTimeout(5000);
    
    console.log('🔍 Checking what\'s on the page...');
    
    // Check if loading state exists
    const loadingExists = await page.locator('[data-testid="loading-state"]').count();
    console.log(`Loading state elements: ${loadingExists}`);
    
    // Check if dashboard exists
    const dashboardExists = await page.locator('[data-testid="dashboard"]').count();
    console.log(`Dashboard elements: ${dashboardExists}`);
    
    // Get page title and content preview
    console.log('Page title:', await page.title());
    console.log('Page URL:', page.url());
    
    // Get all test IDs on the page
    const testIds = await page.$$eval('[data-testid]', elements => 
      elements.map(el => el.getAttribute('data-testid'))
    );
    console.log('Found test IDs:', testIds);
    
    // Check if there's any content at all
    const bodyText = await page.textContent('body');
    console.log('Body text length:', bodyText?.length || 0);
    console.log('Body text preview:', bodyText?.substring(0, 200) || 'No content');
    
    console.log('📸 Taking screenshot of current state...');
    await page.screenshot({ path: 'debug-api-failure.png', fullPage: true });
    
    console.log('⏸️  Pausing for 10 seconds for manual inspection...');
    await page.waitForTimeout(10000);
    
  } catch (error) {
    console.error('❌ Error during debug:', error);
    await page.screenshot({ path: 'debug-api-failure-error.png' });
  } finally {
    await browser.close();
    console.log('✅ Debug complete. Check debug-api-failure.png');
  }
}

debugApiFailure().catch(console.error);

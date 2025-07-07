// debug-visual-test.js
// Run with: node debug-visual-test.js

const { chromium } = require('@playwright/test');

async function debugVisualTest() {
  console.log('🔍 Starting debug session...');
  
  const browser = await chromium.launch({ 
    headless: false,  // Show browser so we can see what's happening
    slowMo: 1000     // Slow down actions
  });
  
  const page = await browser.newPage();
  
  try {
    console.log('📱 Navigating to localhost:3000...');
    await page.goto('http://localhost:3000');
    
    console.log('⏰ Waiting 2 seconds for page to settle...');
    await page.waitForTimeout(2000);
    
    console.log('🔎 Checking if dashboard element exists...');
    const dashboardExists = await page.locator('[data-testid="dashboard"]').count();
    console.log(`Dashboard elements found: ${dashboardExists}`);
    
    if (dashboardExists > 0) {
      console.log('✅ Dashboard element found!');
      
      console.log('🔍 Checking visibility...');
      const isVisible = await page.locator('[data-testid="dashboard"]').isVisible();
      console.log(`Dashboard visible: ${isVisible}`);
      
      console.log('📏 Getting element bounds...');
      const boundingBox = await page.locator('[data-testid="dashboard"]').boundingBox();
      console.log('Bounding box:', boundingBox);
      
    } else {
      console.log('❌ Dashboard element NOT found');
      
      console.log('🔍 Let\'s see what IS on the page...');
      const pageContent = await page.content();
      console.log('Page title:', await page.title());
      console.log('Page URL:', page.url());
      
      // Check for any testid attributes
      const testIds = await page.$$eval('[data-testid]', elements => 
        elements.map(el => el.getAttribute('data-testid'))
      );
      console.log('Found test IDs:', testIds);
    }
    
    console.log('📸 Taking screenshot...');
    await page.screenshot({ path: 'debug-screenshot.png', fullPage: true });
    
    console.log('⏸️  Pausing for 10 seconds so you can inspect...');
    await page.waitForTimeout(10000);
    
  } catch (error) {
    console.error('❌ Error during debug:', error);
    await page.screenshot({ path: 'debug-error-screenshot.png' });
  } finally {
    await browser.close();
    console.log('✅ Debug session complete. Check debug-screenshot.png');
  }
}

// Run the debug
debugVisualTest().catch(console.error);

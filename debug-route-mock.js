// debug-route-mock.js
const { chromium } = require('@playwright/test');

async function debugRouteMock() {
  console.log('🔍 Testing route mocking...');
  
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  // Track all network requests
  page.on('request', request => {
    console.log(`📤 Request: ${request.method()} ${request.url()}`);
  });
  
  page.on('response', response => {
    console.log(`📥 Response: ${response.status()} ${response.url()}`);
  });
  
  try {
    console.log('🚫 Setting up route mock for /api/health...');
    
    // Try different route patterns
    await page.route('**/api/health', route => {
      console.log('🎯 Route intercepted!', route.request().url());
      route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Mocked error' })
      });
    });
    
    console.log('📱 Navigating to page...');
    await page.goto('http://localhost:3000');
    
    console.log('⏰ Waiting for page to load...');
    await page.waitForTimeout(3000);
    
    console.log('🧪 Testing direct API call...');
    const response = await page.evaluate(async () => {
      const res = await fetch('/api/health');
      const data = await res.json();
      return { status: res.status, data };
    });
    
    console.log('API Response:', response);
    
    await page.waitForTimeout(5000);
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await browser.close();
  }
}

debugRouteMock().catch(console.error);

#!/bin/bash

echo "🔍 Debugging webhook 500 error..."

# First, let's test the webhook manually to see the actual error
echo "🧪 Testing webhook endpoint manually..."

echo ""
echo "📋 Testing GET request (should work):"
curl -s http://localhost:3000/api/webhook | jq .

echo ""
echo "📋 Testing POST request (the failing one):"
curl -s -X POST http://localhost:3000/api/webhook \
  -H "Content-Type: application/json" \
  -H "x-webhook-signature: dev-secret-123" \
  -d '{
    "event": "code_generation_request",
    "data": {
      "type": "component",
      "language": "typescript"
    },
    "timestamp": "2025-07-06T12:00:00Z"
  }' | jq .

echo ""
echo "📋 Let's also check what the test is sending exactly..."

# Create a test script that matches exactly what the regression test does
cat > test-webhook-debug.js << 'EOF'
const request = require('supertest');

async function testWebhook() {
  const baseURL = 'http://localhost:3000';
  
  const payload = {
    event: 'code_generation_request',
    data: { type: 'component', language: 'typescript' },
    timestamp: new Date().toISOString()
  };

  console.log('📋 Sending payload:', JSON.stringify(payload, null, 2));

  try {
    const response = await request(baseURL)
      .post('/api/webhook')
      .set('x-webhook-signature', 'dev-secret-123')
      .send(payload)
      .timeout(5000);

    console.log('✅ Response status:', response.status);
    console.log('✅ Response body:', JSON.stringify(response.body, null, 2));
  } catch (error) {
    console.log('❌ Error:', error.message);
    if (error.response) {
      console.log('❌ Status:', error.response.status);
      console.log('❌ Body:', error.response.body);
      console.log('❌ Text:', error.response.text);
    }
  }
}

testWebhook();
EOF

echo ""
echo "🧪 Running debug test script..."
node test-webhook-debug.js

echo ""
echo "💡 Common webhook 500 error causes:"
echo "1. Environment variable WEBHOOK_SECRET mismatch"
echo "2. Import/export issues in the webhook route"
echo "3. Zod validation schema problems"
echo "4. Metrics recording function errors"
echo "5. Sentry initialization issues"

echo ""
echo "🔧 Let's check the current WEBHOOK_SECRET..."
echo "From .env.local (if exists):"
if [ -f .env.local ]; then
  grep WEBHOOK_SECRET .env.local || echo "No WEBHOOK_SECRET found in .env.local"
else
  echo ".env.local does not exist"
fi

echo ""
echo "📝 The test is using signature: 'dev-secret-123'"
echo "📝 The webhook expects: process.env.WEBHOOK_SECRET || 'dev-secret-123'"

echo ""
echo "🎯 Next steps:"
echo "1. Check the server logs in your terminal running 'npm run dev'"
echo "2. Look for any error messages when the webhook is called"
echo "3. The issue is likely in the webhook route file src/app/api/webhook/route.ts"

# Cleanup
rm -f test-webhook-debug.js

echo ""
echo "🔍 Debug complete. Check the output above and server logs!"

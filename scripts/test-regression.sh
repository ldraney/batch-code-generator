#!/bin/bash

set -e

echo "🧪 Running Regression Test Suite..."

export NODE_ENV=test
export TEST_BASE_URL=${TEST_BASE_URL:-http://localhost:3000}

echo "🎯 Testing against: $TEST_BASE_URL"

# Check if server is running
if ! curl -s "$TEST_BASE_URL/api/health" > /dev/null; then
    echo "❌ Server not responding at $TEST_BASE_URL"
    echo "💡 Start the server first: npm run dev (or npm start for prod build)"
    exit 1
fi

echo "✅ Server is responding"

echo ""
echo "📋 Running Jest-based regression tests..."
npm run test:regression:api

echo ""
echo "👁️ Running Playwright-based visual tests..."
npm run test:visual

echo ""
echo "🎭 Running E2E tests..."
npm run test:e2e

echo ""
echo "🎉 All regression tests completed!"

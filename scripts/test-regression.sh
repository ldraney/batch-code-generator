#!/bin/bash

set -e

echo "🧪 Running Regression Test Suite..."

# Environment variables
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

# Run different test suites
echo ""
echo "📋 Running API Contract Tests..."
npm run test -- tests/regression/api

echo ""
echo "⚡ Running Performance Tests..."
npm run test -- tests/regression/performance

echo ""
echo "💨 Running Smoke Tests..."
npm run test -- tests/regression/smoke

echo ""
echo "👁️ Running Visual Regression Tests..."
npm run test:e2e -- tests/regression/visual

echo ""
echo "🎉 All regression tests completed!"

#!/bin/bash

echo "🧪 Running component regression baseline tests..."

if ! curl -s "http://localhost:3000/api/health" > /dev/null; then
    echo "❌ Server not running. Please start with 'npm run dev' first."
    exit 1
fi

echo "🔧 Running component tests (no baselines needed)..."
npm run test:visual

echo "📊 Running API regression tests..."
npm run test:regression:api

echo "✅ All regression tests complete!"
echo "💡 Component tests validate structure and functionality."
echo "🚀 No visual baselines needed - tests are self-validating!"

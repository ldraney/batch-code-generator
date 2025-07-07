#!/bin/bash

echo "📸 Capturing baseline screenshots and performance metrics..."

if ! curl -s "http://localhost:3000/api/health" > /dev/null; then
    echo "❌ Server not running. Please start with 'npm run dev' first."
    exit 1
fi

echo "📷 Capturing visual baselines..."
echo "This will create new baseline screenshots for comparison"

# Create baselines for visual tests
npx playwright test tests/playwright-tests/visual --update-snapshots

echo "📊 Running performance baselines..."
npm run test:regression:api

echo "✅ Baselines captured! Commit these to version control."
echo "💡 Run 'npm run test:regression' to validate against baselines."
echo ""
echo "📁 Screenshot baselines saved to:"
echo "   tests/playwright-tests/visual/screenshots.test.ts-snapshots/"

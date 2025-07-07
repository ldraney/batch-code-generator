#!/bin/bash

echo "📸 Capturing baseline screenshots and performance metrics..."

if ! curl -s "http://localhost:3000/api/health" > /dev/null; then
    echo "❌ Server not running. Please start with 'npm run dev' first."
    exit 1
fi

echo "📷 Capturing visual baselines..."
npm run test:visual -- --update-snapshots

echo "📊 Capturing performance baselines..."
npm run test:regression:api

echo "✅ Baselines captured! Commit these to version control."
echo "💡 Run 'npm run test:regression' to validate against baselines."

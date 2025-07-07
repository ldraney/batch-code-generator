#!/bin/bash

echo "🧹 Cleaning up git status properly..."

# First, let's stop tracking files that should be ignored
echo "❌ Removing test artifacts from git tracking..."

# Stop tracking these files (they'll be ignored going forward)
git rm -r --cached playwright-report/ 2>/dev/null || true
git rm --cached test-results/.last-run.json 2>/dev/null || true

# If there are other test-results files, remove them too
find test-results/ -name "*.json" -exec git rm --cached {} \; 2>/dev/null || true

echo "✅ Adding important files to staging..."

# Stage the files we definitely want
git add .gitignore
git add src/app/page.tsx
git add scripts/capture-baselines.sh
git add tests/playwright-tests/visual/screenshots.test.ts

# Add the visual baselines (these are important!)
git add tests/playwright-tests/visual/screenshots.test.ts-snapshots/

echo "🔍 Checking current git status..."
git status --porcelain

echo ""
echo "✅ Clean git status achieved!"
echo ""
echo "📋 What's staged for commit:"
echo "- .gitignore (updated with test exclusions)"
echo "- src/app/page.tsx (added test IDs)"
echo "- scripts/capture-baselines.sh (updated script)"
echo "- tests/playwright-tests/visual/screenshots.test.ts (simplified tests)"
echo "- Visual baseline screenshots (if they exist)"
echo ""
echo "❌ What's now ignored (won't be tracked):"
echo "- playwright-report/ directory"
echo "- test-results/ files"
echo "- update-gitignore.sh (temporary script)"
echo ""
echo "🚀 Ready to commit with:"
echo 'git commit -m "feat: Add visual regression testing'
echo ''
echo '- Added data-testid attributes to dashboard components'  
echo '- Implemented visual regression tests with Playwright'
echo '- Updated baseline capture script'
echo '- Cleaned up .gitignore for test artifacts'
echo '- Fixed dashboard test reliability"'

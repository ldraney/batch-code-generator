#!/bin/bash

echo "📝 Updating .gitignore for test artifacts..."

# Update .gitignore to handle test-related files properly
cat >> .gitignore << 'EOF'

# Test Results and Reports
/test-results/
/playwright-report/
/coverage/

# Jest Coverage
/coverage.lcov

# Test Artifacts
*.test-result.json
.last-run.json

# Visual Test Snapshots (commit these!)
# Note: We DO want to commit snapshots for visual regression
# tests/playwright-tests/visual/screenshots.test.ts-snapshots/

# Temporary test files
test-webhook-debug.js
fix-*.sh
debug-*.sh
setup-*.sh

# Test databases
test.db
test.sqlite

# Load testing results
artillery-report.html
artillery-results.json

# Local test configurations
.test-env
test.env

EOF

echo "🧹 Cleaning up temporary files that shouldn't be tracked..."

# Remove temporary test results from tracking
git rm -r --cached test-results/ 2>/dev/null || true
git rm -r --cached playwright-report/data/ 2>/dev/null || true

# Add the important files we want to track
echo "📋 Staging important files for commit..."

# Stage the core application changes
git add src/app/page.tsx
git add scripts/capture-baselines.sh  
git add tests/playwright-tests/visual/screenshots.test.ts
git add .gitignore

# Stage any baseline screenshots (these should be tracked!)
if [ -d "tests/playwright-tests/visual/screenshots.test.ts-snapshots/" ]; then
    echo "📸 Found visual baselines - staging them for commit..."
    git add tests/playwright-tests/visual/screenshots.test.ts-snapshots/
fi

echo ""
echo "✅ .gitignore updated and files staged!"
echo ""
echo "📋 What's being tracked:"
echo "✅ Source code changes (src/app/page.tsx)"
echo "✅ Test configuration (tests/playwright-tests/)"  
echo "✅ Scripts (scripts/capture-baselines.sh)"
echo "✅ Visual baselines (if they exist)"
echo "✅ Updated .gitignore"
echo ""
echo "❌ What's ignored:"
echo "- test-results/ (temporary test output)"
echo "- playwright-report/ (temporary reports)"
echo "- fix-*.sh scripts (temporary debug files)"
echo ""
echo "🚀 Ready to commit:"
echo "git commit -m 'Add visual regression testing with dashboard test IDs"
echo ""
echo "Features:"
echo "- Added data-testid attributes to dashboard components"
echo "- Simplified visual regression tests"
echo "- Updated baseline capture script"
echo "- Cleaned up .gitignore for test artifacts'"

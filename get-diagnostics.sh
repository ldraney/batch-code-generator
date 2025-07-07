#!/bin/bash

# Test Diagnostics Script
# This script gathers information to help debug API test failures

echo "🔍 Collecting Test Diagnostics Information..."
echo "=============================================="

# Create output directory
mkdir -p test-diagnostics
cd test-diagnostics

echo "📁 1. File Tree Structure"
echo "-------------------------"
echo "Getting project structure..." > file-tree.txt
tree -I 'node_modules|.git|dist|build|coverage' -L 4 .. >> file-tree.txt 2>/dev/null || {
    echo "tree command not found, using find instead..." >> file-tree.txt
    find .. -type f -name "*.js" -o -name "*.ts" -o -name "*.json" -o -name "*.env*" | grep -E '\.(js|ts|json|env)$' | head -50 >> file-tree.txt
}

echo "📋 2. Package.json"
echo "------------------"
cp ../package.json . 2>/dev/null || echo "package.json not found"

echo "🧪 3. Test Configuration Files"
echo "------------------------------"
# Jest config
cp ../jest.config.js . 2>/dev/null || echo "jest.config.js not found"
cp ../jest.config.ts . 2>/dev/null || echo "jest.config.ts not found"
cp ../jest.config.json . 2>/dev/null || echo "jest.config.json not found"

# Test setup files
find .. -name "*.setup.*" -o -name "setup*" | grep -i test | head -5 | while read file; do
    cp "$file" . 2>/dev/null
done

echo "🔧 4. Environment Files"
echo "----------------------"
cp ../.env.test . 2>/dev/null || echo ".env.test not found"
cp ../.env.local . 2>/dev/null || echo ".env.local not found"
cp ../.env.example . 2>/dev/null || echo ".env.example not found"

echo "📝 5. Failing Test Files"
echo "------------------------"
# Get the specific failing test files
cp ../tests/jest-tests/integration/api-integration.test.ts . 2>/dev/null || echo "api-integration.test.ts not found"
cp ../tests/jest-tests/regression/api/contracts.test.ts . 2>/dev/null || echo "contracts.test.ts not found"

echo "🌐 6. API Route Files"
echo "--------------------"
# Look for API routes
mkdir -p api-routes
find .. -path "*/api/*" -name "*.js" -o -path "*/api/*" -name "*.ts" | head -10 | while read file; do
    cp "$file" api-routes/ 2>/dev/null
done

# Specifically look for health endpoint
find .. -name "*health*" | head -5 | while read file; do
    cp "$file" api-routes/ 2>/dev/null
done

echo "⚙️ 7. Server/App Entry Files"
echo "----------------------------"
# Common server files
cp ../server.js . 2>/dev/null || echo "server.js not found"
cp ../index.js . 2>/dev/null || echo "index.js not found"
cp ../app.js . 2>/dev/null || echo "app.js not found"
cp ../src/index.ts . 2>/dev/null || echo "src/index.ts not found"
cp ../src/app.ts . 2>/dev/null || echo "src/app.ts not found"
cp ../src/server.ts . 2>/dev/null || echo "src/server.ts not found"

echo "🔧 8. Build/Config Files"
echo "------------------------"
cp ../tsconfig.json . 2>/dev/null || echo "tsconfig.json not found"
cp ../webpack.config.js . 2>/dev/null || echo "webpack.config.js not found"
cp ../next.config.js . 2>/dev/null || echo "next.config.js not found"
cp ../vite.config.js . 2>/dev/null || echo "vite.config.js not found"

echo "📊 9. Recent Logs"
echo "----------------"
echo "Checking for recent log files..." > recent-logs.txt
find .. -name "*.log" -mtime -1 2>/dev/null | head -5 | while read logfile; do
    echo "=== $logfile ===" >> recent-logs.txt
    tail -50 "$logfile" >> recent-logs.txt 2>/dev/null
done

echo "🔍 10. Test Command Analysis"
echo "----------------------------"
echo "Package.json test scripts:" > test-commands.txt
grep -A 10 '"scripts"' ../package.json >> test-commands.txt 2>/dev/null

echo "✅ 11. Summary Report"
echo "--------------------"
cat << EOF > DIAGNOSTIC_SUMMARY.md
# Test Diagnostics Summary

## Issue
- Multiple API endpoints returning 500 Internal Server Error
- Tests expecting 200 OK responses
- Affects: /api/health, webhook endpoints, batch job endpoints

## Files Collected
- File tree structure
- Package.json and configs
- Failing test files
- API route files
- Server entry points
- Environment files
- Recent logs

## Next Steps
1. Check server startup in test files
2. Verify database/service connections
3. Check environment variables
4. Review API route implementations
5. Check test setup/teardown

## Key Files to Review First
1. api-integration.test.ts - How is the server started?
2. package.json - Test scripts and dependencies
3. API route files - Health endpoint implementation
4. Environment files - Required variables set?
EOF

echo ""
echo "✅ Diagnostics Complete!"
echo "========================"
echo "Files collected in: ./test-diagnostics/"
echo ""
echo "📋 Quick Summary:"
echo "- File tree: file-tree.txt"
echo "- Config files: package.json, jest.config.*, tsconfig.json"
echo "- Test files: api-integration.test.ts, contracts.test.ts"
echo "- API routes: api-routes/ directory"
echo "- Server files: server.js, index.js, app.js, etc."
echo "- Environment: .env.test, .env.local, .env.example"
echo "- Summary: DIAGNOSTIC_SUMMARY.md"
echo ""
echo "🔍 To view all collected files:"
echo "ls -la test-diagnostics/"
echo ""
echo "📤 Share the test-diagnostics/ directory contents for analysis"

cd ..

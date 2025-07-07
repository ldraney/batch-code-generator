#!/bin/bash

echo "🧪 Running Complete Test Suite..."
echo "This runs ALL tests: Unit, Integration, Visual, Performance, Smoke"

# Set test environment
export NODE_ENV=test
export TEST_BASE_URL=${TEST_BASE_URL:-http://localhost:3000}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to run a test with proper reporting
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo ""
    echo "🔄 Running $test_name..."
    
    if $test_command; then
        echo -e "${GREEN}✅ $test_name: PASSED${NC}"
        return 0
    else
        echo -e "${RED}❌ $test_name: FAILED${NC}"
        return 1
    fi
}

# Track test results
FAILED_TESTS=""

# 1. Unit Tests (don't need server)
run_test "Unit Tests" "npm test -- --watchAll=false" || FAILED_TESTS="$FAILED_TESTS\n- Unit Tests"

# 2. Build Test (ensure production build works)
run_test "Build Validation" "npm run build" || FAILED_TESTS="$FAILED_TESTS\n- Build Validation"

# 3. Check if server is running for integration tests
SERVER_RUNNING=false
if curl -s "$TEST_BASE_URL/api/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Server is running at $TEST_BASE_URL${NC}"
    SERVER_RUNNING=true
else
    echo -e "${YELLOW}⚠️  Server not running at $TEST_BASE_URL${NC}"
    echo "💡 Start server with: npm run dev (in another terminal)"
    echo "   Integration tests will be skipped"
fi

# 4. Integration Tests (need server)
if [ "$SERVER_RUNNING" = true ]; then
    run_test "Integration Tests" "npm run test:integration" || FAILED_TESTS="$FAILED_TESTS\n- Integration Tests"
    run_test "API Contract Tests" "npm run test:contracts" || FAILED_TESTS="$FAILED_TESTS\n- API Contract Tests"
    run_test "Performance Tests" "npm run test:performance" || FAILED_TESTS="$FAILED_TESTS\n- Performance Tests"
    run_test "Smoke Tests" "npm run test:smoke" || FAILED_TESTS="$FAILED_TESTS\n- Smoke Tests"
    run_test "Visual Tests" "npm run test:visual" || FAILED_TESTS="$FAILED_TESTS\n- Visual Tests"
else
    echo -e "${YELLOW}⏭️  Skipping server-dependent tests${NC}"
fi

# Summary
echo ""
echo "📊 Test Suite Summary:"
echo "====================="

if [ -z "$FAILED_TESTS" ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo ""
    echo "✅ Unit Tests"
    echo "✅ Build Validation"
    if [ "$SERVER_RUNNING" = true ]; then
        echo "✅ Integration Tests"
        echo "✅ API Contract Tests"
        echo "✅ Performance Tests"
        echo "✅ Smoke Tests"
        echo "✅ Visual Tests"
    else
        echo "⏭️  Integration tests skipped (server not running)"
    fi
    echo ""
    echo "🚀 Ready for deployment!"
    exit 0
else
    echo -e "${RED}❌ Some tests failed:${NC}"
    echo -e "$FAILED_TESTS"
    echo ""
    echo "🔧 Fix the failing tests before deployment"
    exit 1
fi

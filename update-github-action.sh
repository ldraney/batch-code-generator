#!/bin/bash

echo "🔧 Updating GitHub Action to use our test:all:ci command..."

# Create a simplified GitHub Action that uses our comprehensive test script
cat > .github/workflows/test-suite.yml << 'EOF'
name: 🧪 Complete Test Suite

on:
  push:
    branches: [ main, develop, 'feature/*' ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test-suite:
    name: 🔬 Run Complete Test Suite
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        node-version: [18.x, 20.x]
    
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 📦 Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: 🔧 Install dependencies
        run: npm ci

      - name: 🏗️ Build application
        run: npm run build

      - name: 🚀 Start application for testing
        run: |
          npm start &
          sleep 10
        env:
          NODE_ENV: production
          WEBHOOK_SECRET: test-secret-123
          PORT: 3000

      - name: 🔍 Wait for application to be ready
        run: |
          timeout 60 bash -c 'until curl -f http://localhost:3000/api/health; do sleep 2; done'

      - name: 🧪 Run complete test suite
        run: npm run test:all:ci
        env:
          TEST_BASE_URL: http://localhost:3000
          CI: true

      - name: 🎭 Install Playwright browsers
        run: npx playwright install chromium

      - name: 📸 Upload test artifacts on failure
        uses: actions/upload-artifact@v3
        if: failure()
        with:
          name: test-results-${{ matrix.node-version }}
          path: |
            test-results/
            playwright-report/
            coverage/
          retention-days: 7

      - name: 📊 Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        if: matrix.node-version == '20.x'
        with:
          file: ./coverage/lcov.info
          fail_ci_if_error: false

      - name: 🔐 Security audit
        run: npm audit --audit-level high

  docker-test:
    name: 🐳 Docker Build & Test
    runs-on: ubuntu-latest
    needs: test-suite
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🐳 Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: 🏗️ Build Docker image
        run: docker build -t batch-code-generator:test .

      - name: 🚀 Test Docker container
        run: |
          # Start container
          docker run -d -p 3000:3000 \
            -e WEBHOOK_SECRET=test-secret-123 \
            --name test-container \
            batch-code-generator:test
          
          # Wait for readiness
          timeout 60 bash -c 'until curl -f http://localhost:3000/api/health; do sleep 2; done'
          
          # Test endpoints
          curl -f http://localhost:3000/api/health
          curl -f http://localhost:3000/api/metrics
          curl -f -X POST http://localhost:3000/api/webhook \
            -H "Content-Type: application/json" \
            -H "x-webhook-signature: test-secret-123" \
            -d '{"event": "code_generation_request", "data": {"type": "component"}, "timestamp": "2025-01-01T00:00:00Z"}'

      - name: 🧹 Cleanup Docker
        if: always()
        run: |
          docker stop test-container || true
          docker rm test-container || true

  deployment-ready:
    name: ✅ Ready for Deployment
    runs-on: ubuntu-latest
    needs: [test-suite, docker-test]
    if: github.ref == 'refs/heads/main'

    steps:
      - name: 🎉 Deployment Ready!
        run: |
          echo "🚀 All tests passed! Application is ready for deployment."
          echo "✅ Complete test suite passed on Node.js 18.x and 20.x"
          echo "✅ Docker build and container tests passed"
          echo "✅ Security audit completed"
          echo ""
          echo "🛫 Ready for Fly.io deployment!"

EOF

echo ""
echo "✅ Updated GitHub Action!"
echo ""
echo "🎯 What it now does:"
echo "- Uses our test:all:ci command for comprehensive testing"
echo "- Runs on push to main/develop/feature/* branches"
echo "- Runs on pull requests to main/develop"
echo "- Tests on Node.js 18.x and 20.x"
echo "- Docker tests only on main/develop (not feature branches)"
echo "- Deployment ready check only on main branch"
echo ""
echo "📋 Workflow:"
echo "1. 🔬 Complete Test Suite (always)"
echo "2. 🐳 Docker Test (main/develop only)"  
echo "3. ✅ Deployment Ready (main only)"
echo ""
echo "💡 Branch Protection:"
echo "- Feature branches: Must pass test suite"
echo "- Pull requests: Must pass test suite"
echo "- Main branch: Must pass everything including Docker"

#!/bin/bash

echo "🚀 Setting up Batch Code Generator development environment..."

if [ ! -f .env.local ]; then
    echo "📝 Creating .env.local from example..."
    cp .env.local.example .env.local
    echo "✅ Created .env.local - please update with your actual values"
else
    echo "✅ .env.local already exists"
fi

echo "📦 Installing dependencies..."
npm install

echo "🔨 Building the application..."
npm run build

echo " Testing the setup..."
echo "Starting health check..."

npm run dev &
DEV_PID=$!

sleep 5

echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:3000/api/health)
if [ $? -eq 0 ]; then
    echo "✅ Health check passed"
    echo "Response: $HEALTH_RESPONSE"
else
    echo "❌ Health check failed"
fi

echo "Testing metrics endpoint..."
METRICS_RESPONSE=$(curl -s http://localhost:3000/api/metrics)
if [ $? -eq 0 ]; then
    echo "✅ Metrics endpoint working"
else
    echo "❌ Metrics endpoint failed"
fi

echo "Testing webhook endpoint..."
WEBHOOK_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "x-webhook-signature: dev-secret-123" \
    -d '{
        "event": "code_generation_request",
        "data": {
            "type": "component",
            "language": "typescript",
            "content": "test"
        },
        "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
    }' \
    http://localhost:3000/api/webhook)

if [ $? -eq 0 ]; then
    echo "✅ Webhook endpoint working"
    echo "Response: $WEBHOOK_RESPONSE"
else
    echo "❌ Webhook endpoint failed"
fi

kill $DEV_PID

echo ""
echo "🎉 Setup complete! Next steps:"
echo "1. Update .env.local with your Sentry DSN and other secrets"
echo "2. Run 'npm run dev' to start the development server"
echo "3. Run 'npm run docker:dev' to start with full monitoring stack"
echo "4. Visit http://localhost:3000 to see the application"
echo "5. Visit http://localhost:3001 for Grafana (admin/admin)"
echo "6. Visit http://localhost:9090 for Prometheus"

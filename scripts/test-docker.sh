#!/bin/bash

echo "🐳 TESTING DOCKER SETUP"
echo "======================="

# Build the Docker image
echo "🔨 Building Docker image..."
npm run docker:build

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi

echo "✅ Docker build successful!"

# Test with main docker-compose
echo "🧪 Testing production Docker setup..."
docker-compose up -d

# Wait for container to be ready
echo "⏳ Waiting for container to start..."
sleep 10

# Test health endpoint
echo "🏥 Testing health endpoint..."
for i in {1..30}; do
    if curl -s http://localhost:3000/api/health > /dev/null; then
        echo "✅ Health check passed!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Health check failed after 30 attempts"
        docker-compose logs app
        docker-compose down
        exit 1
    fi
    echo "⏳ Attempt $i/30..."
    sleep 2
done

# Test metrics endpoint
echo "📊 Testing metrics endpoint..."
METRICS_RESPONSE=$(curl -s http://localhost:3000/api/metrics)
if [ $? -eq 0 ]; then
    echo "✅ Metrics endpoint working"
else
    echo "❌ Metrics endpoint failed"
    docker-compose logs app
    docker-compose down
    exit 1
fi

# Test webhook endpoint
echo "🪝 Testing webhook endpoint..."
WEBHOOK_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "x-webhook-signature: dev-secret-123" \
    -d '{
        "event": "code_generation_request",
        "data": {
            "type": "component",
            "language": "typescript",
            "content": "Docker test"
        },
        "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
    }' \
    http://localhost:3000/api/webhook)

if [ $? -eq 0 ]; then
    echo "✅ Webhook endpoint working"
    echo "Response: $WEBHOOK_RESPONSE"
else
    echo "❌ Webhook endpoint failed"
    docker-compose logs app
    docker-compose down
    exit 1
fi

# Clean up
echo "🧹 Cleaning up..."
docker-compose down

echo ""
echo "🎉 Docker setup test completed successfully!"
echo ""
echo "Next steps:"
echo "1. Test full monitoring stack: npm run docker:dev"
echo "2. Run all tests in Docker: npm run test:all"
echo "3. Deploy to Fly.io: fly deploy"


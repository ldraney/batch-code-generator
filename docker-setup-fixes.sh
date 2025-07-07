#!/bin/bash

echo "🐳 FIXING DOCKER SETUP"
echo "======================"

# 1. Fix Dockerfile - install ALL dependencies for build, then copy only production
echo "📝 Creating improved Dockerfile..."
cat > Dockerfile << 'EOF'
# Multi-stage build for optimal production image
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./
# Install ALL dependencies (including devDependencies for build)
RUN npm ci

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Set environment for build
ENV NEXT_TELEMETRY_DISABLED 1
ENV NODE_ENV production

# Build application
RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

# Create system user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built application
COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Copy package.json for version info
COPY --from=builder /app/package.json ./package.json

# Copy healthcheck script
COPY --from=builder /app/healthcheck.js ./healthcheck.js

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# Start the application
CMD ["node", "server.js"]
EOF

# 2. Create main docker-compose.yml for production testing
echo "📝 Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - WEBHOOK_SECRET=${WEBHOOK_SECRET:-dev-secret-123}
      - PORT=3000
    healthcheck:
      test: ["CMD", "node", "healthcheck.js"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - batch-generator

networks:
  batch-generator:
    driver: bridge
EOF

# 3. Update .dockerignore to be more precise
echo "📝 Updating .dockerignore..."
cat > .dockerignore << 'EOF'
# Dependencies
node_modules
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build outputs
.next
dist
build

# Environment files
.env*
!.env.local.example

# Version control
.git
.gitignore

# Documentation
README.md
docs/

# Development files
docker-compose*.yml
!docker-compose.yml
monitoring/
scripts/
*.sh
*.md

# Test files
test-results/
playwright-report/
coverage/

# Logs
*.log

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.temp
EOF

# 4. Update next.config.js to ensure standalone output
echo "📝 Updating next.config.js for Docker..."
cp next.config.js next.config.js.bak

# Add standalone output if not present
if ! grep -q "output.*standalone" next.config.js; then
    echo "Adding standalone output to next.config.js..."
    
    # Create updated next.config.js
    cat > next.config.js << 'EOF'
const { withSentryConfig } = require('@sentry/nextjs');

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Enable standalone output for Docker
  output: 'standalone',
  
  experimental: {
    instrumentationHook: true,
  },
  
  // Disable telemetry
  telemetry: false,
  
  // Optimize for production
  compress: true,
  poweredByHeader: false,
  
  // Handle static files
  trailingSlash: false,
  
  // Webpack configuration
  webpack: (config, { isServer }) => {
    // Ignore specific modules that might cause issues
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
      };
    }
    return config;
  },
  
  // Headers for security
  async headers() {
    return [
      {
        source: '/api/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'no-store, max-age=0',
          },
        ],
      },
    ];
  },
};

// Sentry configuration
const sentryWebpackPluginOptions = {
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,
  silent: true,
  widenClientFileUpload: true,
  reactComponentAnnotation: {
    enabled: true,
  },
  hideSourceMaps: true,
  disableLogger: true,
  automaticVercelMonitors: false,
};

// Export with Sentry if DSN is provided
module.exports = process.env.SENTRY_DSN 
  ? withSentryConfig(nextConfig, sentryWebpackPluginOptions)
  : nextConfig;
EOF
fi

# 5. Create Docker test script
echo "📝 Creating Docker test script..."
cat > scripts/test-docker.sh << 'EOF'
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

EOF

chmod +x scripts/test-docker.sh

# 6. Update package.json docker scripts
echo "📝 Updating package.json scripts..."
npm pkg set scripts.docker:test="./scripts/test-docker.sh"
npm pkg set scripts.docker:logs="docker-compose logs -f"
npm pkg set scripts.docker:down="docker-compose down"
npm pkg set scripts.docker:clean="docker system prune -f && docker volume prune -f"

echo ""
echo "🎉 DOCKER FIXES COMPLETE!"
echo "========================"
echo ""
echo "Changes made:"
echo "✅ Fixed Dockerfile (proper dependency handling)"
echo "✅ Created docker-compose.yml (production testing)"
echo "✅ Updated .dockerignore (optimized)"
echo "✅ Updated next.config.js (standalone output)"
echo "✅ Created scripts/test-docker.sh"
echo "✅ Added new npm scripts"
echo ""
echo "Next steps:"
echo "1. Test Docker build: npm run docker:build"
echo "2. Test Docker setup: npm run docker:test"
echo "3. Test full stack: npm run docker:dev"
echo "4. Run all tests: npm run test:all"
EOF

#!/bin/bash

echo "🔧 FIXING DOCKER PUBLIC DIRECTORY ISSUE"
echo "========================================"

# 1. Create public directory if it doesn't exist
if [ ! -d "public" ]; then
    echo "📁 Creating public directory..."
    mkdir -p public
    
    # Add a simple favicon and robots.txt
    cat > public/favicon.ico << 'EOF'
# Placeholder favicon (empty file is fine for now)
EOF

    cat > public/robots.txt << 'EOF'
User-agent: *
Allow: /

Sitemap: /sitemap.xml
EOF

    echo "✅ Created public directory with basic files"
else
    echo "✅ Public directory already exists"
fi

# 2. Create improved Dockerfile that handles optional public directory
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
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Build application
RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create system user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Create public directory and copy if exists
RUN mkdir -p ./public
COPY --from=builder /app/public ./public 2>/dev/null || true

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

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# Start the application
CMD ["node", "server.js"]
EOF

echo "✅ Updated Dockerfile to handle optional public directory"

# 3. Test the fix
echo "🧪 Testing Docker build..."
npm run docker:build

if [ $? -eq 0 ]; then
    echo "✅ Docker build successful!"
    echo ""
    echo "🎉 Ready to test full Docker setup:"
    echo "   npm run docker:test"
else
    echo "❌ Docker build still failing. Let's check what's missing..."
    
    # Check if .next/standalone exists after build
    if [ ! -f ".next/standalone/server.js" ]; then
        echo "⚠️  Issue: .next/standalone/server.js not found"
        echo "This means Next.js standalone output isn't working properly."
        echo ""
        echo "Let's check your next.config.js..."
        grep -A 5 -B 5 "output.*standalone" next.config.js || echo "❌ 'output: standalone' not found in next.config.js"
        
        echo ""
        echo "Running a local build to debug..."
        npm run build
        
        if [ -f ".next/standalone/server.js" ]; then
            echo "✅ Local build creates standalone output"
            echo "The issue might be with the Docker build context"
        else
            echo "❌ Even local build doesn't create standalone output"
            echo "Need to fix next.config.js configuration"
        fi
    fi
fi

echo ""
echo "🔧 Fix completed. Try running:"
echo "   npm run docker:build"
echo "   npm run docker:test"

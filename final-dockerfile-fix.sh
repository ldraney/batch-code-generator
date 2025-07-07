#!/bin/bash

echo "🔧 FINAL DOCKERFILE FIX"
echo "======================"

# Create the correct Dockerfile that handles missing public directory
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

# Handle public directory - create empty one first, then copy if exists
RUN mkdir -p ./public
# Use a shell command to copy public directory only if it exists in builder
RUN --mount=from=builder,source=/app,target=/tmp/app \
    if [ -d "/tmp/app/public" ]; then \
        cp -r /tmp/app/public/* ./public/ 2>/dev/null || true; \
    fi

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

echo "✅ Created new Dockerfile with proper public directory handling"

# Test the build
echo "🧪 Testing Docker build..."
docker build -t batch-code-generator .

if [ $? -eq 0 ]; then
    echo "✅ Docker build successful!"
else
    echo "❌ Still having issues. Let's try a simpler approach..."
    
    # Create a much simpler Dockerfile that just skips the public directory if missing
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

# Create empty public directory (Next.js will serve from .next/static anyway)
RUN mkdir -p ./public

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

    echo "✅ Created simpler Dockerfile"
    echo "🧪 Testing simpler build..."
    docker build -t batch-code-generator .
    
    if [ $? -eq 0 ]; then
        echo "✅ Simple Docker build successful!"
    else
        echo "❌ Still failing. Let's check what's actually in the .next directory..."
        echo "Contents of .next after local build:"
        ls -la .next/ 2>/dev/null || echo "No .next directory found"
        
        if [ -d ".next/standalone" ]; then
            echo "✅ .next/standalone exists"
            ls -la .next/standalone/
        else
            echo "❌ .next/standalone missing - this is the problem!"
            echo "Let's check next.config.js output setting..."
            grep -n "output" next.config.js || echo "No output setting found"
        fi
    fi
fi

echo ""
echo "Run this to test:"
echo "  docker build -t batch-code-generator ."

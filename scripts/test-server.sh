#!/bin/bash

# Test Server Script
# Starts the development server with test environment variables

echo "🚀 Starting development server with TEST environment..."

# Set test environment variables
export NODE_ENV=development  # Keep as development for Next.js
export WEBHOOK_SECRET=test-secret-123  # Use test secret for consistency with tests
export SENTRY_DSN=https://fake-dsn@sentry.io/fake-project

echo "✅ Environment variables set for testing:"
echo "   WEBHOOK_SECRET=$WEBHOOK_SECRET"
echo "   NODE_ENV=$NODE_ENV"

# Start the development server
npm run dev

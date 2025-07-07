#!/bin/bash

# CI Test Runner Script
# This script runs all tests in the proper order for CI

set -e

echo "🚀 Starting CI Test Suite..."

# Set CI environment
export CI=true
export NODE_ENV=test

# Run tests in order
echo "1️⃣ Running unit tests..."
npm run test:unit

echo "2️⃣ Running integration tests..."
npm run test:integration

echo "3️⃣ Running API contract tests..."
npm run test:contracts

echo "4️⃣ Running performance tests..."
npm run test:performance

echo "5️⃣ Running smoke tests..."
npm run test:smoke

echo "6️⃣ Running visual tests..."
npm run test:visual

echo "✅ All tests completed successfully!"

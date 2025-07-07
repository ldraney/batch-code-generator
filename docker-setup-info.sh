#!/bin/bash

echo "🐳 DOCKER SETUP INFO GATHERER"
echo "==============================="
echo

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Run this from your project root."
    exit 1
fi

echo "📁 PROJECT STRUCTURE"
echo "---------------------"
echo "Root directory contents:"
ls -la
echo

echo "📦 DOCKER FILES"
echo "---------------"
# Check for Docker files
if [ -f "Dockerfile" ]; then
    echo "✅ Dockerfile found"
    echo "--- Dockerfile content ---"
    cat Dockerfile
    echo
else
    echo "❌ Dockerfile not found"
fi

if [ -f "docker-compose.yml" ]; then
    echo "✅ docker-compose.yml found"
    echo "--- docker-compose.yml content ---"
    cat docker-compose.yml
    echo
else
    echo "❌ docker-compose.yml not found"
fi

if [ -f "docker-compose.dev.yml" ]; then
    echo "✅ docker-compose.dev.yml found"
    echo "--- docker-compose.dev.yml content ---"
    cat docker-compose.dev.yml
    echo
else
    echo " docker-compose.dev.yml not found"
fi

if [ -f ".dockerignore" ]; then
    echo "✅ .dockerignore found"
    echo "--- .dockerignore content ---"
    cat .dockerignore
    echo
else
    echo "❌ .dockerignore not found"
fi

echo "📋 PACKAGE.JSON SCRIPTS"
echo "------------------------"
echo "Docker-related scripts:"
grep -E "(docker|Docker)" package.json || echo "No docker scripts found"
echo

echo "All scripts:"
cat package.json | jq -r '.scripts | to_entries[] | "\(.key): \(.value)"' 2>/dev/null || echo "Could not parse scripts with jq, showing raw:"
grep -A 20 '"scripts"' package.json
echo

echo "🗂️ MONITORING DIRECTORY"
echo "------------------------"
if [ -d "monitoring" ]; then
    echo "✅ monitoring directory found"
    echo "Contents:"
    find monitoring -type f -name "*.yml" -o -name "*.yaml" -o -name "*.json" | head -10
    echo
    
    if [ -f "monitoring/docker-compose.yml" ]; then
        echo "--- monitoring/docker-compose.yml ---"
        cat monitoring/docker-compose.yml
        echo
    fi
else
    echo "❌ monitoring directory not found"
fi

echo "🧪 TEST CONFIGURATION"
echo "----------------------"
if [ -f "jest.config.js" ]; then
    echo "✅ jest.config.js found"
    echo "--- jest.config.js content ---"
    cat jest.config.js
    echo
fi

if [ -f "playwright.config.ts" ]; then
    echo "✅ playwright.config.ts found"
    echo "--- playwright.config.ts content ---"
    cat playwright.config.ts
    echo
fi

echo "🌍 ENVIRONMENT FILES"
echo "--------------------"
if [ -f ".env.local.example" ]; then
    echo "✅ .env.local.example found"
    echo "--- .env.local.example content ---"
    cat .env.local.example
    echo
else
    echo "❌ .env.local.example not found"
fi

if [ -f ".env.local" ]; then
    echo "✅ .env.local found (showing keys only for security)"
    echo "--- .env.local keys ---"
    grep -E "^[A-Z_]+" .env.local | cut -d'=' -f1 || echo "Could not parse .env.local"
    echo
else
    echo "❌ .env.local not found"
fi

echo "🚀 FLY.IO CONFIGURATION"
echo "------------------------"
if [ -f "fly.toml" ]; then
    echo "✅ fly.toml found"
    echo "--- fly.toml content ---"
    cat fly.toml
    echo
else
    echo "❌ fly.toml not found"
fi

if [ -f "Dockerfile.fly" ]; then
    echo "✅ Dockerfile.fly found"
    echo "--- Dockerfile.fly content ---"
    cat Dockerfile.fly
    echo
else
    echo "❌ Dockerfile.fly not found"
fi

echo "🔧 SCRIPTS DIRECTORY"
echo "--------------------"
if [ -d "scripts" ]; then
    echo "✅ scripts directory found"
    echo "Contents:"
    ls -la scripts/
    echo
    
    # Show any setup or docker scripts
    find scripts -name "*docker*" -o -name "*setup*" | while read file; do
        echo "--- $file ---"
        cat "$file"
        echo
    done
else
    echo "❌ scripts directory not found"
fi

echo "🎯 SUMMARY"
echo "----------"
echo "Docker files status:"
[ -f "Dockerfile" ] && echo "✅ Dockerfile" || echo "❌ Dockerfile"
[ -f "docker-compose.yml" ] && echo "✅ docker-compose.yml" || echo "❌ docker-compose.yml"
[ -f ".dockerignore" ] && echo "✅ .dockerignore" || echo "❌ .dockerignore"
[ -f "fly.toml" ] && echo "✅ fly.toml" || echo "❌ fly.toml"
[ -d "monitoring" ] && echo "✅ monitoring/" || echo "❌ monitoring/"

echo
echo "🚀 Ready to analyze Docker setup!"
echo "Next steps: Run 'npm run docker:build' and 'npm run docker:dev' to test"

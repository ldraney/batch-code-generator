#!/bin/bash

# Batch Code Generator - Project Analysis Script
# Run this from the root of your repository

echo "🔍 BATCH CODE GENERATOR - PROJECT ANALYSIS"
echo "=========================================="
echo ""

# Create output directory
mkdir -p analysis_output
OUTPUT_DIR="analysis_output"

echo "📁 Gathering project information..."
echo ""

# 1. README.md
echo "1️⃣ README.md Content:"
echo "-------------------"
if [ -f "README.md" ]; then
    cat README.md > "$OUTPUT_DIR/readme.md"
    echo "✅ README.md saved to $OUTPUT_DIR/readme.md"
else
    echo "❌ README.md not found"
fi
echo ""

# 2. File tree structure
echo "2️⃣ Project Structure:"
echo "--------------------"
if command -v tree &> /dev/null; then
    tree -I 'node_modules|.git|.next|dist|build|coverage|analysis_output' -a > "$OUTPUT_DIR/file_tree.txt"
    echo "✅ File tree saved to $OUTPUT_DIR/file_tree.txt"
else
    find . -type f -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./.next/*" -not -path "./dist/*" -not -path "./build/*" -not -path "./coverage/*" -not -path "./analysis_output/*" | head -50 > "$OUTPUT_DIR/file_tree.txt"
    echo "✅ File listing saved to $OUTPUT_DIR/file_tree.txt (install 'tree' for better output)"
fi
echo ""

# 3. Current webhook implementation
echo "3️⃣ Webhook Implementation:"
echo "-------------------------"
WEBHOOK_PATHS=(
    "pages/api/webhook.js"
    "pages/api/webhook.ts"
    "src/pages/api/webhook.js"
    "src/pages/api/webhook.ts"
    "app/api/webhook/route.js"
    "app/api/webhook/route.ts"
    "src/app/api/webhook/route.js"
    "src/app/api/webhook/route.ts"
)

WEBHOOK_FOUND=false
for path in "${WEBHOOK_PATHS[@]}"; do
    if [ -f "$path" ]; then
        cat "$path" > "$OUTPUT_DIR/webhook_implementation.txt"
        echo "✅ Webhook implementation found at $path"
        echo "✅ Saved to $OUTPUT_DIR/webhook_implementation.txt"
        WEBHOOK_FOUND=true
        break
    fi
done

if [ "$WEBHOOK_FOUND" = false ]; then
    echo "❌ Webhook implementation not found in common locations"
    echo "   Searched: ${WEBHOOK_PATHS[*]}"
    echo ""
    echo "📝 Please manually locate your webhook file and share its contents"
fi
echo ""

# 4. Package.json for dependencies
echo "4️⃣ Dependencies:"
echo "---------------"
if [ -f "package.json" ]; then
    cat package.json > "$OUTPUT_DIR/package.json"
    echo "✅ package.json saved to $OUTPUT_DIR/package.json"
else
    echo "❌ package.json not found"
fi
echo ""

# 5. Environment variables template
echo "5️⃣ Environment Configuration:"
echo "-----------------------------"
ENV_FILES=(".env.example" ".env.local" ".env")
ENV_FOUND=false
for env_file in "${ENV_FILES[@]}"; do
    if [ -f "$env_file" ]; then
        # Remove actual secrets, show structure only
        sed 's/=.*/=***REDACTED***/' "$env_file" > "$OUTPUT_DIR/env_structure.txt"
        echo "✅ Environment structure from $env_file saved to $OUTPUT_DIR/env_structure.txt"
        ENV_FOUND=true
        break
    fi
done

if [ "$ENV_FOUND" = false ]; then
    echo "❌ No environment files found (.env.example, .env.local, .env)"
fi
echo ""

# 6. Docker and deployment files
echo "6️⃣ Deployment Configuration:"
echo "----------------------------"
DEPLOY_FILES=("Dockerfile" "docker-compose.yml" "fly.toml" "vercel.json" "netlify.toml")
for file in "${DEPLOY_FILES[@]}"; do
    if [ -f "$file" ]; then
        cat "$file" > "$OUTPUT_DIR/$file"
        echo "✅ $file saved to $OUTPUT_DIR/$file"
    fi
done
echo ""

# 7. Database schema/models
echo "7️⃣ Database Configuration:"
echo "-------------------------"
DB_PATHS=(
    "prisma/schema.prisma"
    "src/db/schema.js"
    "src/db/schema.ts"
    "src/models"
    "models"
    "database"
    "db"
)

DB_FOUND=false
for path in "${DB_PATHS[@]}"; do
    if [ -f "$path" ] || [ -d "$path" ]; then
        if [ -f "$path" ]; then
            cat "$path" > "$OUTPUT_DIR/db_schema.txt"
            echo "✅ Database schema found at $path"
        else
            find "$path" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.sql" -o -name "*.prisma" \) | head -10 > "$OUTPUT_DIR/db_files.txt"
            echo "✅ Database files found in $path directory"
        fi
        DB_FOUND=true
        break
    fi
done

if [ "$DB_FOUND" = false ]; then
    echo "❓ No database configuration found (will need to set up for batch code storage)"
fi
echo ""

# 8. Monitoring/observability setup
echo "8️⃣ Monitoring Setup:"
echo "-------------------"
MONITORING_FILES=("prometheus.yml" "grafana" "sentry.config.js" "next.config.js")
for file in "${MONITORING_FILES[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        if [ -f "$file" ]; then
            cat "$file" > "$OUTPUT_DIR/monitoring_$file"
            echo "✅ $file saved to $OUTPUT_DIR/monitoring_$file"
        else
            echo "✅ $file directory found"
        fi
    fi
done
echo ""

# Summary
echo "📋 ANALYSIS COMPLETE"
echo "==================="
echo ""
echo "🎯 What I found:"
ls -la "$OUTPUT_DIR/"
echo ""
echo "📝 NEXT STEPS:"
echo "1. Share the contents of the files in the '$OUTPUT_DIR' directory"
echo "2. Provide a sample Monday.com webhook payload (JSON)"
echo "3. Let me know your Monday.com API credentials setup preference"
echo ""
echo "💡 TIP: You can run 'cat $OUTPUT_DIR/*' to see all files at once"
echo ""
echo "🚀 Once I have this info, I can help you build:"
echo "   • Monday.com API integration"
echo "   • Batch code generation logic"
echo "   • Database schema for code storage"
echo "   • Webhook payload processing"
echo "   • Error handling & retries"
echo "   • Performance optimizations"
echo ""
echo "✨ Ready to transform your foundation into a production batch code generator!"

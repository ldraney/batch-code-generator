#!/bin/bash
# scripts/deploy-production.sh

echo "🚀 DEPLOYING BATCH CODE GENERATOR TO PRODUCTION"
echo "=============================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Pre-deployment checks
echo ""
echo " Pre-deployment Checks"
echo "------------------------"

# Check if fly CLI is installed
if ! command -v flyctl &> /dev/null; then
    echo -e "${RED}❌ Fly CLI not installed${NC}"
    echo "Install: curl -L https://fly.io/install.sh | sh"
    exit 1
fi
echo -e "${GREEN}✅ Fly CLI installed${NC}"

# Check if logged into Fly
if ! flyctl auth whoami &> /dev/null; then
    echo -e "${RED}❌ Not logged into Fly.io${NC}"
    echo "Run: flyctl auth login"
    exit 1
fi
echo -e "${GREEN}✅ Logged into Fly.io${NC}"

# Check production environment file
if [ ! -f ".env.production" ]; then
    echo -e "${YELLOW}⚠️ .env.production not found${NC}"
    echo "Creating from template..."
    cp .env.production.example .env.production
    echo -e "${YELLOW}⚠️ Please edit .env.production with your production values${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Production environment file exists${NC}"

# Run tests
echo ""
echo "🧪 Running Tests"
echo "---------------"
npm run test:ci
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Tests failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ All tests passed${NC}"

# Build application
echo ""
echo "🏗️ Building Application"
echo "----------------------"
npm run build
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Build successful${NC}"

# Set production secrets
echo ""
echo "🔐 Setting Production Secrets"
echo "----------------------------"

# Read production environment variables
source .env.production

# Set secrets in Fly.io
echo "Setting secrets..."
flyctl secrets set \
  MONDAY_API_KEY="$MONDAY_API_KEY" \
  MONDAY_BATCH_CODE_COLUMN_ID="$MONDAY_BATCH_CODE_COLUMN_ID" \
  MONDAY_WEBHOOK_SECRET="$MONDAY_WEBHOOK_SECRET" \
  WEBHOOK_SECRET="$WEBHOOK_SECRET" \
  SENTRY_DSN="$SENTRY_DSN" \
  SENTRY_ORG="$SENTRY_ORG" \
  SENTRY_PROJECT="$SENTRY_PROJECT" \
  SENTRY_AUTH_TOKEN="$SENTRY_AUTH_TOKEN" \
  DATABASE_PATH="$DATABASE_PATH"

echo -e "${GREEN}✅ Secrets configured${NC}"

# Create volume for database persistence
echo ""
echo "💾 Setting Up Database Volume"
echo "----------------------------"

# Check if volume exists
if ! flyctl volumes list | grep -q "batch_codes_data"; then
    echo "Creating persistent volume for database..."
    flyctl volumes create batch_codes_data --size 1 --region sjc
    echo -e "${GREEN}✅ Database volume created${NC}"
else
    echo -e "${GREEN}✅ Database volume already exists${NC}"
fi

# Deploy to Fly.io
echo ""
echo "🚀 Deploying to Fly.io"
echo "---------------------"
flyctl deploy --remote-only

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi

# Get the deployed URL
APP_URL=$(flyctl info --json | jq -r '.Hostname')
if [ "$APP_URL" != "null" ]; then
    APP_URL="https://$APP_URL"
    echo -e "${GREEN}✅ Deployment successful${NC}"
    echo "App URL: $APP_URL"
else
    APP_URL="https://batch-code-generator.fly.dev"
    echo -e "${GREEN}✅ Deployment successful${NC}"
    echo "App URL: $APP_URL (default)"
fi

# Test deployment
echo ""
echo "🧪 Testing Deployment"
echo "--------------------"

echo "Testing health endpoint..."
sleep 10  # Wait for app to start

HEALTH_CHECK=$(curl -s "$APP_URL/api/health")
if echo "$HEALTH_CHECK" | grep -q "healthy"; then
    echo -e "${GREEN}✅ Health check passed${NC}"
else
    echo -e "${RED}❌ Health check failed${NC}"
    echo "Response: $HEALTH_CHECK"
fi

echo "Testing webhook endpoint..."
WEBHOOK_CHECK=$(curl -s "$APP_URL/api/webhook")
if echo "$WEBHOOK_CHECK" | grep -q "Monday.com"; then
    echo -e "${GREEN}✅ Webhook endpoint accessible${NC}"
else
    echo -e "${RED}❌ Webhook endpoint failed${NC}"
    echo "Response: $WEBHOOK_CHECK"
fi

# Display post-deployment information
echo ""
echo "🎉 DEPLOYMENT COMPLETE!"
echo "======================"
echo ""
echo "📊 Application Information:"
echo "  URL: $APP_URL"
echo "  Health: $APP_URL/api/health"
echo "  Metrics: $APP_URL/api/metrics"
echo "  Webhook: $APP_URL/api/webhook"
echo ""
echo "🔧 Monday.com Webhook Configuration:"
echo "  1. Go to your Monday.com board"
echo "  2. Board Settings → Integrations → Webhooks"
echo "  3. Add webhook URL: $APP_URL/api/webhook"
echo "  4. Select 'Item created' event"
echo "  5. Save webhook configuration"
echo ""
echo "📊 Monitoring Commands:"
echo "  flyctl logs           # View application logs"
echo "  flyctl ssh console    # Access production console"
echo "  flyctl status         # Check app status"
echo "  flyctl metrics        # View performance metrics"

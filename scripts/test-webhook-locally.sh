#!/bin/bash
# scripts/test-webhook-locally.sh
# Test the Monday.com webhook integration locally

echo "🧪 TESTING MONDAY.COM WEBHOOK LOCALLY"
echo "====================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load environment variables
if [ -f .env.local ]; then
    source .env.local
    echo -e "${GREEN}✅ Environment variables loaded${NC}"
else
    echo -e "${RED}❌ .env.local not found${NC}"
    exit 1
fi

# Check if dev server is running
if ! curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    echo -e "${RED}❌ Development server not running${NC}"
    echo "Please start it with: npm run dev"
    exit 1
fi

echo -e "${GREEN}✅ Development server is running${NC}"

# Test webhook with simulated Monday.com data
echo ""
echo "🔍 Testing webhook with simulated item creation..."
echo "------------------------------------------------"

RESPONSE=$(curl -s -X POST http://localhost:3000/api/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "event": {
      "type": "create_item",
      "data": {
        "item_id": "test-item-'$(date +%s)'",
        "item_name": "Test Batch Code Item",
        "board_id": "test-board-123",
        "group_id": "test-group-456"
      }
    }
  }')

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "success.*true"; then
    echo -e "${GREEN}✅ Webhook test successful!${NC}"
    
    # Extract batch code
    BATCH_CODE=$(echo "$RESPONSE" | grep -o '"batchCode":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$BATCH_CODE" ]; then
        echo -e "${BLUE}🎲 Generated batch code: $BATCH_CODE${NC}"
    fi
else
    echo -e "${RED}❌ Webhook test failed${NC}"
fi

echo ""
echo "🎯 If this works, you're ready to set up the real Monday.com webhook!"

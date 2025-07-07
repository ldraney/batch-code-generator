#!/bin/bash
# scripts/test-monday-api-direct.sh
# Test Monday.com API directly with your actual credentials

echo "🧪 TESTING MONDAY.COM API DIRECTLY"
echo "=================================="

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

# Check required variables
if [ -z "$MONDAY_API_KEY" ]; then
    echo -e "${RED}❌ MONDAY_API_KEY not set${NC}"
    exit 1
fi

if [ -z "$MONDAY_BATCH_CODE_COLUMN_ID" ]; then
    echo -e "${RED}❌ MONDAY_BATCH_CODE_COLUMN_ID not set${NC}"
    echo "Run: npm run monday:list-columns to find your column ID"
    exit 1
fi

echo -e "${BLUE}🔑 Using API Key: ${MONDAY_API_KEY:0:10}...${NC}"
echo -e "${BLUE}📋 Using Column ID: $MONDAY_BATCH_CODE_COLUMN_ID${NC}"

# Test 1: Basic API connection
echo ""
echo "🔍 Test 1: Basic API Connection"
echo "------------------------------"

API_TEST=$(curl -s -X POST https://api.monday.com/v2 \
  -H "Authorization: Bearer $MONDAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "query { me { id name email } }"}')

echo "Response: $API_TEST"

if echo "$API_TEST" | grep -q '"data"'; then
    echo -e "${GREEN}✅ API connection works${NC}"
    USER_NAME=$(echo "$API_TEST" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    echo "   Connected as: $USER_NAME"
else
    echo -e "${RED}❌ API connection failed${NC}"
    exit 1
fi

# Test 2: Get recent items from your boards
echo ""
echo "🔍 Test 2: Get Recent Items"
echo "--------------------------"

ITEMS_QUERY='{"query": "query { boards(limit: 5) { id name items(limit: 3) { id name column_values { id text value } } } }"}'

ITEMS_RESPONSE=$(curl -s -X POST https://api.monday.com/v2 \
  -H "Authorization: Bearer $MONDAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$ITEMS_QUERY")

echo "Recent items response:"
echo "$ITEMS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$ITEMS_RESPONSE"

# Extract some item IDs for testing
ITEM_IDS=$(echo "$ITEMS_RESPONSE" | grep -o '"id":"[0-9]*"' | cut -d'"' -f4 | head -3)

if [ -n "$ITEM_IDS" ]; then
    echo ""
    echo -e "${GREEN}✅ Found items to test with:${NC}"
    echo "$ITEM_IDS" | while read item_id; do
        echo "   Item ID: $item_id"
    done
    
    # Pick the first item for testing
    TEST_ITEM_ID=$(echo "$ITEM_IDS" | head -1)
    echo -e "${BLUE}🎯 Will test with Item ID: $TEST_ITEM_ID${NC}"
else
    echo -e "${YELLOW}⚠️ No items found. We'll use a fake ID for testing the API format${NC}"
    TEST_ITEM_ID="9529619040"  # From your webhook logs
fi

# Test 3: Try to update an item with batch code
echo ""
echo "🔍 Test 3: Update Item with Batch Code"
echo "-------------------------------------"

TEST_BATCH_CODE="TEST$(date +%s | tail -c 4)"
echo "Testing with batch code: $TEST_BATCH_CODE"

# Create the mutation query
UPDATE_QUERY=$(cat << EOF
{
  "query": "mutation { change_column_value (item_id: \"$TEST_ITEM_ID\", column_id: \"$MONDAY_BATCH_CODE_COLUMN_ID\", value: \"\\\"$TEST_BATCH_CODE\\\"\") { id } }"
}
EOF
)

echo ""
echo "Sending mutation:"
echo "$UPDATE_QUERY" | python3 -m json.tool 2>/dev/null || echo "$UPDATE_QUERY"

UPDATE_RESPONSE=$(curl -s -X POST https://api.monday.com/v2 \
  -H "Authorization: Bearer $MONDAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$UPDATE_QUERY")

echo ""
echo "Update response:"
echo "$UPDATE_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$UPDATE_RESPONSE"

if echo "$UPDATE_RESPONSE" | grep -q '"data"' && ! echo "$UPDATE_RESPONSE" | grep -q '"errors"'; then
    echo -e "${GREEN}✅ Successfully updated item with batch code!${NC}"
    echo "   Item ID: $TEST_ITEM_ID"
    echo "   Column ID: $MONDAY_BATCH_CODE_COLUMN_ID"
    echo "   Batch Code: $TEST_BATCH_CODE"
else
    echo -e "${RED}❌ Failed to update item${NC}"
    
    if echo "$UPDATE_RESPONSE" | grep -q '"errors"'; then
        echo ""
        echo "🔍 Error details:"
        echo "$UPDATE_RESPONSE" | grep -o '"message":"[^"]*"' | cut -d'"' -f4 | while read error_msg; do
            echo "   • $error_msg"
        done
    fi
    
    if echo "$UPDATE_RESPONSE" | grep -q "400"; then
        echo ""
        echo -e "${YELLOW}💡 Common 400 error causes:${NC}"
        echo "   • Wrong column ID format"
        echo "   • Column doesn't exist on this board"
        echo "   • API key lacks write permissions"
        echo "   • Item doesn't exist"
    fi
fi

# Test 4: Verify the column exists
echo ""
echo "🔍 Test 4: Verify Column Exists"
echo "------------------------------"

COLUMN_QUERY='{"query": "query { boards(limit: 10) { id name columns { id title type } } }"}'

COLUMN_RESPONSE=$(curl -s -X POST https://api.monday.com/v2 \
  -H "Authorization: Bearer $MONDAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$COLUMN_QUERY")

echo "Looking for column ID: $MONDAY_BATCH_CODE_COLUMN_ID"

if echo "$COLUMN_RESPONSE" | grep -q "\"$MONDAY_BATCH_CODE_COLUMN_ID\""; then
    echo -e "${GREEN}✅ Column ID found in your boards${NC}"
    
    # Show which board it's on
    echo "$COLUMN_RESPONSE" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    target_column = '$MONDAY_BATCH_CODE_COLUMN_ID'
    for board in data.get('data', {}).get('boards', []):
        for column in board.get('columns', []):
            if column.get('id') == target_column:
                print(f'   Found in board: {board.get(\"name\")} (ID: {board.get(\"id\")})')
                print(f'   Column name: {column.get(\"title\")}')
                print(f'   Column type: {column.get(\"type\")}')
except:
    pass
    "
else
    echo -e "${RED}❌ Column ID not found in any of your boards${NC}"
    echo ""
    echo "Available columns:"
    echo "$COLUMN_RESPONSE" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for board in data.get('data', {}).get('boards', []):
        print(f'Board: {board.get(\"name\")}')
        for column in board.get('columns', []):
            print(f'  {column.get(\"id\")} - {column.get(\"title\")} ({column.get(\"type\")})')
        print()
except:
    print('Could not parse response')
    "
fi

echo ""
echo "📊 SUMMARY"
echo "========="
echo ""
if echo "$UPDATE_RESPONSE" | grep -q '"data"' && ! echo "$UPDATE_RESPONSE" | grep -q '"errors"'; then
    echo -e "${GREEN}🎉 SUCCESS! Your Monday.com API integration is working!${NC}"
    echo ""
    echo "✅ API Key: Valid"
    echo "✅ Column ID: Correct"
    echo "✅ Permissions: Write access confirmed"
    echo ""
    echo "🚀 Your webhook should work now. Try creating another item!"
else
    echo -e "${YELLOW}⚠️ API test failed. Check the errors above.${NC}"
    echo ""
    echo "🔧 Next steps:"
    echo "1. Verify your MONDAY_BATCH_CODE_COLUMN_ID is correct"
    echo "2. Check API key permissions"
    echo "3. Ensure the column exists on the right board"
fi

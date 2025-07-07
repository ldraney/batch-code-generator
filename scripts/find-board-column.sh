#!/bin/bash
# scripts/find-board-columns-fixed.sh
# Find columns for a specific board ID (FIXED)

echo "🔍 FINDING COLUMNS FOR SPECIFIC BOARD"
echo "====================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load environment variables
source .env.local

# Board ID from your webhook logs
WEBHOOK_BOARD_ID="8768285252"

echo -e "${BLUE}🎯 Looking for board ID: $WEBHOOK_BOARD_ID${NC}"
echo ""

# Simple query for board columns only
echo "Fetching board columns..."
BOARD_RESPONSE=$(curl -s -X POST https://api.monday.com/v2 \
  -H "Authorization: Bearer $MONDAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"query { boards(ids: [$WEBHOOK_BOARD_ID]) { id name description columns { id title type } } }\"}")

echo ""
echo "Raw response:"
echo "$BOARD_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$BOARD_RESPONSE"

echo ""
echo "📋 BOARD DETAILS:"
echo "================="

# Parse and display board info
echo "$BOARD_RESPONSE" | python3 -c "
import json
import sys

try:
    data = json.load(sys.stdin)
    
    if 'errors' in data:
        print('❌ Error getting board:')
        for error in data['errors']:
            print(f'   {error.get(\"message\", \"Unknown error\")}')
        sys.exit(1)
    
    boards = data.get('data', {}).get('boards', [])
    
    if not boards:
        print('❌ Board not found or no access')
        sys.exit(1)
    
    board = boards[0]
    print(f'✅ Board found: {board.get(\"name\")}')
    print(f'   ID: {board.get(\"id\")}')
    if board.get('description'):
        print(f'   Description: {board.get(\"description\")}')
    
    print()
    print('📋 COLUMNS:')
    print('==========')
    
    columns = board.get('columns', [])
    if not columns:
        print('❌ No columns found')
    else:
        # Format as table
        print(f'{'Column ID':<25} {'Column Name':<30} {'Type':<15}')
        print('-' * 70)
        
        for col in columns:
            col_id = col.get('id', '')
            col_name = col.get('title', '')
            col_type = col.get('type', '')
            print(f'{col_id:<25} {col_name:<30} {col_type:<15}')
    
    print()
    print('💡 RECOMMENDATIONS:')
    print('==================')
    
    # Look for text columns
    text_columns = [col for col in columns if col.get('type') == 'text']
    
    if text_columns:
        print('✅ Available text columns for batch codes:')
        for col in text_columns:
            print(f'   {col.get(\"id\")} - {col.get(\"title\")}')
        print()
        print('🔧 To use one of these columns, add to .env.local:')
        print(f'   MONDAY_BATCH_CODE_COLUMN_ID={text_columns[0].get(\"id\")}')
    else:
        print('⚠️ No text columns found.')
        print('   You need to add a \"Batch Code\" text column to this board.')
    
    # Check if there's a name column we could use for testing
    name_col = next((col for col in columns if col.get('id') == 'name'), None)
    if name_col:
        print()
        print('🧪 For quick testing, you could use the name column:')
        print('   MONDAY_BATCH_CODE_COLUMN_ID=name')
        print('   (This will replace item names with batch codes)')
    
    print()
    print('📝 NEXT STEPS:')
    print('=============')
    print('1. Pick a column ID from above')
    print('2. Update .env.local: MONDAY_BATCH_CODE_COLUMN_ID=your_chosen_column_id')
    print('3. Test again: ./scripts/test-monday-api-direct.sh')

except Exception as e:
    print(f'❌ Error parsing response: {e}')
"

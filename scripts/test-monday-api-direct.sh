# Load your environment variables
source .env.local

# Test the API call directly with your correct IDs
curl -X POST https://api.monday.com/v2 \
  -H "Authorization: Bearer $MONDAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { change_column_value (item_id: \"9529619040\", column_id: \"text_mkpsv5qx\", value: \"\\\"TEST123\\\"\") { id } }"
  }'

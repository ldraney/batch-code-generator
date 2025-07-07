#!/bin/bash
# Stress test for batch code generation

source .env.local 2>/dev/null || true

if [ -z "$WEBHOOK_SECRET" ]; then
    echo "❌ WEBHOOK_SECRET not set in .env.local"
    exit 1
fi

echo "🚀 Running stress test for batch code generation..."
echo "Sending 10 concurrent webhook requests..."

for i in {1..10}; do
  curl -s -X POST http://localhost:3000/api/webhook \
    -H "Content-Type: application/json" \
    -H "x-webhook-signature: $WEBHOOK_SECRET" \
    -d "{\"event\":{\"type\":\"create_item\",\"data\":{\"item_id\":\"stress-test-$i-$(date +%s)\",\"item_name\":\"Stress Test Item $i\",\"board_id\":\"stress-board\",\"group_id\":\"stress-group\"}}}" &
done

wait
echo "✅ Stress test complete!"
echo "Check the database for generated batch codes:"
echo "npm run db:stats"

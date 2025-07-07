#!/bin/bash
# scripts/complete-setup.sh

echo "🎯 COMPLETE BATCH CODE GENERATOR SETUP"
echo "====================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command succeeded
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1 failed${NC}"
        exit 1
    fi
}

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Please run this script from the project root directory${NC}"
    exit 1
fi

# Make all scripts executable
echo ""
echo "🔧 Setting up scripts"
echo "--------------------"
chmod +x scripts/*.sh analysis_script.sh
check_success "Made scripts executable"

# Install new dependencies
echo ""
echo "📦 Installing Dependencies"
echo "-------------------------"
echo "Installing SQLite and types..."
npm install sqlite3 @types/sqlite3
check_success "Dependencies installed"

# Create directories
echo ""
echo "📁 Creating directories"
echo "----------------------"
mkdir -p data
mkdir -p src/lib
check_success "Directories created"

# Create database initialization SQL
echo ""
echo "🗃️ Creating database schema"
echo "--------------------------"
cat > init-database.sql << 'EOF'
-- Initialize batch codes database
PRAGMA foreign_keys = ON;

-- Table to store generated batch codes
CREATE TABLE IF NOT EXISTS batch_codes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code VARCHAR(10) NOT NULL UNIQUE,
  monday_item_id VARCHAR(50) NOT NULL,
  monday_board_id VARCHAR(50) NOT NULL,
  item_name TEXT,
  generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_code ON batch_codes(code);
CREATE INDEX IF NOT EXISTS idx_monday_item ON batch_codes(monday_item_id);
CREATE INDEX IF NOT EXISTS idx_generated_at ON batch_codes(generated_at);

-- Table to track webhook processing
CREATE TABLE IF NOT EXISTS webhook_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_type VARCHAR(50),
  monday_item_id VARCHAR(50),
  payload TEXT,
  status VARCHAR(20),
  error_message TEXT,
  processing_time_ms INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_webhook_status ON webhook_logs(status);
CREATE INDEX IF NOT EXISTS idx_webhook_created ON webhook_logs(created_at);

-- Insert initial test data
INSERT OR IGNORE INTO batch_codes (code, monday_item_id, monday_board_id, item_name) 
VALUES ('TEST1', 'test-item-1', 'test-board-1', 'Test Item');
EOF

# Initialize database
echo "Initializing SQLite database..."
if command -v sqlite3 &> /dev/null; then
    sqlite3 data/batch_codes.db < init-database.sql
    check_success "Database initialized"
else
    echo -e "${YELLOW}⚠️ SQLite not found. Database schema saved to init-database.sql${NC}"
    echo "   Install SQLite and run: sqlite3 data/batch_codes.db < init-database.sql"
fi

# Update package.json scripts
echo ""
echo "📋 Updating package.json scripts"
echo "--------------------------------"

# Create backup of package.json
cp package.json package.json.backup

# Add new scripts using Node.js
node << 'EOF'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));

// Add new scripts
const newScripts = {
  "setup:monday": "./scripts/setup-monday-integration.sh",
  "test:monday": "./scripts/test-monday-integration.sh", 
  "db:init": "mkdir -p data && sqlite3 data/batch_codes.db < init-database.sql",
  "db:query": "sqlite3 data/batch_codes.db",
  "db:stats": "sqlite3 data/batch_codes.db 'SELECT COUNT(*) as total_codes, COUNT(DISTINCT monday_board_id) as boards FROM batch_codes;'",
  "monday:test-connection": "node scripts/test-monday-connection.js",
  "stress:test": "./scripts/stress-test.sh"
};

pkg.scripts = { ...pkg.scripts, ...newScripts };

fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
console.log('✅ Package.json updated with new scripts');
EOF

check_success "Package.json scripts updated"

# Check environment configuration
echo ""
echo "🔧 Checking environment configuration"
echo "------------------------------------"

if [ ! -f ".env.local" ]; then
    echo -e "${YELLOW}⚠️ .env.local not found${NC}"
    if [ -f ".env.local.example" ]; then
        cp .env.local.example .env.local
        echo "✅ Created .env.local from example"
    else
        echo "❌ No .env.local.example found"
    fi
fi

# Check if Monday.com variables are set
source .env.local 2>/dev/null || true

echo "Checking required environment variables..."

if [ -z "$MONDAY_API_KEY" ]; then
    echo -e "${YELLOW}⚠️ MONDAY_API_KEY not set${NC}"
    echo "   Add your Monday.com API key to .env.local"
fi

if [ -z "$MONDAY_BATCH_CODE_COLUMN_ID" ]; then
    echo -e "${YELLOW}⚠️ MONDAY_BATCH_CODE_COLUMN_ID not set${NC}"
    echo "   Add your batch code column ID to .env.local"
fi

if [ -z "$WEBHOOK_SECRET" ]; then
    echo -e "${YELLOW}⚠️ WEBHOOK_SECRET not set${NC}"
    echo "   Add a webhook secret to .env.local"
fi

# Create a simple connection test script
echo ""
echo "🧪 Creating connection test script"
echo "---------------------------------"

cat > scripts/test-monday-connection.js << 'EOF'
const https = require('https');
require('dotenv').config({ path: '.env.local' });

const MONDAY_API_KEY = process.env.MONDAY_API_KEY;

if (!MONDAY_API_KEY) {
  console.log('❌ MONDAY_API_KEY not set in .env.local');
  process.exit(1);
}

const query = JSON.stringify({
  query: `
    query {
      me {
        id
        name
        email
      }
    }
  `
});

const options = {
  hostname: 'api.monday.com',
  path: '/v2',
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${MONDAY_API_KEY}`,
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(query)
  }
};

console.log('🧪 Testing Monday.com API connection...');

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => {
    if (res.statusCode === 200) {
      try {
        const result = JSON.parse(data);
        if (result.data && result.data.me) {
          console.log('✅ Monday.com API connection successful!');
          console.log(`   User: ${result.data.me.name} (${result.data.me.email})`);
          process.exit(0);
        } else if (result.errors) {
          console.log('❌ Monday.com API error:', result.errors[0].message);
          process.exit(1);
        }
      } catch (error) {
        console.log('❌ Failed to parse response:', error.message);
        process.exit(1);
      }
    } else {
      console.log(`❌ API request failed: ${res.statusCode} ${res.statusMessage}`);
      process.exit(1);
    }
  });
});

req.on('error', (error) => {
  console.log('❌ Connection error:', error.message);
  process.exit(1);
});

req.write(query);
req.end();
EOF

chmod +x scripts/test-monday-connection.js
check_success "Monday.com connection test script created"

# Create a simple stress test script
echo ""
echo "⚡ Creating stress test script"
echo "-----------------------------"

cat > scripts/stress-test.sh << 'EOF'
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
EOF

chmod +x scripts/stress-test.sh
check_success "Stress test script created"

# Final setup checks
echo ""
echo "🔍 Final setup verification"
echo "--------------------------"

# Check if TypeScript files need to be created
echo "📝 Note: You'll need to create the TypeScript modules manually:"
echo "   - src/lib/batch-codes.ts"
echo "   - src/lib/database.ts" 
echo "   - src/lib/monday.ts"
echo "   - src/lib/batch-code-processor.ts"
echo "   - Update src/app/api/webhook/route.ts"
echo ""
echo "   Use the TypeScript code from the previous artifacts."

# Summary
echo ""
echo "🎉 SETUP COMPLETE!"
echo "=================="
echo ""
echo "✅ What's been set up:"
echo "   • SQLite database initialized"
echo "   • Package.json scripts added"
echo "   • Test scripts created"
echo "   • Directory structure ready"
echo ""
echo "🔧 Next steps:"
echo "1. Add Monday.com credentials to .env.local:"
echo "   MONDAY_API_KEY=your_api_key"
echo "   MONDAY_BATCH_CODE_COLUMN_ID=your_column_id"
echo ""
echo "2. Copy the TypeScript code from the artifacts to create:"
echo "   • src/lib/batch-codes.ts"
echo "   • src/lib/database.ts"
echo "   • src/lib/monday.ts"
echo "   • src/lib/batch-code-processor.ts"
echo ""
echo "3. Update src/app/api/webhook/route.ts with the new implementation"
echo ""
echo "4. Test the connection:"
echo "   npm run monday:test-connection"
echo ""
echo "5. Run the full integration test:"
echo "   npm run test:monday"
echo ""
echo "6. Start development:"
echo "   npm run dev"
echo ""
echo "🎯 Ready to process Monday.com webhooks and generate batch codes!"

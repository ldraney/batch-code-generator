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

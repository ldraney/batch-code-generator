#!/usr/bin/env node
// scripts/list-monday-columns.js
// Lists all boards and their columns with IDs

const https = require('https');
require('dotenv').config({ path: '.env.local' });

const MONDAY_API_KEY = process.env.MONDAY_API_KEY;

if (!MONDAY_API_KEY) {
  console.log('❌ MONDAY_API_KEY not set in .env.local');
  process.exit(1);
}

// Function to make Monday.com API requests
function makeRequest(query, variables = {}) {
  return new Promise((resolve, reject) => {
    const requestBody = JSON.stringify({ query, variables });
    
    const options = {
      hostname: 'api.monday.com',
      path: '/v2',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${MONDAY_API_KEY}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(requestBody)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const result = JSON.parse(data);
          if (result.errors) {
            reject(new Error(`API Error: ${result.errors[0].message}`));
          } else {
            resolve(result.data);
          }
        } catch (error) {
          reject(new Error(`Parse Error: ${error.message}`));
        }
      });
    });

    req.on('error', reject);
    req.write(requestBody);
    req.end();
  });
}

// Function to format table
function formatTable(data, headers) {
  // Calculate column widths
  const widths = headers.map((header, i) => {
    const headerWidth = header.length;
    const dataWidth = Math.max(...data.map(row => String(row[i] || '').length));
    return Math.max(headerWidth, dataWidth);
  });

  // Create separator
  const separator = '+' + widths.map(w => '-'.repeat(w + 2)).join('+') + '+';
  
  // Format header
  const headerRow = '|' + headers.map((header, i) => 
    ` ${header.padEnd(widths[i])} `
  ).join('|') + '|';
  
  // Format data rows
  const dataRows = data.map(row => 
    '|' + row.map((cell, i) => 
      ` ${String(cell || '').padEnd(widths[i])} `
    ).join('|') + '|'
  );

  return [separator, headerRow, separator, ...dataRows, separator].join('\n');
}

async function listBoardsAndColumns() {
  try {
    // Check for board ID argument
    const args = process.argv.slice(2);
    const boardIdArg = args.find(arg => arg.startsWith('--board='));
    const specificBoardId = boardIdArg ? boardIdArg.split('=')[1] : null;

    if (specificBoardId) {
      console.log(`🔍 Fetching columns for board ID: ${specificBoardId}...\n`);
    } else {
      console.log('🔍 Fetching your Monday.com boards and columns...\n');
      console.log('💡 Tip: Use --board=BOARD_ID to show only one board\n');
    }

    // Build query based on whether we want specific board or all boards
    const boardsQuery = specificBoardId ? `
      query {
        boards(ids: [${specificBoardId}]) {
          id
          name
          description
          columns {
            id
            title
            type
            settings_str
          }
        }
      }
    ` : `
      query {
        boards(limit: 50) {
          id
          name
          description
          columns {
            id
            title
            type
            settings_str
          }
        }
      }
    `;

    const data = await makeRequest(boardsQuery);
    
    if (!data.boards || data.boards.length === 0) {
      if (specificBoardId) {
        console.log(`❌ Board with ID "${specificBoardId}" not found or no access.`);
        console.log('💡 Double-check the board ID or your API permissions.');
      } else {
        console.log('❌ No boards found. Make sure your API key has the right permissions.');
      }
      return;
    }

    if (specificBoardId) {
      console.log(`✅ Found board: ${data.boards[0].name}\n`);
    } else {
      console.log(`✅ Found ${data.boards.length} board(s)\n`);
    }

    // Display each board and its columns
    data.boards.forEach((board, boardIndex) => {
      if (!specificBoardId) {
        console.log(`📋 Board #${boardIndex + 1}: ${board.name}`);
        console.log(`   ID: ${board.id}`);
        if (board.description) {
          console.log(`   Description: ${board.description}`);
        }
        console.log('');
      } else {
        console.log(`📋 ${board.name} (ID: ${board.id})`);
        if (board.description) {
          console.log(`   Description: ${board.description}`);
        }
        console.log('');
      }

      if (board.columns && board.columns.length > 0) {
        const columnData = board.columns.map(col => [
          col.id,
          col.title,
          col.type,
          col.settings_str ? 'Yes' : 'No'
        ]);

        const table = formatTable(columnData, ['Column ID', 'Column Name', 'Type', 'Has Settings']);
        console.log(table);
        
        // If specific board, show copy-paste ready commands
        if (specificBoardId) {
          console.log('\n🎯 CHOOSE YOUR BATCH CODE COLUMN:');
          console.log('═'.repeat(40));
          
          const textColumns = board.columns.filter(col => 
            col.type === 'text' || col.type === 'long-text'
          );
          
          if (textColumns.length > 0) {
            console.log('\n✅ RECOMMENDED: Text columns (best for batch codes)');
            textColumns.forEach((col, index) => {
              console.log(`\n   ${index + 1}. "${col.title}" (${col.type})`);
              console.log(`      Column ID: ${col.id}`);
              console.log(`      To use: MONDAY_BATCH_CODE_COLUMN_ID="${col.id}"`);
            });
          }
          
          console.log('\n📋 OTHER COLUMNS (not recommended for batch codes):');
          const nonTextColumns = board.columns.filter(col => 
            col.type !== 'text' && col.type !== 'long-text'
          );
          
          nonTextColumns.forEach((col, index) => {
            console.log(`\n   ${index + 1}. "${col.title}" (${col.type})`);
            console.log(`      Column ID: ${col.id}`);
            console.log(`      To use: MONDAY_BATCH_CODE_COLUMN_ID="${col.id}"`);
          });
          
          console.log('\n💡 INSTRUCTIONS:');
          console.log('   1. Pick ONE column from above (preferably a text column)');
          console.log('   2. Copy its Column ID');
          console.log('   3. Add to your .env.local file:');
          console.log('      MONDAY_BATCH_CODE_COLUMN_ID="the_column_id_you_picked"');
          console.log('\n   Example if you pick the first text column:');
          if (textColumns.length > 0) {
            console.log(`   MONDAY_BATCH_CODE_COLUMN_ID="${textColumns[0].id}"`);
          }
        }
      } else {
        console.log('   No columns found');
      }
      
      if (!specificBoardId) {
        console.log('\n' + '='.repeat(80) + '\n');
      }
    });

    // Summary for easy copying (only if showing all boards)
    if (!specificBoardId) {
      console.log('📝 QUICK REFERENCE - Column IDs for .env.local:');
      console.log('=' .repeat(50));
      
      data.boards.forEach(board => {
        console.log(`\n📋 ${board.name} (Board ID: ${board.id}):`);
        board.columns.forEach(col => {
          const isTextType = col.type === 'text' || col.type === 'long-text';
          const indicator = isTextType ? '✅' : '  ';
          console.log(`   ${indicator} ${col.title.padEnd(20)} → ${col.id}`);
        });
      });

      console.log('\n💡 Look for a "Batch Code" column or similar text column.');
      console.log('   ✅ = Text columns (recommended for batch codes)');
      console.log('\n🔧 To use a column ID, add to your .env.local:');
      console.log('   MONDAY_BATCH_CODE_COLUMN_ID=your_column_id_here');
      console.log('\n🎯 To see details for a specific board:');
      console.log('   npm run monday:list-columns -- --board=BOARD_ID');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

// Run the script
listBoardsAndColumns();

/**
 * test_update_batch_code.js
 *
 * Purpose:
 * - Tests updating a Monday.com item's column with a generated batch code.
 * - Corrects GraphQL type usage: uses ID (string) instead of Int for board_id and item_id.
 *
 * Usage:
 *   MONDAY_API_KEY=your_key node test_update_batch_code.js
 *
 * Author: ChatGPT for Lucas Draney
 * Date: 2025-07-07
 */

import fetch from 'node-fetch';

const MONDAY_API_KEY = process.env.MONDAY_API_KEY;
const BOARD_ID = '8768285252'; // now a string
const ITEM_ID = '9529721663';  // now a string
const COLUMN_ID = 'text_mkpsv5qx';
const BATCH_CODE = 'OYQDT';

async function testUpdate() {
  const query = `
    mutation ($boardId: ID!, $itemId: ID!, $columnId: String!, $value: JSON!) {
      change_column_value(
        board_id: $boardId,
        item_id: $itemId,
        column_id: $columnId,
        value: $value
      ) {
        id
      }
    }
  `;

  const variables = {
    boardId: BOARD_ID,
    itemId: ITEM_ID,
    columnId: COLUMN_ID,
    value: JSON.stringify(BATCH_CODE),
  };

  try {
    const response = await fetch('https://api.monday.com/v2', {
      method: 'POST',
      headers: {
        'Authorization': MONDAY_API_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ query, variables }),
    });

    const data = await response.json();

    console.log('Raw Response:', JSON.stringify(data, null, 2));

    if (data.errors) {
      console.error('❌ Error updating Monday item:', data.errors);
    } else {
      console.log(`✅ Successfully updated item ${ITEM_ID} with batch code ${BATCH_CODE}`);
    }
  } catch (error) {
    console.error('❌ Request failed:', error);
  }
}

testUpdate();


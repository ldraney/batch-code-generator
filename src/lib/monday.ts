import { z } from 'zod';

// Monday.com webhook payload schemas - UPDATED to match real Monday.com webhooks
export const MondayWebhookSchema = z.object({
  challenge: z.string().optional(), // For webhook verification
  event: z.object({
    app: z.string().optional(),
    type: z.enum(['create_pulse', 'update_pulse', 'create_item', 'update_item']), // Monday uses "pulse" terminology
    triggerTime: z.string().optional(),
    subscriptionId: z.number().optional(),
    isRetry: z.boolean().optional(),
    userId: z.number().optional(),
    originalTriggerUuid: z.string().nullable().optional(),
    boardId: z.number().optional(),
    pulseId: z.number().optional(),        // Monday calls items "pulses"
    pulseName: z.string().optional(),      // Item name
    groupId: z.string().optional(),
    groupName: z.string().optional(),
    groupColor: z.string().optional(),
    isTopGroup: z.boolean().optional(),
    columnValues: z.record(z.any()).optional(),
    triggerUuid: z.string().optional(),
    // Legacy data structure support
    data: z.object({
      item_id: z.string(),
      board_id: z.string(),
      group_id: z.string(),
      item_name: z.string(),
      column_values: z.array(z.object({
        column_id: z.string(),
        value: z.any(),
        text: z.string().optional()
      })).optional()
    }).optional()
  }).optional()
});

export type MondayWebhookPayload = z.infer<typeof MondayWebhookSchema>;

// Helper function to normalize Monday.com webhook data
export function normalizeMondayWebhook(payload: MondayWebhookPayload) {
  if (!payload.event) return null;

  const { event } = payload;
  
  // Handle both old and new Monday.com webhook formats
  if (event.type === 'create_pulse' || event.type === 'create_item') {
    return {
      type: 'create_item',
      data: {
        item_id: event.data?.item_id || String(event.pulseId),
        item_name: event.data?.item_name || event.pulseName || 'Unknown Item',
        board_id: event.data?.board_id || String(event.boardId),
        group_id: event.data?.group_id || event.groupId || 'unknown',
        column_values: event.data?.column_values || []
      }
    };
  }
  
  if (event.type === 'update_pulse' || event.type === 'update_item') {
    return {
      type: 'update_item',
      data: {
        item_id: event.data?.item_id || String(event.pulseId),
        item_name: event.data?.item_name || event.pulseName || 'Unknown Item',
        board_id: event.data?.board_id || String(event.boardId),
        group_id: event.data?.group_id || event.groupId || 'unknown',
        column_values: event.data?.column_values || []
      }
    };
  }
  
  return null;
}

// Monday.com API client (unchanged)
export class MondayClient {
  private apiKey: string;
  private baseUrl = 'https://api.monday.com/v2';

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  /**
   * Execute a GraphQL query against Monday.com API
   */
  private async executeQuery(query: string, variables?: Record<string, any>) {
    const response = await fetch(this.baseUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
        'API-Version': '2023-10'
      },
      body: JSON.stringify({
        query,
        variables
      })
    });

    if (!response.ok) {
      throw new Error(`Monday.com API error: ${response.status} ${response.statusText}`);
    }

    const result = await response.json();
    
    if (result.errors) {
      throw new Error(`Monday.com GraphQL error: ${JSON.stringify(result.errors)}`);
    }

    return result.data;
  }

  /**
   * Update an item's column value (e.g., batch code column)
   */
/**
 * Update an item's column value (e.g., batch code column)
 */

  async updateItemColumn(
    boardId: string,
    itemId: string,
    columnId: string,
    value: string
  ): Promise<void> {
    // Correct: place inside function body
    await new Promise(resolve => setTimeout(resolve, 2000)); // 2 second delay

    const query = `
      mutation ($boardId: ID!, $itemId: ID!, $columnId: String!, $value: JSON!) {
        change_column_value (
          board_id: $boardId,
          item_id: $itemId,
          column_id: $columnId,
          value: $value
        ) {
          id
        }
      }
    `;

    const payloadValue = JSON.stringify({ text: value });

    await this.executeQuery(query, {
      boardId,
      itemId,
      columnId,
      value: payloadValue,
    });
  }

  /**
   * Get item details including current column values
   */
  async getItem(itemId: string): Promise<any> {
    const query = `
      query ($itemId: [ID!]!) {
        items (ids: $itemId) {
          id
          name
          board {
            id
            name
          }
          group {
            id
            title
          }
          column_values {
            id
            text
            value
          }
        }
      }
    `;

    const result = await this.executeQuery(query, { itemId: [itemId] });
    return result.items[0];
  }

  /**
   * Test API connection
   */
  async testConnection(): Promise<boolean> {
    try {
      const query = `
        query {
          me {
            id
            name
          }
        }
      `;
      
      await this.executeQuery(query);
      return true;
    } catch (error) {
      console.error('Monday.com API connection test failed:', error);
      return false;
    }
  }
}

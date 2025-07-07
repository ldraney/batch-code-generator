import { z } from 'zod';

// Monday.com webhook payload schemas
export const MondayWebhookSchema = z.object({
  challenge: z.string().optional(), // For webhook verification
  event: z.object({
    type: z.enum(['create_item', 'update_item']),
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
    })
  }).optional()
});

export type MondayWebhookPayload = z.infer<typeof MondayWebhookSchema>;

// Monday.com API client
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
  async updateItemColumn(
    itemId: string, 
    columnId: string, 
    value: string
  ): Promise<void> {
    const query = `
      mutation ($itemId: ID!, $columnId: String!, $value: JSON!) {
        change_column_value (
          item_id: $itemId,
          column_id: $columnId,
          value: $value
        ) {
          id
        }
      }
    `;

    await this.executeQuery(query, {
      itemId,
      columnId,
      value: JSON.stringify(value)
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

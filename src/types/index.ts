export interface HealthStatus {
  status: 'healthy' | 'unhealthy';
  timestamp: string;
  uptime: number;
  memory: {
    rss: number;
    heapTotal: number;
    heapUsed: number;
    external: number;
  };
  version: string;
  environment: string;
}

export interface WebhookPayload {
  event: string;
  data: {
    type: string;
    content?: string;
    language?: string;
    template?: string;
    batch_id?: string;
  };
  timestamp: string;
}

export interface CodeGenerationResponse {
  success: boolean;
  message: string;
  job_id: string;
  type: string;
  language: string;
}

export interface BatchJobResponse {
  success: boolean;
  message: string;
  batch_id: string;
  estimated_completion: string;
}

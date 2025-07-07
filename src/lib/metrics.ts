import { register, collectDefaultMetrics, Counter, Histogram, Gauge } from 'prom-client';

// Only initialize default metrics once
let defaultMetricsInitialized = false;

function initializeDefaultMetrics() {
  if (!defaultMetricsInitialized) {
    try {
      collectDefaultMetrics();
      defaultMetricsInitialized = true;
      console.log('✅ Prometheus default metrics initialized');
    } catch (error) {
      // If metrics are already registered, that's fine in development
      if (error.message?.includes('already been registered')) {
        console.log('⚠️  Prometheus metrics already registered (development mode)');
        defaultMetricsInitialized = true;
      } else {
        console.error('❌ Failed to initialize Prometheus metrics:', error);
      }
    }
  }
}

// Initialize default metrics
initializeDefaultMetrics();

// Custom metrics - use a factory pattern to avoid double registration
function createOrGetMetric<T>(
  metricName: string,
  MetricClass: any,
  config: any
): T {
  try {
    // Try to get existing metric first
    const existingMetric = register.getSingleMetric(metricName);
    if (existingMetric) {
      return existingMetric as T;
    }
    
    // Create new metric if it doesn't exist
    return new MetricClass(config);
  } catch (error) {
    if (error.message?.includes('already been registered')) {
      // Return the existing metric
      return register.getSingleMetric(metricName) as T;
    }
    throw error;
  }
}

// Custom metrics for the batch code generator
export const webhookRequestsTotal = createOrGetMetric<Counter<string>>(
  'webhook_requests_total',
  Counter,
  {
    name: 'webhook_requests_total',
    help: 'Total number of webhook requests received',
    labelNames: ['method', 'status', 'endpoint'],
  }
);

export const codeGenerationDuration = createOrGetMetric<Histogram<string>>(
  'code_generation_duration_seconds',
  Histogram,
  {
    name: 'code_generation_duration_seconds',
    help: 'Time spent generating code',
    labelNames: ['type', 'success'],
    buckets: [0.1, 0.5, 1, 2, 5, 10],
  }
);

export const activeCodeGenerationJobs = createOrGetMetric<Gauge<string>>(
  'active_code_generation_jobs',
  Gauge,
  {
    name: 'active_code_generation_jobs',
    help: 'Number of active code generation jobs',
  }
);

export const codeGenerationErrorsTotal = createOrGetMetric<Counter<string>>(
  'code_generation_errors_total',
  Counter,
  {
    name: 'code_generation_errors_total',
    help: 'Total number of code generation errors',
    labelNames: ['error_type'],
  }
);

export const batchJobsTotal = createOrGetMetric<Counter<string>>(
  'batch_jobs_total',
  Counter,
  {
    name: 'batch_jobs_total',
    help: 'Total number of batch jobs processed',
    labelNames: ['status'],
  }
);

export const batchJobDuration = createOrGetMetric<Histogram<string>>(
  'batch_job_duration_seconds',
  Histogram,
  {
    name: 'batch_job_duration_seconds',
    help: 'Time spent processing batch jobs',
    labelNames: ['job_type'],
    buckets: [1, 5, 10, 30, 60, 120, 300],
  }
);

// Helper functions for common metric operations
export function recordWebhookRequest(method: string, status: string, endpoint: string) {
  try {
    webhookRequestsTotal.inc({ method, status, endpoint });
  } catch (error) {
    console.warn('Failed to record webhook request metric:', error);
  }
}

export function recordCodeGeneration(type: string, success: boolean, duration: number) {
  try {
    codeGenerationDuration.observe({ type, success: success.toString() }, duration);
  } catch (error) {
    console.warn('Failed to record code generation metric:', error);
  }
}

export function incrementActiveJobs() {
  try {
    activeCodeGenerationJobs.inc();
  } catch (error) {
    console.warn('Failed to increment active jobs metric:', error);
  }
}

export function decrementActiveJobs() {
  try {
    activeCodeGenerationJobs.dec();
  } catch (error) {
    console.warn('Failed to decrement active jobs metric:', error);
  }
}

export function recordError(errorType: string) {
  try {
    codeGenerationErrorsTotal.inc({ error_type: errorType });
  } catch (error) {
    console.warn('Failed to record error metric:', error);
  }
}

export function recordBatchJob(status: string, jobType: string, duration: number) {
  try {
    batchJobsTotal.inc({ status });
    batchJobDuration.observe({ job_type: jobType }, duration);
  } catch (error) {
    console.warn('Failed to record batch job metrics:', error);
  }
}

// Export the register for metrics endpoint
export { register };

// Health check for metrics system
export function getMetricsHealth() {
  try {
    const metricNames = register.getMetricsAsArray().map(m => m.name);
    return {
      status: 'healthy',
      metricsCount: metricNames.length,
      customMetrics: [
        'webhook_requests_total',
        'code_generation_duration_seconds',
        'active_code_generation_jobs',
        'code_generation_errors_total',
        'batch_jobs_total',
        'batch_job_duration_seconds'
      ].filter(name => metricNames.includes(name)),
      defaultMetricsInitialized
    };
  } catch (error) {
    return {
      status: 'unhealthy',
      error: error.message,
      defaultMetricsInitialized
    };
  }
}

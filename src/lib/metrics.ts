import { register, collectDefaultMetrics, Counter, Histogram, Gauge } from 'prom-client';

collectDefaultMetrics();

export const webhookRequestsTotal = new Counter({
  name: 'webhook_requests_total',
  help: 'Total number of webhook requests received',
  labelNames: ['method', 'status', 'endpoint'],
});

export const codeGenerationDuration = new Histogram({
  name: 'code_generation_duration_seconds',
  help: 'Time spent generating code',
  labelNames: ['type', 'success'],
  buckets: [0.1, 0.5, 1, 2, 5, 10],
});

export const activeCodeGenerationJobs = new Gauge({
  name: 'active_code_generation_jobs',
  help: 'Number of active code generation jobs',
});

export const codeGenerationErrorsTotal = new Counter({
  name: 'code_generation_errors_total',
  help: 'Total number of code generation errors',
  labelNames: ['error_type'],
});

export const batchJobsTotal = new Counter({
  name: 'batch_jobs_total',
  help: 'Total number of batch jobs processed',
  labelNames: ['status'],
});

export const batchJobDuration = new Histogram({
  name: 'batch_job_duration_seconds',
  help: 'Time spent processing batch jobs',
  labelNames: ['job_type'],
  buckets: [1, 5, 10, 30, 60, 120, 300],
});

export function recordWebhookRequest(method: string, status: string, endpoint: string) {
  webhookRequestsTotal.inc({ method, status, endpoint });
}

export function recordCodeGeneration(type: string, success: boolean, duration: number) {
  codeGenerationDuration.observe({ type, success: success.toString() }, duration);
}

export function incrementActiveJobs() {
  activeCodeGenerationJobs.inc();
}

export function decrementActiveJobs() {
  activeCodeGenerationJobs.dec();
}

export function recordError(errorType: string) {
  codeGenerationErrorsTotal.inc({ error_type: errorType });
}

export function recordBatchJob(status: string, jobType: string, duration: number) {
  batchJobsTotal.inc({ status });
  batchJobDuration.observe({ job_type: jobType }, duration);
}

export { register };

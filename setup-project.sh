#!/bin/bash

echo "🚀 Creating complete batch-code-generator project..."

# Create .gitignore first
echo "📝 Creating .gitignore..."
cat > .gitignore << 'EOF'
# Dependencies
/node_modules
/.pnp
.pnp.js

# Testing
/coverage

# Next.js
/.next/
/out/

# Production
/build

# Misc
.DS_Store
*.pem

# Debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-debug.log*

# Local env files
.env
.env*.local
.env.development.local
.env.test.local
.env.production.local

# Vercel
.vercel

# TypeScript
*.tsbuildinfo
next-env.d.ts

# Logs
logs
*.log

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Docker
.dockerignore

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
Thumbs.db
.DS_Store

# Monitoring data (local volumes)
prometheus_data/
grafana_data/
grafana-storage/

# Sentry
.sentryclirc

# Temporary files
*.tmp
*.temp

# Build artifacts
dist/
build/

# Package manager
package-lock.json
yarn.lock
pnpm-lock.yaml

# Keep package-lock.json for this project
!package-lock.json
EOF

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p src/app/api/{webhook,health,metrics}
mkdir -p src/components/{ui,dashboard}
mkdir -p src/lib
mkdir -p src/types
mkdir -p monitoring/{prometheus,grafana/provisioning/{dashboards,datasources},grafana/dashboards}
mkdir -p scripts
mkdir -p docs
mkdir -p .github/workflows

# Create package.json
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "batch-code-generator",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "type-check": "tsc --noEmit",
    "docker:build": "docker build -t batch-code-generator .",
    "docker:dev": "docker-compose -f docker-compose.dev.yml up",
    "docker:monitoring": "docker-compose -f monitoring/docker-compose.monitoring.yml up",
    "setup": "chmod +x scripts/setup-dev.sh && ./scripts/setup-dev.sh"
  },
  "dependencies": {
    "next": "14.0.4",
    "react": "^18",
    "react-dom": "^18",
    "@sentry/nextjs": "^7.99.0",
    "prom-client": "^15.1.0",
    "zod": "^3.22.4",
    "date-fns": "^3.0.6",
    "clsx": "^2.1.0",
    "tailwind-merge": "^2.2.1"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "autoprefixer": "^10.0.1",
    "postcss": "^8",
    "tailwindcss": "^3.3.0",
    "eslint": "^8",
    "eslint-config-next": "14.0.4",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

# Create Next.js config
echo "⚙️ Creating Next.js configuration..."
cat > next.config.js << 'EOF'
const { withSentryConfig } = require('@sentry/nextjs');

/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverComponentsExternalPackages: ['prom-client'],
  },
  async rewrites() {
    return [
      {
        source: '/metrics',
        destination: '/api/metrics',
      },
    ];
  },
  async headers() {
    return [
      {
        source: '/api/health',
        headers: [
          {
            key: 'Cache-Control',
            value: 'no-store, max-age=0',
          },
        ],
      },
    ];
  },
};

const sentryWebpackPluginOptions = {
  silent: true,
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,
};

module.exports = withSentryConfig(nextConfig, sentryWebpackPluginOptions);
EOF

# Create Tailwind config
cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        popover: {
          DEFAULT: 'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))',
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
    },
  },
  plugins: [],
}
EOF

# Create PostCSS config
cat > postcss.config.js << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# Create TypeScript config
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/components/*": ["./src/components/*"],
      "@/lib/*": ["./src/lib/*"],
      "@/types/*": ["./src/types/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

# Create environment example
cat > .env.local.example << 'EOF'
# App Configuration
NODE_ENV=development
PORT=3000

# Sentry Configuration
SENTRY_DSN=https://your-dsn@sentry.io/project-id
SENTRY_ORG=your-org
SENTRY_PROJECT=batch-code-generator
SENTRY_AUTH_TOKEN=your-auth-token

# Webhook Configuration
WEBHOOK_SECRET=your-webhook-secret-here

# Monitoring Configuration
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001
GRAFANA_ADMIN_PASSWORD=admin

# Database (if needed later)
# DATABASE_URL=postgresql://user:password@localhost:5432/batch_code_generator

# External APIs (if needed)
# OPENAI_API_KEY=your-openai-key
# GITHUB_TOKEN=your-github-token
EOF

# Create globals.css
echo "🎨 Creating global styles..."
cat > src/app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 221.2 83.2% 53.3%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96%;
    --secondary-foreground: 222.2 84% 4.9%;
    --muted: 210 40% 96%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96%;
    --accent-foreground: 222.2 84% 4.9%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 221.2 83.2% 53.3%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 217.2 91.2% 59.8%;
    --primary-foreground: 222.2 84% 4.9%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 224.3 76.3% 94.1%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
EOF

# Create layout
echo "📄 Creating React components..."
cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Batch Code Generator',
  description: 'Generate code in batches via webhook',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  );
}
EOF

# Create main page
cat > src/app/page.tsx << 'EOF'
'use client';

import { useState, useEffect } from 'react';

interface HealthStatus {
  status: string;
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

export default function Home() {
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkHealth = async () => {
      try {
        const response = await fetch('/api/health');
        const data = await response.json();
        setHealth(data);
      } catch (error) {
        console.error('Failed to fetch health status:', error);
      } finally {
        setLoading(false);
      }
    };

    checkHealth();
    const interval = setInterval(checkHealth, 30000);
    return () => clearInterval(interval);
  }, []);

  const formatBytes = (bytes: number) => {
    return (bytes / 1024 / 1024).toFixed(2) + ' MB';
  };

  const formatUptime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    return `${hours}h ${minutes}m ${secs}s`;
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Batch Code Generator
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Generate code in batches via webhook. Monitor performance and track metrics in real-time.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
          <div className="bg-white rounded-lg shadow-sm p-6 border-l-4 border-green-500">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Status</p>
                <p className="text-2xl font-semibold text-green-600">
                  {health?.status || 'Unknown'}
                </p>
              </div>
              <div className="bg-green-100 rounded-full p-3">
                <svg className="h-6 w-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-sm p-6 border-l-4 border-blue-500">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Uptime</p>
                <p className="text-2xl font-semibold text-blue-600">
                  {health ? formatUptime(health.uptime) : '0h 0m 0s'}
                </p>
              </div>
              <div className="bg-blue-100 rounded-full p-3">
                <svg className="h-6 w-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-sm p-6 border-l-4 border-purple-500">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Memory Used</p>
                <p className="text-2xl font-semibold text-purple-600">
                  {health ? formatBytes(health.memory.heapUsed) : '0 MB'}
                </p>
              </div>
              <div className="bg-purple-100 rounded-full p-3">
                <svg className="h-6 w-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6 mb-12">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">API Endpoints</h2>
          <div className="space-y-4">
            <div className="border-l-4 border-green-500 pl-4">
              <h3 className="text-lg font-semibold text-gray-900">POST /api/webhook</h3>
              <p className="text-gray-600">Main webhook endpoint for code generation requests</p>
            </div>
            <div className="border-l-4 border-blue-500 pl-4">
              <h3 className="text-lg font-semibold text-gray-900">GET /api/health</h3>
              <p className="text-gray-600">Health check endpoint for monitoring</p>
            </div>
            <div className="border-l-4 border-purple-500 pl-4">
              <h3 className="text-lg font-semibold text-gray-900">GET /api/metrics</h3>
              <p className="text-gray-600">Prometheus metrics endpoint</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">Quick Links</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <a
              href="/api/health"
              className="block p-4 border border-gray-200 rounded-lg hover:border-blue-500 hover:shadow-md transition-all"
            >
              <h3 className="font-semibold text-gray-900">Health Status</h3>
              <p className="text-gray-600 text-sm">Check application health</p>
            </a>
            <a
              href="/api/metrics"
              className="block p-4 border border-gray-200 rounded-lg hover:border-blue-500 hover:shadow-md transition-all"
            >
              <h3 className="font-semibold text-gray-900">Metrics</h3>
              <p className="text-gray-600 text-sm">View Prometheus metrics</p>
            </a>
          </div>
        </div>

        <div className="mt-12 text-center text-gray-500">
          <p>Version: {health?.version} | Environment: {health?.environment}</p>
          <p className="mt-2">Last updated: {health?.timestamp}</p>
        </div>
      </div>
    </div>
  );
}
EOF

# Create library files
echo "📚 Creating library files..."
cat > src/lib/sentry.ts << 'EOF'
import * as Sentry from '@sentry/nextjs';

export function initSentry() {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    tracesSampleRate: 1.0,
    debug: process.env.NODE_ENV === 'development',
    integrations: [
      new Sentry.Integrations.Http({ tracing: true }),
    ],
    environment: process.env.NODE_ENV,
    beforeSend(event) {
      if (event.request?.url?.includes('/api/health')) {
        return null;
      }
      return event;
    },
  });
}

export function captureWebhookError(error: Error, context: Record<string, any>) {
  Sentry.withScope((scope) => {
    scope.setTag('component', 'webhook');
    scope.setContext('webhook_data', context);
    Sentry.captureException(error);
  });
}

export function captureMetrics(name: string, value: number, tags?: Record<string, string>) {
  Sentry.addBreadcrumb({
    message: `Metric: ${name}`,
    category: 'metric',
    data: { value, ...tags },
    level: 'info',
  });
}
EOF

cat > src/lib/metrics.ts << 'EOF'
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
EOF

cat > src/lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

export function formatUptime(seconds: number): string {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);
  
  if (days > 0) {
    return `${days}d ${hours}h ${minutes}m`;
  } else if (hours > 0) {
    return `${hours}h ${minutes}m ${secs}s`;
  } else {
    return `${minutes}m ${secs}s`;
  }
}
EOF

# Create type definitions
cat > src/types/index.ts << 'EOF'
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
EOF

# Create API routes
echo "🔌 Creating API endpoints..."
cat > src/app/api/health/route.ts << 'EOF'
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      version: process.env.npm_package_version || '0.1.0',
      environment: process.env.NODE_ENV || 'development',
    };

    return NextResponse.json(health, { status: 200 });
  } catch (error) {
    return NextResponse.json(
      { 
        status: 'unhealthy', 
        error: error instanceof Error ? error.message : 'Unknown error',
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}

export async function HEAD() {
  return new Response(null, { status: 200 });
}
EOF

cat > src/app/api/metrics/route.ts << 'EOF'
import { NextResponse } from 'next/server';
import { register } from '@/lib/metrics';

export async function GET() {
  try {
    const metrics = await register.metrics();
    
    return new NextResponse(metrics, {
      status: 200,
      headers: {
        'Content-Type': register.contentType,
        'Cache-Control': 'no-store, max-age=0',
      },
    });
  } catch (error) {
    console.error('Error collecting metrics:', error);
    return NextResponse.json(
      { error: 'Failed to collect metrics' },
      { status: 500 }
    );
  }
}
EOF

cat > src/app/api/webhook/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { recordWebhookRequest, recordCodeGeneration, incrementActiveJobs, decrementActiveJobs, recordError } from '@/lib/metrics';
import { captureWebhookError } from '@/lib/sentry';

const WebhookPayloadSchema = z.object({
  event: z.string(),
  data: z.object({
    type: z.string(),
    content: z.string().optional(),
    language: z.string().optional(),
    template: z.string().optional(),
    batch_id: z.string().optional(),
  }),
  timestamp: z.string(),
});

type WebhookPayload = z.infer<typeof WebhookPayloadSchema>;

export async function POST(request: NextRequest) {
  const startTime = Date.now();
  
  try {
    const signature = request.headers.get('x-webhook-signature');
    if (!signature || !verifyWebhookSignature(signature, request.body)) {
      recordWebhookRequest('POST', '401', '/api/webhook');
      return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
    }

    const body = await request.json();
    const payload = WebhookPayloadSchema.parse(body);
    const result = await handleWebhookEvent(payload);
    
    recordWebhookRequest('POST', '200', '/api/webhook');
    recordCodeGeneration(payload.data.type, true, (Date.now() - startTime) / 1000);
    
    return NextResponse.json(result, { status: 200 });
    
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    
    console.error('Webhook error:', error);
    captureWebhookError(error as Error, { request: request.url });
    
    recordWebhookRequest('POST', '500', '/api/webhook');
    recordError(error instanceof z.ZodError ? 'validation' : 'processing');
    
    return NextResponse.json(
      { error: errorMessage },
      { status: 500 }
    );
  }
}

async function handleWebhookEvent(payload: WebhookPayload) {
  incrementActiveJobs();
  
  try {
    switch (payload.event) {
      case 'code_generation_request':
        return await handleCodeGenerationRequest(payload.data);
      case 'batch_job_request':
        return await handleBatchJobRequest(payload.data);
      default:
        throw new Error(`Unknown event type: ${payload.event}`);
    }
  } finally {
    decrementActiveJobs();
  }
}

async function handleCodeGenerationRequest(data: WebhookPayload['data']) {
  await new Promise(resolve => setTimeout(resolve, 100));
  
  return {
    success: true,
    message: 'Code generation started',
    job_id: `gen_${Date.now()}`,
    type: data.type,
    language: data.language || 'javascript',
  };
}

async function handleBatchJobRequest(data: WebhookPayload['data']) {
  await new Promise(resolve => setTimeout(resolve, 500));
  
  return {
    success: true,
    message: 'Batch job queued',
    batch_id: data.batch_id || `batch_${Date.now()}`,
    estimated_completion: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
  };
}

function verifyWebhookSignature(signature: string, body: any): boolean {
  const expectedSignature = process.env.WEBHOOK_SECRET;
  return signature === expectedSignature;
}

export async function GET() {
  return NextResponse.json(
    { 
      message: 'Webhook endpoint is active',
      supportedEvents: ['code_generation_request', 'batch_job_request'],
      timestamp: new Date().toISOString(),
    },
    { status: 200 }
  );
}
EOF

# Create Docker files
echo "🐳 Creating Docker configuration..."
cat > Dockerfile << 'EOF'
FROM node:18-alpine AS base

FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build

FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

RUN mkdir .next
RUN chown nextjs:nodejs .next

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
EOF

cat > docker-compose.dev.yml << 'EOF'
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - WEBHOOK_SECRET=dev-secret-123
    volumes:
      - .:/app
      - /app/node_modules
      - /app/.next
    depends_on:
      - prometheus
    networks:
      - batch-generator

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    networks:
      - batch-generator

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
      - grafana-storage:/var/lib/grafana
    networks:
      - batch-generator

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    networks:
      - batch-generator

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    networks:
      - batch-generator

volumes:
  grafana-storage:

networks:
  batch-generator:
    driver: bridge
EOF

cat > .dockerignore << 'EOF'
node_modules
.next
.git
.gitignore
README.md
Dockerfile
.dockerignore
docker-compose*.yml
monitoring/
scripts/
docs/
.env*
npm-debug.log*
yarn-debug.log*
yarn-error.log*
EOF

# Create monitoring configuration
echo "📊 Creating monitoring configuration..."
cat > monitoring/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'batch-code-generator'
    static_configs:
      - targets: ['app:3000']
    metrics_path: '/api/metrics'
    scrape_interval: 5s
    scrape_timeout: 5s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
EOF

cat > monitoring/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

# Create setup script
echo "🔧 Creating setup script..."
cat > scripts/setup-dev.sh << 'EOF'
#!/bin/bash

echo "🚀 Setting up Batch Code Generator development environment..."

if [ ! -f .env.local ]; then
    echo "📝 Creating .env.local from example..."
    cp .env.local.example .env.local
    echo "✅ Created .env.local - please update with your actual values"
else
    echo "✅ .env.local already exists"
fi

echo "📦 Installing dependencies..."
npm install

echo "🔨 Building the application..."
npm run build

echo " Testing the setup..."
echo "Starting health check..."

npm run dev &
DEV_PID=$!

sleep 5

echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:3000/api/health)
if [ $? -eq 0 ]; then
    echo "✅ Health check passed"
    echo "Response: $HEALTH_RESPONSE"
else
    echo "❌ Health check failed"
fi

echo "Testing metrics endpoint..."
METRICS_RESPONSE=$(curl -s http://localhost:3000/api/metrics)
if [ $? -eq 0 ]; then
    echo "✅ Metrics endpoint working"
else
    echo "❌ Metrics endpoint failed"
fi

echo "Testing webhook endpoint..."
WEBHOOK_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "x-webhook-signature: dev-secret-123" \
    -d '{
        "event": "code_generation_request",
        "data": {
            "type": "component",
            "language": "typescript",
            "content": "test"
        },
        "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
    }' \
    http://localhost:3000/api/webhook)

if [ $? -eq 0 ]; then
    echo "✅ Webhook endpoint working"
    echo "Response: $WEBHOOK_RESPONSE"
else
    echo "❌ Webhook endpoint failed"
fi

kill $DEV_PID

echo ""
echo "🎉 Setup complete! Next steps:"
echo "1. Update .env.local with your Sentry DSN and other secrets"
echo "2. Run 'npm run dev' to start the development server"
echo "3. Run 'npm run docker:dev' to start with full monitoring stack"
echo "4. Visit http://localhost:3000 to see the application"
echo "5. Visit http://localhost:3001 for Grafana (admin/admin)"
echo "6. Visit http://localhost:9090 for Prometheus"
EOF

chmod +x scripts/setup-dev.sh

echo ""
echo "🎉 All files created successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Run: npm install"
echo "2. Run: npm run setup"
echo "3. Test with: npm run dev"
echo ""
echo "🚀 Ready to rock!"

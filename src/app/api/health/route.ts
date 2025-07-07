import { NextResponse } from 'next/server';

// Simple health check that includes system info
export async function GET() {
  try {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: {
        used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
        total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
        rss: Math.round(process.memoryUsage().rss / 1024 / 1024),
      },
      version: process.env.npm_package_version || '0.1.0',
      environment: process.env.NODE_ENV || 'development',
      platform: process.platform,
      nodeVersion: process.version,
      sentry: !!process.env.SENTRY_DSN,
      region: process.env.FLY_REGION || 'local',
      app: process.env.FLY_APP_NAME || 'development',
    };

    return NextResponse.json(health, { 
      status: 200,
      headers: {
        'Cache-Control': 'no-store, max-age=0',
        'X-Health-Check': 'true',
      },
    });
  } catch (error) {
    console.error('Health check error:', error);
    
    const errorResponse = {
      status: 'unhealthy',
      error: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString(),
    };

    return NextResponse.json(errorResponse, { status: 500 });
  }
}

// HEAD method for simple health checks
export async function HEAD() {
  try {
    // Simple memory check
    const memUsage = process.memoryUsage();
    if (memUsage.heapUsed > memUsage.heapTotal * 0.9) {
      return new Response(null, { status: 503 });
    }
    
    return new Response(null, { 
      status: 200,
      headers: {
        'X-Health-Check': 'true',
      },
    });
  } catch {
    return new Response(null, { status: 503 });
  }
}

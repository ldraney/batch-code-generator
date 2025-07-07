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
      <div className="min-h-screen bg-gray-50 flex items-center justify-center" data-testid="loading-state">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50" data-testid="dashboard">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Batch Code Generator
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Generate code in batches via webhook. Monitor performance and track metrics in real-time.
          </p>
        </div>

        {/* Status Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12" data-testid="status-cards">
          <div className="bg-white rounded-lg shadow-sm p-6 border-l-4 border-green-500" data-testid="status-card">
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

          <div className="bg-white rounded-lg shadow-sm p-6 border-l-4 border-blue-500" data-testid="status-card">
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

          <div className="bg-white rounded-lg shadow-sm p-6 border-l-4 border-purple-500" data-testid="status-card">
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

        {/* API Endpoints */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-12" data-testid="api-endpoints">
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

        {/* Quick Links */}
        <div className="bg-white rounded-lg shadow-sm p-6" data-testid="quick-links">
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

        {/* Footer */}
        <div className="mt-12 text-center text-gray-500" data-testid="footer">
          <p>Version: {health?.version} | Environment: {health?.environment}</p>
          <p className="mt-2">Last updated: {health?.timestamp}</p>
        </div>
      </div>
    </div>
  );
}

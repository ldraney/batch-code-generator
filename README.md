# Batch Code Generator

Generate code in batches via webhook with comprehensive monitoring and observability.

## 🚀 Features

- **🔗 Webhook API** - Robust endpoint for code generation requests
- **📊 Monitoring** - Prometheus metrics + Grafana dashboards  
- **🚨 Error Tracking** - Sentry integration for production reliability
- **🐳 Docker Ready** - Complete containerized development environment
- **☁️ Fly.io Deployment** - Production-ready cloud deployment

## 🏃‍♂️ Quick Start

```bash
# Clone and setup
git clone https://github.com/ldraney/batch-code-generator.git
cd batch-code-generator

# Install dependencies and setup
npm install
npm run setup

# Start development server
npm run dev
# OR start with full monitoring stack
npm run docker:dev
```

## 🔌 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/webhook` | POST | Main webhook endpoint for code generation |
| `/api/health` | GET | Health check endpoint |
| `/api/metrics` | GET | Prometheus metrics |

## 📊 Monitoring Dashboard

- **Application**: http://localhost:3000
- **Grafana**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9090

## 🧪 Test the Webhook

```bash
curl -X POST http://localhost:3000/api/webhook \
  -H "Content-Type: application/json" \
  -H "x-webhook-signature: dev-secret-123" \
  -d '{
    "event": "code_generation_request",
    "data": {
      "type": "component",
      "language": "typescript",
      "content": "Button component"
    },
    "timestamp": "2025-07-06T12:00:00Z"
  }'
```

## 🛠️ Development

Built with:
- **Next.js 14** - React framework with App Router
- **TypeScript** - Type-safe development
- **Tailwind CSS** - Utility-first styling
- **Prometheus** - Metrics collection
- **Grafana** - Monitoring dashboards
- **Sentry** - Error tracking
- **Docker** - Containerization

## 📁 Project Structure

```
batch-code-generator/
├── src/
│   ├── app/                 # Next.js App Router
│   ├── components/          # React components
│   ├── lib/                 # Utilities & configurations
│   └── types/               # TypeScript definitions
├── monitoring/              # Prometheus & Grafana configs
├── scripts/                 # Development scripts
└── docs/                    # Documentation
```

## 🚀 Deployment

Deploy to Fly.io with a single command:

```bash
npm run deploy
```

## 📚 Documentation

- [Setup Guide](docs/SETUP.md)
- [API Documentation](docs/API.md)
- [Deployment Guide](docs/DEPLOYMENT.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

# 🚀 Batch Code Generator

**A production-ready Next.js application template with comprehensive observability, testing, and monitoring.**

> **Template Status:** This is both a working batch code generator AND a reusable template for building robust web applications with enterprise-grade monitoring and testing.

## ✨ Features

- 🔗 **Webhook API** - Robust endpoints for code generation requests
- 📊 **Full Observability** - Prometheus metrics + Grafana dashboards + Sentry error tracking
- 🧪 **Comprehensive Testing** - Unit, integration, visual regression, and performance tests
- 🐳 **Docker Ready** - Complete containerized development environment
- ☁️ **Fly.io Deployment** - Production-ready cloud deployment configuration
- 🎯 **Template Ready** - Fork and adapt for new projects instantly

## 🏃‍♂️ Quick Start

```bash
# Clone the repository
git clone https://github.com/ldraney/batch-code-generator.git
cd batch-code-generator

# Install dependencies
npm install

# Set up environment
cp .env.local.example .env.local
# Edit .env.local with your configurations

# Run complete setup and validation
npm run setup

# Start development server
npm run dev
```

**🎉 Your app is now running at http://localhost:3000**

## 📋 Prerequisites

- **Node.js** 18+ 
- **npm** 8+
- **curl** (for API testing)
- **Docker** (for containerization - Phase 2)
- **Git** (for version control)

## 🧪 Testing Strategy

### **Complete Test Suite**

Run these commands to validate everything works:

```bash
# 🔬 Unit Tests - Core functionality
npm test

# 🏗️ Build Validation - Production readiness  
npm run build

# 🌐 Development Server - Local development
npm run dev

# 🔌 API Endpoint Tests - Manual verification
curl http://localhost:3000/api/health
curl http://localhost:3000/api/metrics

# 🔄 Full Regression Suite - Complete validation
npm run test:regression

# 👁️ Visual Regression - UI consistency
npm run test:visual

# ⚡ Performance Tests - Response time validation
npm run test:performance

# 💨 Smoke Tests - Critical path verification
npm run test:smoke
```

### **Test Categories**

| Test Type | Command | Purpose |
|-----------|---------|---------|
| **Unit** | `npm test` | Individual function testing |
| **Integration** | `npm run test:regression` | Full API flow testing |
| **Visual** | `npm run test:visual` | UI component validation |
| **Performance** | `npm run test:performance` | Response time benchmarks |
| **Smoke** | `npm run test:smoke` | Critical functionality verification |
| **Contracts** | `npm run test:contracts` | API schema validation |

## 🔌 API Endpoints

### **Core Endpoints**

| Endpoint | Method | Description | Test Command |
|----------|--------|-------------|--------------|
| `/api/health` | GET | Application health status | `curl localhost:3000/api/health` |
| `/api/metrics` | GET | Prometheus metrics | `curl localhost:3000/api/metrics` |
| `/api/webhook` | POST | Code generation webhook | See webhook testing below |

### **Webhook Testing**

```bash
# Test code generation request
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

# Test batch job request
curl -X POST http://localhost:3000/api/webhook \
  -H "Content-Type: application/json" \
  -H "x-webhook-signature: dev-secret-123" \
  -d '{
    "event": "batch_job_request",
    "data": {
      "type": "batch",
      "batch_id": "batch-123"
    },
    "timestamp": "2025-07-06T12:00:00Z"
  }'
```

## 📊 Monitoring & Observability

### **Local Monitoring Stack**

```bash
# Start full development stack with monitoring
npm run docker:dev
```

**Access Points:**
- **Application**: http://localhost:3000
- **Grafana Dashboard**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Application Metrics**: http://localhost:3000/api/metrics

### **Sentry Error Tracking**

1. **Sign up**: https://sentry.io
2. **Create project**: `batch-code-generator`
3. **Update .env.local**:
   ```bash
   SENTRY_DSN=https://your-dsn@sentry.io/project-id
   SENTRY_ORG=your-org-slug
   SENTRY_PROJECT=batch-code-generator
   ```
4. **Restart server**: `npm run dev`

## 🏗️ Project Structure

```
batch-code-generator/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── api/               # API endpoints
│   │   │   ├── health/        # Health check endpoint
│   │   │   ├── metrics/       # Prometheus metrics
│   │   │   └── webhook/       # Webhook processing
│   │   ├── layout.tsx         # Root layout
│   │   └── page.tsx           # Dashboard page
│   ├── lib/                   # Utilities & configurations
│   │   ├── metrics.ts         # Prometheus metrics setup
│   │   └── sentry.ts          # Sentry configuration
│   └── types/                 # TypeScript definitions
├── tests/
│   ├── jest-tests/            # Unit & integration tests
│   │   ├── unit/              # Unit tests
│   │   ├── integration/       # Integration tests
│   │   └── regression/        # Regression tests
│   └── playwright-tests/      # E2E & visual tests
├── monitoring/                # Monitoring configurations
│   ├── prometheus/            # Prometheus config
│   └── grafana/               # Grafana dashboards
├── scripts/                   # Development scripts
└── docs/                      # Documentation
```

## ⚙️ Configuration

### **Environment Variables**

```bash
# Copy example configuration
cp .env.local.example .env.local
```

**Required Configuration:**
```bash
# Webhook security
WEBHOOK_SECRET=your-webhook-secret-here

# Sentry (optional but recommended)
SENTRY_DSN=https://your-dsn@sentry.io/project-id
SENTRY_ORG=your-org-slug
SENTRY_PROJECT=batch-code-generator
```

### **Development Scripts**

| Script | Purpose |
|--------|---------|
| `npm run dev` | Start development server |
| `npm run build` | Build for production |
| `npm run start` | Start production server |
| `npm run setup` | Complete development setup |
| `npm run docker:dev` | Start with monitoring stack |
| `npm run capture:baselines` | Capture visual test baselines |

## 🚀 Deployment Pipeline

### **Phase 1: Local Development ✅**
- All tests passing
- Full monitoring stack
- Complete API coverage

### **Phase 2: Docker (Next)**
```bash
npm run docker:build
npm run docker:dev
```

### **Phase 3: Fly.io Production**
```bash
fly deploy
```

## 🧬 Using as a Template

This repository is designed to be a **reusable template**:

```bash
# Create new project from template
git clone https://github.com/ldraney/batch-code-generator.git my-new-project
cd my-new-project

# Update for your use case
# 1. Modify src/app/api/ endpoints
# 2. Update dashboard in src/app/page.tsx  
# 3. Customize monitoring in monitoring/
# 4. Run tests to ensure nothing breaks

npm test
npm run test:regression
```

**Template Benefits:**
- ✅ **Production-ready** observability out of the box
- ✅ **Comprehensive testing** for any modifications
- ✅ **Visual regression** catches UI changes
- ✅ **Performance monitoring** prevents degradation
- ✅ **Clean deployment** pipeline ready

## 🔧 Development Workflow

### **Daily Development**
```bash
# Start your day
npm run dev

# Make changes to code
# Run tests continuously
npm run test:watch

# Before committing
npm run test:regression
git add .
git commit -m "feat: your changes"
```

### **Before Deployment**
```bash
# Full validation
npm run build
npm run test:regression
npm run test:visual

# If all green ✅
npm run docker:build  # Phase 2
fly deploy            # Phase 3
```

## 📈 Metrics & Performance

### **Custom Metrics Tracked**
- **Webhook requests** - Success/failure rates
- **Code generation** - Duration and success rates  
- **Active jobs** - Current processing load
- **Error rates** - By error type
- **Response times** - API performance

### **Performance Thresholds**
- **Health endpoint**: < 100ms
- **Metrics endpoint**: < 500ms  
- **Webhook processing**: < 200ms
- **Memory usage**: Monitored and alerted

## 🐛 Troubleshooting

### **Common Issues**

**Tests failing?**
```bash
# Check if server is running
curl http://localhost:3000/api/health

# Restart with clean state
npm run dev
```

**Webhook 500 errors?**
```bash
# Check environment variables
grep WEBHOOK_SECRET .env.local

# Should match test signature: dev-secret-123
```

**Visual tests failing?**
```bash
# Capture new baselines
npm run capture:baselines

# Run visual tests
npm run test:visual
```

## 📚 Additional Resources

- **API Documentation**: [docs/API.md](docs/API.md)
- **Deployment Guide**: [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)
- **Testing Guide**: [docs/TESTING.md](docs/TESTING.md)
- **Monitoring Setup**: [docs/MONITORING.md](docs/MONITORING.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the full test suite: `npm run test:regression`
5. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🎯 Development Status

- ✅ **Phase 1**: Local Development Complete
- 🚧 **Phase 2**: Docker Configuration (Next)
- ⏳ **Phase 3**: Fly.io Deployment  
- ⏳ **Phase 4**: Feature Development

**Ready for containerization!** 🐳

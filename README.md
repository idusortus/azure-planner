# Azure DevOps & POC Research

**Purpose:** Exploratory workspace for learning and experimenting with Azure services using minimal resources and cost-optimized approaches.

## 🎯 Objectives

This workspace is dedicated to:
- **Re-familiarizing** with Azure services through hands-on POC projects
- **Cost optimization** - keeping expenses at $0-5/month using free tiers
- **Documentation** - creating reusable reference materials for Azure services
- **Experimentation** - building multiple POC applications with shared infrastructure

## 📚 Documentation

All Azure service research and reference materials are maintained in the [`/docs`](./docs) directory.

**Start here:** [Documentation Index](./docs/README.md)

### Key Resources
- [Azure SQL Database Free Tier Guide](./docs/azure-sql-free-tier.md) - Complete guide to free SQL databases

## 🚀 Target POC Projects

### 0. BudgetFriendlyAzureAdvisor Agent (NEW!)
**An AI agent that helps you research Azure services and keep costs minimal**
- **Built with:** .NET 10/C# + Microsoft Agent Framework
- **Capabilities:** Reads/writes Azure docs, researches services, calculates costs
- **Tools:** File system, Microsoft Learn MCP, cost calculator
- **Location:** [`src/BudgetFriendlyAzureAdvisor`](src/BudgetFriendlyAzureAdvisor)
- **Docs:** [Agent Documentation](docs/budget-friendly-azure-advisor-agent.md)

**Status:** ✅ Built and ready to use  
**Cost to run:** $1-3/month (Microsoft Foundry API calls only)

---

### 1. .NET Aspire Multi-Service Application
A comprehensive microservices architecture including:
- **.NET 10 WebAPI** - RESTful services
- **JavaScript SPA** - Modern frontend
- **Blazor WebAssembly** - Alternative SPA approach
- **Background Workers** - Microservice pattern demonstration
- **Azure SQL Database** - Data persistence
- **Message Orchestration** - Azure Service Bus and/or RabbitMQ/MassTransit

**Status:** 📋 Planning  
**Estimated Cost:** $0-3/month

### 2. Polymarket-Style Prediction App
A friendly prediction market application without real money:
- **Vanilla JavaScript** frontend
- **Node.js/Python API** backend
- **Azure SQL Database** for data persistence
- Friends-only access for entertainment

**Status:** 📋 Planning  
**Estimated Cost:** $0/month (within free tiers)

### 3. Static Web Apps
Various static websites and SPAs:
- Portfolio sites
- Documentation sites
- Landing pages
- Interactive demos

**Status:** 📋 Planning  
**Estimated Cost:** $0/month (free tier)

### 4. MCP Server
Model Context Protocol server implementation:
- Custom context providers
- Azure service integration
- Persistent state storage

**Status:** 📋 Planning  
**Estimated Cost:** $0-2/month

## 🏗️ Infrastructure Strategy

### Shared Resource Group Approach
All POC projects share a common resource group and infrastructure:

```
Resource Group: rg-shared-poc (East US)
│
├── SQL Server: sql-poc-shared
│   ├── db-aspire-app (32GB, Free tier)
│   ├── db-polymarket-clone (32GB, Free tier)
│   ├── db-spa-backend (32GB, Free tier)
│   └── [up to 10 free databases total]
│
├── Storage Account: stpocshared (Free tier)
│
├── Function Apps: (Consumption plan, Free tier)
│   └── Various serverless backends
│
└── Static Web Apps: (Free tier)
    └── Frontend hosting
```

**Benefits:**
- Centralized cost tracking
- Shared security and networking configuration
- Resource efficiency
- Simplified management

**Target Monthly Cost:** $0-5 total

## 💰 Cost Optimization Strategy

### Free Tier Priorities
1. **Azure SQL Database** - 10 free databases (32GB, 100K vCore-sec/mo each)
2. **Azure Static Web Apps** - Free tier with custom domains
3. **Azure Functions** - 1M requests/month free
4. **Azure Storage** - 5GB free
5. **Application Insights** - Basic monitoring free

### Auto-Pause & Scale-to-Zero
- SQL databases auto-pause when free compute is exhausted
- Serverless functions scale to zero when idle
- Container apps use consumption plan

### Monitoring
- Set budget alerts at $5/month
- Track free tier consumption per service
- Alert at 90% of free limits

## 🛠️ Development Setup

### Prerequisites
- Azure subscription (any type except Students Starter)
- Azure CLI installed
- .NET 10 SDK
- Node.js/npm
- Git

### Getting Started
1. Clone this repository
2. Review the [Documentation Index](./docs/README.md)
3. Follow service-specific setup guides in `/docs`
4. Deploy using Azure CLI or Portal

## 📖 Custom GitHub Copilot Instructions

This workspace uses custom GitHub Copilot instructions to optimize for:
- Cost-conscious Azure recommendations
- Free tier prioritization
- POC-appropriate architecture patterns
- Automatic documentation generation

See [`.github/copilot-instructions.md`](.github/copilot-instructions.md) for details.

## 🔄 Workflow

### Adding New Azure Service Research
1. Research the service (free tier, limits, pricing)
2. Create detailed markdown document in `/docs`
3. Update the documentation index
4. Test implementation with POC project
5. Document lessons learned

### Building New POC Project
1. Design with free tiers in mind
2. Use shared infrastructure where possible
3. Document architecture decisions
4. Implement incrementally
5. Monitor costs proactively

## 📊 Current Status

### Infrastructure
- [ ] Resource group created
- [ ] SQL logical server deployed
- [ ] First database provisioned
- [ ] Networking/firewall configured
- [ ] Monitoring/alerts set up

### Documentation
- [x] Custom Copilot instructions created
- [x] Documentation structure established
- [x] Azure SQL free tier documented
- [ ] Static Web Apps guide
- [ ] Azure Functions guide
- [ ] Service Bus guide

### Projects
- [ ] .NET Aspire app - Planning phase
- [ ] Polymarket clone - Planning phase
- [ ] Static sites - Planning phase
- [ ] MCP server - Planning phase

## 🤝 Contributing

This is a personal learning workspace, but the documentation may be useful to others exploring Azure on a budget. Feel free to reference or adapt materials for your own use.

## 📝 License

This repository is for personal educational purposes. Azure services and documentation are subject to Microsoft's terms of service and licensing.

---

**Last Updated:** January 13, 2026  
**Azure Subscription:** Cost-optimized for exploratory POC development

# Azure POC Research & Reference Documentation

**Purpose:** Cost-optimized Azure service research and implementation guides for proof-of-concept projects.

**Last Updated:** January 18, 2026

---

## 🚀 POC Deployment Documentation

> **START HERE** for deploying .NET Aspire applications to Azure

| Document | Purpose |
|----------|---------|
| [**⭐ MASTER**](MASTER.md) | **Quick reference - process overview, frameworks, CLI vs Bicep** |
| [**📋 CHECKLIST**](poc-deployment/CHECKLIST.md) | Step-by-step deployment checklist |
| [**📖 GUIDE**](poc-deployment/GUIDE.md) | Comprehensive explanations and detailed instructions |
| [**🏛️ DECISIONS**](poc-deployment/DECISIONS.md) | Architecture Decision Records (ADRs) with rationale |
| [**📦 Bicep Templates**](../azd-bicep/README.md) | Infrastructure as Code for repeatable deployments |

**Stack:** .NET 10 Aspire • Azure SQL Serverless (schema isolation) • Container Apps • Static Web Apps • ACR

**Cost Achieved:** ~$5-10/month for 3 POCs combined ✅

---

## 📊 Live POCs

| POC | API | Frontend | Schema |
|-----|-----|----------|--------|
| TodoApp | [API](https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/todos) | [Web](https://happy-desert-065eace10.6.azurestaticapps.net) | `todo` |
| LeaveACommentApp | [API](https://leave-a-comment-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/comments) | [Web](https://nice-sand-0b0628510.6.azurestaticapps.net) | `comments` |
| FriendsPrediction | [API](https://friends-prediction-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/events) | [Web](https://kind-pebble-0eeaa2310.2.azurestaticapps.net) | `predictions` |

---

## 📋 Quick Reference Index

### 🤖 AI Agents & Tools
- [**Deployed Resources Tracking**](deployed-resources.md) - Live inventory of all Azure resources
- [**Quick Start: Agent Setup**](quick-start-agent.md) - Get the agent running in 5 minutes
- [**Using with GitHub Copilot**](using-agent-with-github-copilot.md) - MCP server integration
- [**Corporate Security Workaround**](corporate-security-workaround.md) - Running .NET apps in restricted environments

### Database Services
- [**Azure SQL Database Free Tier**](Azure/Planning/azure-sql-free-tier.md) - Complete guide to free SQL databases
- [**SQL Credentials**](sql-credentials.md) - Connection strings and credentials

### Compute Services
*Coming soon: Azure Functions, Azure Container Apps deep-dive*

### Messaging & Integration
*Coming soon: Azure Service Bus, Event Grid*
*Coming soon: Azure Key Vault, Application Insights, MCP Server hosting*

---

## 🎯 Documentation Categories

### By Service Type

#### 💾 Data & Storage
- [Azure SQL Database Free Tier](azure-sql-free-tier.md) - Serverless databases at no cost

#### ⚡ Compute
- *Azure Functions* - Planned
- *Azure Static Web Apps* - Planned
- *Azure Container Apps* - Planned
- *Azure App Service* - Planned

#### 📨 Messaging
- *Azure Service Bus* - Planned
- *Azure Event Grid* - Planned

#### 🔐 Security & Identity
- *Azure Key Vault* - Planned
- *Managed Identity* - Planned

#### 📊 Monitoring
- *Application Insights Free Tier* - Planned
- *Azure Monitor* - Planned

### By Cost Level

#### 🆓 Completely Free (with limits)
- [Azure SQL Database](azure-sql-free-tier.md) - 10 databases, 32GB each, 100K vCore-sec/mo each

#### 💰 Very Low Cost ($0-5/month)
- *To be documented*

#### 💵 Low Cost ($5-20/month)
- *To be documented*

### By Use Case

#### .NET Aspire Applications
- [Azure SQL Database](azure-sql-free-tier.md) - Primary data persistence
- *Azure Service Bus* - Message orchestration (Planned)
- *Azure Functions* - Background workers (Planned)
- *Azure Static Web Apps* - Frontend hosting (Planned)

#### JavaScript Applications
- [Azure SQL Database](azure-sql-free-tier.md) - API backend persistence
- *Azure Static Web Apps* - Frontend hosting (Planned)
- *Azure Functions* - Serverless API (Planned)

#### Static Web Apps
- *Azure Static Web Apps* - Full hosting solution (Planned)
- [Azure SQL Database](azure-sql-free-tier.md) - Optional backend data

#### MCP Servers
- [Azure SQL Database](azure-sql-free-tier.md) - State/context storage
- *Azure Functions* - Runtime hosting (Planned)
- *Azure Container Apps* - Container hosting (Planned)

---

## 🏗️ Architecture Patterns

### Shared Resource Group Pattern
Using a single resource group and logical SQL server for multiple POC projects:

```
Resource Group: rg-shared-poc
├── Logical SQL Server: sql-poc-shared
│   ├── db-aspire-app
│   ├── db-polymarket-clone
│   ├── db-spa-backend
│   ├── db-worker-state
│   └── db-mcp-storage
├── Storage Account: stpocshared
├── Static Web App: swa-poc-frontend
└── Function App: func-poc-workers
```

**Benefits:**
- Centralized cost tracking
- Shared firewall/security rules
- Simplified management
- Resource quota efficiency

**Estimated Monthly Cost:** $0-5 using free tiers

---

## 📝 Document Templates

### Service Reference Template
When creating new service documentation:

```markdown
# [Service Name]

**Last Updated:** [Date]
**Cost Level:** [Free / Very Low / Low]
**Service Tier:** [Specific tier/plan]

## Overview
[Brief description]

## Key Features
[Bullet points]

## Cost Analysis
[Detailed breakdown]

## Limitations
[What to watch out for]

## Implementation Steps
[Step-by-step guide]

## Use Cases for This Workspace
[Specific POC scenarios]

## Monitoring & Optimization
[How to track usage and costs]

## Troubleshooting
[Common issues]

## Related Documentation
[Links]

## Changelog
[Update history]
```

---

## 🔍 Research Methodology

When researching a new Azure service:

1. **Identify free tier availability** and limits
2. **Calculate cost estimates** for typical POC usage
3. **Document limitations** that might affect POCs
4. **Provide implementation steps** with Azure CLI and Portal options
5. **Create reference document** using template above
6. **Update this index** with new entry

---

## 💡 Cost Optimization Principles

### Golden Rules
1. **Free first** - Exhaust all free tier options before considering paid
2. **Serverless preferred** - Pay only for what you use
3. **Auto-pause/scale-to-zero** - Enable wherever possible
4. **Shared infrastructure** - One SQL server, many databases
5. **Monitor proactively** - Set alerts at 80-90% of free limits
6. **Region lock awareness** - Free resources often locked to initial region

### Monthly Budget Target
**Goal:** $0-5/month for all POC projects combined

**Strategy:**
- Maximum use of free tiers
- Serverless compute that auto-pauses
- Consumption-based pricing
- Regional resource consolidation

---

## 🚀 Quick Start Guides

### Setting Up First POC Project

1. **Create Resource Group**
   ```bash
   az group create --name rg-shared-poc --location eastus
   ```

2. **Set Up SQL Server**
   - Follow [Azure SQL Database Free Tier](azure-sql-free-tier.md) guide
   - Create logical server first
   - Add databases as needed

3. **Configure Networking**
   - Set firewall rules for development IP
   - Enable Azure service access
   - Document connection strings

4. **Deploy Application**
   - Use Azure Static Web Apps for frontend
   - Azure Functions for serverless APIs
   - Connect to SQL database

---

## 📚 External Resources

### Official Documentation
- [Azure Free Account](https://azure.microsoft.com/free/)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure Architecture Center](https://learn.microsoft.com/azure/architecture/)

### Cost Management
- [Azure Cost Management](https://azure.microsoft.com/services/cost-management/)
- [Azure Advisor](https://azure.microsoft.com/services/advisor/)

---

## 📊 Service Comparison Matrix

| Service | Free Tier | Best For | Monthly Limit | Cost if Exceeded |
|---------|-----------|----------|---------------|------------------|
| SQL Database | ✅ Yes | Relational data | 100K vCore-sec, 32GB | ~$4.78+ |
| Functions | ✅ Yes | Serverless compute | 1M requests, 400K GB-sec | ~$0.20/M requests |
| Static Web Apps | ✅ Yes | Frontend hosting | 100GB bandwidth | $9/month after |
| Service Bus | ⚠️ Basic | Messaging | Pay per operation | ~$0.05/M operations |
| Storage | ✅ Yes | Object storage | 5GB, 20K transactions | ~$0.02/GB |

*To be expanded as services are researched*

---

## 🎯 Target Projects Status

### Project: .NET Aspire Multi-Service App
- [x] Database solution identified (Azure SQL Free)
- [ ] API hosting solution (Azure Functions/Container Apps)
- [ ] Frontend hosting (Azure Static Web Apps)
- [ ] Message bus (Azure Service Bus/RabbitMQ)
- [ ] Background workers (Azure Functions)

### Project: Polymarket Clone
- [x] Database solution identified (Azure SQL Free)
- [ ] API hosting (Azure Functions)
- [ ] Frontend hosting (Azure Static Web Apps)

### Project: Static Web Apps
- [ ] Hosting solution (Azure Static Web Apps)

### Project: MCP Server
- [ ] Runtime hosting (Azure Functions/Container Apps)
- [x] Storage solution (Azure SQL Free)

---

## ✅ Contribution Guidelines

When adding new documentation:

1. Use the service reference template
2. Include current pricing (verify date)
3. Calculate POC-specific cost estimates
4. Provide both Portal and CLI implementation steps
5. Add entry to this README in all relevant sections
6. Update comparison matrices
7. Link from related documents

---

## 📞 Support & Questions

This is a personal research repository. For Azure support:
- [Azure Documentation](https://learn.microsoft.com/azure/)
- [Azure Support](https://azure.microsoft.com/support/)
- [Azure Community](https://techcommunity.microsoft.com/azure)

---

*This index is automatically maintained as new research documentation is added.*

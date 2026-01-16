# PoC Platform Roadmap

**Date**: January 16, 2026  
**Target**: 4-5 concurrent PoC applications  
**Monthly Budget**: $30-60

## Architecture Overview

```
Shared (centralus)                    Per-PoC Resource Groups
├── Azure SQL Server ─────────────┬── poc-betting-rg
│   ├── poc-betting-db            │   ├── Container App (API)
│   ├── poc-chat-db               │   ├── Static Web App (Frontend)
│   └── poc-inventory-db          │   └── Custom domain
├── Service Bus (wiscoshared) ────┼── poc-chat-rg
│   ├── poc-betting-queue         │   ├── Container App (API)
│   └── poc-chat-queue            │   ├── Static Web App (Frontend)
└── Container Apps Environment ───┘   └── Custom domain
```

---

## Phase 1: Shared Infrastructure

Resources in existing `Shared` resource group.

### 1.1 Azure SQL Server
- **Status**: To be created
- **Tier**: Serverless General Purpose (auto-pause 60 min)
- **Cost**: ~$0 when paused, ~$0.50/hr when active
- **Action**: Create logical server, configure firewall

### 1.2 Service Bus
- **Status**: Exists (`wiscoshared`)
- **Action**: Verify tier, plan queue naming convention

### 1.3 Container Apps Environment
- **Status**: To be created
- **Tier**: Consumption (no base cost)
- **Action**: Create environment for hosting all PoC APIs

**Phase 1 Cost**: ~$5-15/month (SQL storage + minimal compute)

---

## Phase 2: Per-PoC Resource Pattern

Each PoC application follows this template.

### Resource Group Contents

| Resource | Tier | Monthly Cost | Purpose |
|----------|------|--------------|---------|
| Container App | Consumption | $0.50-5 | .NET WebAPI backend |
| Static Web App | Free | $0 | SPA frontend |
| SQL Database | Serverless | $5-15 | Data persistence |
| Service Bus Queue | Shared | ~$0 | Async messaging |

### Repository Structure (Aspire)

```
poc-{name}/
├── src/
│   ├── {Name}.AppHost/           # Aspire orchestrator
│   ├── {Name}.ServiceDefaults/   # Aspire shared config
│   ├── {Name}.Api/               # .NET 10 WebAPI
│   └── {Name}.Web/               # Frontend (if not separate)
├── infra/
│   └── main.bicep                # Azure infrastructure
├── .github/
│   └── workflows/
│       └── deploy.yml            # CI/CD to Azure
└── README.md
```

### Connection to Shared Resources

Each PoC connects to shared infrastructure via:
- **SQL**: Dedicated database on shared server (connection string in Key Vault or app settings)
- **Service Bus**: Dedicated queue(s) in shared namespace
- **Container Apps**: Deployed to shared environment

### Deployment Pipeline

1. Build .NET API → Container image
2. Push to Azure Container Registry (or GitHub Container Registry)
3. Deploy Container App revision
4. Deploy Static Web App (separate workflow)

### Graduation Path

When a PoC gains traction:
1. Create dedicated resource group
2. Create dedicated SQL Server + database
3. Create dedicated Service Bus namespace
4. Scale Container App (increase min replicas, CPU/memory)
5. Update connection strings
6. Delete from shared infrastructure

---

## Phase 3: First PoC Setup

### Steps to Create First PoC

1. **Create shared SQL Server** (if not exists)
2. **Create Container Apps Environment** (if not exists)
3. **Create PoC resource group**: `poc-{name}-rg`
4. **Create SQL database**: `poc-{name}-db` on shared server
5. **Create Service Bus queue**: `poc-{name}-events`
6. **Create Aspire project** from template
7. **Configure Container App** deployment
8. **Create Static Web App** linked to frontend repo/folder
9. **Configure custom domain** (optional)
10. **Document in deployed-resources.md**

### Estimated Timeline

| Task | Duration |
|------|----------|
| Shared infrastructure setup | 1-2 hours |
| First PoC scaffolding | 2-3 hours |
| CI/CD pipeline | 1-2 hours |
| Subsequent PoCs | 30-60 min each |

---

## Cost Summary

### Monthly Estimates (5 PoCs, light traffic)

| Component | Cost |
|-----------|------|
| SQL Server (5 serverless DBs) | $25-50 |
| Container Apps (5 apps, scale-to-zero) | $2-25 |
| Static Web Apps (5 free tier) | $0 |
| Service Bus (shared, basic tier) | $1-5 |
| **Total** | **$28-80** |

With auto-pause and scale-to-zero, expect closer to $30-40/month for light PoC usage.

---

## Next Actions

- [ ] Create Azure SQL Server in Shared resource group
- [ ] Create Container Apps Environment in Shared resource group
- [ ] Define naming conventions for databases, queues, apps
- [ ] Create Aspire project template for PoCs
- [ ] Document deployment workflow
- [ ] Create first PoC (betting app?)

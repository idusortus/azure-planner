# POC Deployment Documentation

**Purpose**: Repeatable process for deploying .NET Aspire + JavaScript frontend + Azure SQL POC applications.

## 📁 Document Index

| Document | Purpose | When to Use |
|----------|---------|-------------|
| [**CHECKLIST.md**](CHECKLIST.md) | Quick step-by-step checklist | During deployment - follow along |
| [**GUIDE.md**](GUIDE.md) | In-depth explanations | Learning, troubleshooting, decision-making |
| [**DECISIONS.md**](DECISIONS.md) | Architecture decisions log | Understanding why choices were made |

## 🎯 Target Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Cloud                               │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐     ┌──────────────────────────────────┐ │
│  │  Static Web App  │────▶│  Container App (.NET 10 API)     │ │
│  │  (Free Tier)     │     │  (Consumption - scale to zero)   │ │
│  │  Vanilla JS SPA  │     │                                  │ │
│  └──────────────────┘     └──────────────┬───────────────────┘ │
│                                          │                      │
│                                          ▼                      │
│                           ┌──────────────────────────────────┐ │
│                           │  Azure SQL (Serverless)          │ │
│                           │  Shared Server: dev-wiscodev     │ │
│                           │  Per-POC databases               │ │
│                           └──────────────────────────────────┘ │
│                                                                 │
│  ┌──────────────────┐     ┌──────────────────────────────────┐ │
│  │ Container        │     │  Log Analytics                   │ │
│  │ Registry (Shared)│     │  (auto-created per environment)  │ │
│  └──────────────────┘     └──────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 💰 Cost Target

| Component | Service | Monthly Cost |
|-----------|---------|--------------|
| Frontend | Static Web Apps (Free) | $0 |
| Backend | Container Apps (Consumption) | $0-2 |
| Database | Azure SQL Serverless | $0-5 |
| Registry | Container Registry (Basic, shared) | ~$5 total |
| **Per-POC Total** | | **$0-7** |

## 📂 Related Files

### Infrastructure Templates
- [`/apps/todo-app/`](../../apps/todo-app/) - Example infrastructure scripts

### Copilot Integration
- [`/.github/prompts/create-new-poc.prompt.md`](../../.github/prompts/create-new-poc.prompt.md) - Prompt for new POC creation

### Live Example
- [`/TestPOCApp/TodoApp/`](../../TestPOCApp/TodoApp/) - Complete working example

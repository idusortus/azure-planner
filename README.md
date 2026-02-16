# Azure POC Research & Development

Budget-friendly Azure POC workspace. 3 live applications running for ~$5-10/month total.

## Live POCs

| POC | Stack | API | Frontend |
|-----|-------|-----|----------|
| **TodoApp** | .NET 10 Aspire + Vanilla JS | [API](https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io) | [SWA](https://happy-desert-065eace10.6.azurestaticapps.net) |
| **LeaveACommentApp** | .NET 10 Aspire + Vanilla JS | [API](https://leave-a-comment-api.politeriver-ded1b871.centralus.azurecontainerapps.io) | [SWA](https://nice-sand-0b0628510.6.azurestaticapps.net) |
| **FriendsPrediction** | .NET 10 Aspire + Vanilla JS | [API](https://friends-prediction-api.politeriver-ded1b871.centralus.azurecontainerapps.io) | [SWA](https://kind-pebble-0eeaa2310.2.azurestaticapps.net) |

## Shared Infrastructure

| Resource | Name | Cost |
|----------|------|------|
| SQL Server | `dev-wiscodev` (centralus) | $0 |
| Database | `sandbox` (free tier, schema-per-POC) | $0 |
| Container Registry | `wiscodevacr` (Basic) | ~$5/mo |
| Container Apps Env | `todoapp-env` (consumption) | $0 |
| Service Bus | `wiscoshared` | varies |

## Repository Structure

```
docs/
  MASTER.md                    # THE deployment reference (start here)
  deployed-resources.md        # Full Azure resource inventory
  poc-deployment/DECISIONS.md  # Architecture decision records
  Azure/Planning/              # Historical research docs
apps/
  todo-app/                    # Infrastructure scripts + config
  leave-a-comment-app/
  friends-prediction/
TestPOCApp/
  TodoApp/                     # .NET Aspire solution (complete)
  LeaveACommentApp/            # .NET Aspire solution (skeleton)
src/
  BudgetFriendlyAzureAdvisor/  # MCP agent for Azure research
azd-bicep/                     # Bicep templates (optional IaC)
```

## Getting Started

**Deploy a new POC**: Read [docs/MASTER.md](docs/MASTER.md) — covers the full process from local app to deployed Azure resources.

**Scaffold with Copilot**: Use the [create-new-poc prompt](.github/prompts/create-new-poc.prompt.md) in VS Code.

## Key Documentation

| Document | Purpose |
|----------|---------|
| [MASTER.md](docs/MASTER.md) | Single source of truth for deployment |
| [deployed-resources.md](docs/deployed-resources.md) | All Azure resources with cleanup commands |
| [DECISIONS.md](docs/poc-deployment/DECISIONS.md) | 15 ADRs with rationale |
| [azure-sql-free-tier.md](docs/azure-sql-free-tier.md) | Free SQL tier research |

## MCP Agent

[BudgetFriendlyAzureAdvisor](src/BudgetFriendlyAzureAdvisor/) — .NET 10 MCP server for Azure research and cost optimization.

```bash
# Build
cd src/BudgetFriendlyAzureAdvisor && dotnet build -c Release

# Run (HTTP mode)
dotnet bin/Release/net10.0/BudgetFriendlyAzureAdvisor.dll

# Run (MCP mode for Copilot)
dotnet bin/Release/net10.0/BudgetFriendlyAzureAdvisor.dll --mcp
```

## Prerequisites

- Azure subscription + Azure CLI (`az login`)
- .NET 10 SDK
- Docker Desktop
- Git Bash (on Windows)

---

**Last Updated:** February 15, 2026  
**Subscription:** Azure subscription 1 (`e4b6b908-fa56-4b92-9e9c-5b0c855d13fe`)  
**Monthly Cost:** ~$5-10 total

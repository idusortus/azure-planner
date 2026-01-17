# Deployed Azure Resources

**Subscription**: Azure subscription 1 (e4b6b908-fa56-4b92-9e9c-5b0c855d13fe)  
**Primary Region**: centralus  
**Last Updated**: January 17, 2026

## Current Resources

### Resource Group: Shared
- **Type**: Resource Group
- **Location**: centralus
- **Created**: Pre-existing
- **Purpose**: Shared resources for POC projects (SQL Server, Service Bus)
- **Status**: Active ✅
- **Estimated Cost**: $0/month (container only)

### SQL Server: dev-wiscodev
- **Type**: Microsoft.Sql/servers
- **Resource Group**: Shared
- **Location**: centralus
- **Purpose**: Shared SQL Server for all POC databases
- **Status**: Active ✅
- **Admin User**: sqladmin
- **Estimated Cost**: $0/month (server is free, only DBs cost)

### Service Bus Namespace: wiscoshared
- **Type**: Microsoft.ServiceBus/namespaces
- **Resource Group**: Shared
- **Location**: centralus
- **Created**: Pre-existing
- **Purpose**: Message queue for microservices communication
- **Status**: Active ✅
- **Estimated Cost**: Depends on tier (check with `az servicebus namespace show`)
- **Query Command**:
  ```bash
  az servicebus namespace show --name wiscoshared --resource-group Shared --output table
  ```

---

## POC: friends-prediction

### Resource Group: friends-prediction
- **Type**: Resource Group
- **Location**: centralus
- **Created**: January 16, 2026
- **Purpose**: Friends prediction betting app POC
- **Status**: Active ✅

### Database: friends-prediction-db
- **Type**: Microsoft.Sql/databases
- **Resource Group**: Shared (on dev-wiscodev server)
- **Location**: centralus
- **Tier/SKU**: General Purpose, Serverless (Gen5, 0.5-1 vCores)
- **Created**: January 16, 2026
- **Purpose**: Database for friends-prediction POC
- **Estimated Cost**: $0-5/month (auto-pause 60 min)
- **Status**: Active ✅
- **Cleanup Command**:
  ```bash
  az sql db delete --name friends-prediction-db --server dev-wiscodev --resource-group Shared --yes
  ```

### Static Web App: friends-prediction-web
- **Type**: Microsoft.Web/staticSites
- **Resource Group**: friends-prediction
- **Location**: centralus
- **Tier/SKU**: Free
- **URL**: https://icy-moss-06e338310.6.azurestaticapps.net
- **Created**: January 16, 2026
- **Purpose**: Frontend hosting for friends-prediction POC
- **Estimated Cost**: $0/month
- **Status**: Active ✅

### Storage Account: friendspredictionsa
- **Type**: Microsoft.Storage/storageAccounts
- **Resource Group**: friends-prediction
- **Location**: centralus
- **Tier/SKU**: Standard_LRS
- **Created**: January 16, 2026
- **Purpose**: Blob storage for friends-prediction POC
- **Estimated Cost**: ~$0.02/month
- **Status**: Active ✅

---

## POC: todo-app

### Resource Group: todo-app
- **Type**: Resource Group
- **Location**: centralus
- **Created**: January 17, 2026
- **Purpose**: TODO app test POC
- **Status**: Active ✅

### Database: todo-app-db
- **Type**: Microsoft.Sql/databases
- **Resource Group**: Shared (on dev-wiscodev server)
- **Location**: centralus
- **Tier/SKU**: General Purpose, Serverless (Gen5, 0.5-1 vCores)
- **Created**: January 17, 2026
- **Purpose**: Database for todo-app POC
- **Estimated Cost**: $0-5/month (auto-pause 60 min)
- **Status**: Active ✅
- **Cleanup Command**:
  ```bash
  az sql db delete --name todo-app-db --server dev-wiscodev --resource-group Shared --yes
  ```

### Static Web App: todo-app-web
- **Type**: Microsoft.Web/staticSites
- **Resource Group**: todo-app
- **Location**: centralus
- **Tier/SKU**: Free
- **URL**: https://happy-desert-065eace10.6.azurestaticapps.net
- **Created**: January 17, 2026
- **Purpose**: Frontend hosting for todo-app POC
- **Estimated Cost**: $0/month
- **Status**: Active ✅ (Pending frontend deployment)
- **Deployment Token**: See `apps/todo-app/azure-static-web-config.json`
- **Cleanup Command**:
  ```bash
  az staticwebapp delete --name todo-app-web --resource-group todo-app --yes
  ```

### Container Registry: wiscodevacr
- **Type**: Microsoft.ContainerRegistry/registries
- **Resource Group**: Shared
- **Location**: centralus
- **Tier/SKU**: Basic
- **Login Server**: wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io
- **Created**: January 17, 2026
- **Purpose**: Shared container registry for all POC Docker images
- **Estimated Cost**: ~$0.17/day ($5/month)
- **Status**: Active ✅
- **Admin Enabled**: Yes
- **Cleanup Command**:
  ```bash
  az acr delete --name wiscodevacr --resource-group Shared --yes
  ```

### Container Apps Environment: todoapp-env
- **Type**: Microsoft.App/managedEnvironments
- **Resource Group**: todo-app
- **Location**: Central US
- **Created**: January 17, 2026
- **Purpose**: Container Apps hosting environment
- **Default Domain**: politeriver-ded1b871.centralus.azurecontainerapps.io
- **Static IP**: 20.221.48.64
- **Log Analytics**: workspace-todoappBEfK (auto-created)
- **Estimated Cost**: $0/month (consumption-based)
- **Status**: Active ✅
- **Cleanup Command**:
  ```bash
  az containerapp env delete --name todoapp-env --resource-group todo-app --yes
  ```

### Container App: todoapp-api
- **Type**: Microsoft.App/containerApps
- **Resource Group**: todo-app
- **Location**: Central US
- **Image**: wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/todoapp-api:latest
- **Created**: January 17, 2026
- **Purpose**: TODO App .NET 10 API backend
- **URL**: https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io
- **Health Check**: https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/health
- **API Endpoint**: https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/todos
- **Scaling**: Min 0, Max 1 replicas (scale-to-zero enabled)
- **Estimated Cost**: $0-2/month (pay-per-use, scales to zero)
- **Status**: Active ✅ LIVE AND WORKING
- **Cleanup Command**:
  ```bash
  az containerapp delete --name todoapp-api --resource-group todo-app --yes
  ```

### Log Analytics Workspace: todoapp-logs
- **Type**: Microsoft.OperationalInsights/workspaces
- **Resource Group**: todo-app
- **Location**: centralus
- **Created**: January 17, 2026
- **Purpose**: Logging for Container Apps (manually created, auto-created used instead)
- **Retention**: 30 days
- **Estimated Cost**: ~$0-1/month (based on data ingestion)
- **Status**: Active ✅
- **Note**: Container Apps environment auto-created its own workspace (workspace-todoappBEfK)

---

## Resource Creation Log

_Resources created via GitHub Copilot will be documented here automatically_

### Template
```markdown
## {Resource Name}
- **Type**: {Azure Resource Type}
- **Resource Group**: {RG Name}
- **Location**: {Region}
- **Tier/SKU**: {Pricing Tier}
- **Created**: {Date}
- **Purpose**: {Description}
- **Estimated Cost**: ${amount}/month
- **Status**: Active ✅ / Paused ⏸️ / Deleted ❌
- **Cleanup Command**: 
  ```bash
  az {type} delete --name {name} --resource-group {rg} --yes
  ```
```

---

## Cost Summary

**Current Month Estimated**: ~$5-7/month  
**Target**: $0-7/month for all POC resources

### Cost Breakdown by Service

| Service | Resource | Monthly Cost |
|---------|----------|--------------|
| Azure SQL (Serverless) | friends-prediction-db | $0-5 |
| Azure SQL (Serverless) | todo-app-db | $0-5 |
| Container Registry | wiscodevacr | ~$5 |
| Container Apps | todoapp-api | $0-2 |
| Static Web Apps | friends-prediction-web | $0 |
| Static Web Apps | todo-app-web | $0 |
| Log Analytics | Various workspaces | $0-1 |
| **Total** | | **~$5-13** |

**Notes**:
- SQL databases use serverless tier with 60-min auto-pause
- Container Apps scale to zero when idle
- ACR Basic tier is the main fixed cost (~$5/month)

---

## Cleanup Commands

To remove all POC resources (⚠️ use with caution):

```bash
# List all resources first
az resource list --resource-group Shared --output table

# Delete specific resources (replace with actual names)
# az sql db delete --name {db-name} --server {server} --resource-group Shared --yes
# az webapp delete --name {app-name} --resource-group Shared --yes

# ⚠️ NUCLEAR OPTION - Delete entire resource group
# az group delete --name Shared --yes --no-wait
```

---

## Notes

- All resources should be tagged with `project=azure-planner`
- Prefer serverless/consumption tiers for cost optimization
- Use auto-pause on SQL databases (60-minute delay)
- Review costs weekly: `az consumption usage list --output table`

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
- **Status**: Active ✅

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

**Current Month Estimated**: $0.00  
**Target**: $0-5/month for all POC resources

### Cost Breakdown by Service
_Will be updated as resources are created_

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

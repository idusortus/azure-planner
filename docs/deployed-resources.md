# Deployed Azure Resources

**Subscription**: Azure subscription 1 (e4b6b908-fa56-4b92-9e9c-5b0c855d13fe)  
**Primary Region**: centralus  
**Last Updated**: January 16, 2026

## Current Resources

### Resource Group: Shared
- **Type**: Resource Group
- **Location**: centralus
- **Created**: Pre-existing
- **Purpose**: Shared resources for POC projects
- **Status**: Active ✅
- **Estimated Cost**: $0/month (container only)

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

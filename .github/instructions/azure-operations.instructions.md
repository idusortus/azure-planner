---
applyTo: "**"
---

# Azure Resource Management Operations

**ACTIVE SESSION**: Authenticated with Azure CLI  
**Subscription**: Azure subscription 1 (e4b6b908-fa56-4b92-9e9c-5b0c855d13fe)  
**User**: samuel.johnson.wi@gmail.com

## Authentication Status

This session is configured with active Azure CLI authentication. All `az` commands will use the logged-in user's credentials.

### Verifying Authentication

Before any Azure operation, verify authentication:
```bash
az account show
```

If authentication expires:
```bash
az login
```

## Resource Creation Guidelines

### Pre-Creation Checklist
1. ✅ Verify authentication is active
2. ✅ Check if resource already exists
3. ✅ Calculate estimated monthly cost
4. ✅ Identify appropriate resource group (prefer existing: `Shared`)
5. ✅ Choose optimal region (existing: `centralus`)
6. ✅ Select free/low-cost tier when available
7. ✅ Plan resource naming convention

### Naming Conventions
Use descriptive, purpose-driven names:
- Resource Groups: `{purpose}-{env}` (e.g., `poc-dev`, `shared-resources`)
- SQL Servers: `{app}-sql-{region}` (e.g., `polymarket-sql-centralus`)
- Databases: `{app}-db` (e.g., `polymarket-db`)
- Web Apps: `{app}-web-{env}` (e.g., `polymarket-web-poc`)
- Storage: `{app}storage{region}` (e.g., `polymarketstorageus`)

### Standard Tags
Apply these tags to all created resources:
```bash
--tags \
  project=azure-planner \
  cost-center=poc \
  created-by=github-copilot \
  created-date=$(date +%Y-%m-%d) \
  purpose={description}
```

## Resource Operations Patterns

### Creating Resource Groups
```bash
# Always check if exists first
az group show --name {resource-group-name} 2>/dev/null || \
az group create \
  --name {resource-group-name} \
  --location centralus \
  --tags project=azure-planner cost-center=poc
```

### Creating Azure SQL Database (Free Tier)
```bash
# Create SQL Server (if doesn't exist)
az sql server create \
  --name {server-name} \
  --resource-group Shared \
  --location centralus \
  --admin-user sqladmin \
  --admin-password {secure-password} \
  --enable-public-network true

# Create free-tier database
az sql db create \
  --resource-group Shared \
  --server {server-name} \
  --name {database-name} \
  --edition GeneralPurpose \
  --compute-model Serverless \
  --family Gen5 \
  --capacity 1 \
  --auto-pause-delay 60 \
  --min-capacity 0.5 \
  --backup-storage-redundancy Local \
  --zone-redundant false
```

### Creating Static Web App (Free Tier)
```bash
az staticwebapp create \
  --name {app-name} \
  --resource-group Shared \
  --location centralus \
  --sku Free \
  --source {github-repo-url} \
  --branch main \
  --app-location "/" \
  --api-location "api" \
  --output-location "dist"
```

### Creating Azure Functions (Consumption Plan)
```bash
# Create storage account (required for Functions)
az storage account create \
  --name {storage-name} \
  --resource-group Shared \
  --location centralus \
  --sku Standard_LRS \
  --kind StorageV2

# Create Function App
az functionapp create \
  --name {function-app-name} \
  --resource-group Shared \
  --consumption-plan-location centralus \
  --runtime dotnet-isolated \
  --runtime-version 8 \
  --functions-version 4 \
  --storage-account {storage-name} \
  --os-type Windows
```

## Query Operations

### List All Resources
```bash
# By resource group
az resource list --resource-group Shared --output table

# By type
az resource list --resource-type Microsoft.Sql/servers --output table

# All resources in subscription
az resource list --output table
```

### Check Resource Costs
```bash
# Cost by resource group (last 30 days)
az consumption usage list \
  --start-date $(date -d '30 days ago' +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query "[?properties.instanceName contains 'Shared'].{Name:properties.instanceName, Cost:properties.pretaxCost, Currency:properties.currency}" \
  --output table
```

### Check Resource Status
```bash
# SQL Database status
az sql db show \
  --name {db-name} \
  --server {server-name} \
  --resource-group Shared \
  --query "{Name:name, Status:status, Tier:sku.tier, Capacity:sku.capacity}" \
  --output table

# Web App status
az webapp show \
  --name {app-name} \
  --resource-group Shared \
  --query "{Name:name, State:state, Location:location, Tier:sku}" \
  --output table
```

## Modification Operations

### Scale Resources
```bash
# Scale SQL Database (serverless tier)
az sql db update \
  --name {db-name} \
  --server {server-name} \
  --resource-group Shared \
  --capacity {new-capacity} \
  --max-size {new-size}

# Scale Web App
az webapp update \
  --name {app-name} \
  --resource-group Shared \
  --set sku.name=F1  # Free tier
```

### Update Configuration
```bash
# Add connection string to Web App
az webapp config connection-string set \
  --name {app-name} \
  --resource-group Shared \
  --connection-string-type SQLAzure \
  --settings DefaultConnection="{connection-string}"

# Add app settings
az webapp config appsettings set \
  --name {app-name} \
  --resource-group Shared \
  --settings KEY1=value1 KEY2=value2
```

## Deletion Operations

**CRITICAL**: Always confirm before deleting resources

### Safe Deletion Pattern
```bash
# 1. Show what will be deleted
az {resource-type} show --name {name} --resource-group {rg} --output table

# 2. Confirm with user (always ask first)
# "I found resource X. Confirm deletion? This action cannot be undone."

# 3. Delete with confirmation
az {resource-type} delete \
  --name {name} \
  --resource-group {rg} \
  --yes  # Only after user confirms
```

### Clean Up Resource Group
```bash
# ⚠️ EXTREMELY DESTRUCTIVE - Delete entire resource group
# Must get explicit user confirmation first
az group delete \
  --name {resource-group-name} \
  --yes \
  --no-wait
```

## Documentation Requirements

After any resource creation or modification, update the deployed resources tracking file:

**File**: `/docs/deployed-resources.md`

**Template**:
```markdown
## {Resource Name}
- **Type**: {Azure Resource Type}
- **Resource Group**: {RG Name}
- **Location**: {Region}
- **Tier/SKU**: {Pricing Tier}
- **Created**: {Date}
- **Purpose**: {Description}
- **Estimated Cost**: ${amount}/month
- **Cleanup Command**: `az {type} delete --name {name} --resource-group {rg}`
```

## Error Handling

### Common Issues

**Authentication Expired**
```bash
Error: Please run 'az login' to setup account.
Solution: az login
```

**Resource Already Exists**
```bash
Error: Resource already exists
Solution: Check if resource meets requirements, reuse if possible
```

**Insufficient Permissions**
```bash
Error: The client does not have authorization
Solution: Verify subscription permissions with user
```

**Quota Exceeded**
```bash
Error: Quota exceeded for resource type
Solution: Check existing resources, clean up unused resources, or request quota increase
```

## Cost Monitoring

Always monitor costs when creating resources:

```bash
# Get current month's cost
az consumption usage list \
  --start-date $(date -d 'month ago' +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --output table

# Get cost forecast
az consumption forecast list \
  --filter "properties/usageDate ge '$(date +%Y-%m-%d)'" \
  --output table
```

## Safety Rules

1. ✅ **Always verify** authentication before operations
2. ✅ **Always calculate** costs before creating resources
3. ✅ **Always ask** before deleting resources
4. ✅ **Always document** created resources
5. ✅ **Always use** existing resource groups when possible
6. ✅ **Always apply** standard tags
7. ✅ **Always provide** cleanup commands
8. ⛔ **Never delete** resources without explicit user confirmation
9. ⛔ **Never create** expensive resources without discussing alternatives
10. ⛔ **Never assume** - verify everything with queries first

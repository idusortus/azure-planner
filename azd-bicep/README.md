# Azure POC Platform - Infrastructure as Code

This folder contains **Bicep templates** and **Azure Developer CLI (azd)** configuration for deploying POC infrastructure to Azure.

## 📁 Structure

```
azd-bicep/
├── azure.yaml              # azd project definition
├── README.md               # This file
└── infra/
    ├── main.bicep          # Full deployment (shared + POC)
    ├── main.bicepparam     # Parameters file
    ├── poc-only.bicep      # POC-only deployment (uses existing shared infra)
    └── modules/
        ├── sql-server.bicep              # SQL Server + serverless database
        ├── container-registry.bicep      # Azure Container Registry
        ├── container-apps-env.bicep      # Container Apps Environment
        ├── container-apps-env-existing.bicep  # Reference existing env
        ├── container-app.bicep           # Container App (API)
        └── static-web-app.bicep          # Static Web App (frontend)
```

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** - [Install](https://docs.microsoft.com/cli/azure/install-azure-cli)
2. **Azure Developer CLI (azd)** - [Install](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
3. **Bicep CLI** - Included with Azure CLI v2.20+

### Option 1: Full Deployment (New Environment)

Use this when setting up a fresh POC environment with all shared infrastructure.

```bash
# Navigate to azd-bicep folder
cd azd-bicep

# Login to Azure
azd auth login

# Initialize and deploy
azd up
```

You'll be prompted for:
- Environment name (e.g., `dev`)
- Azure subscription
- Azure region (default: `centralus`)
- Resource prefix (e.g., `wiscodev`)
- POC name (e.g., `my-new-poc`)
- SQL admin credentials

### Option 2: POC-Only Deployment (Existing Shared Infra)

Use this when shared infrastructure already exists (SQL Server, ACR, Container Apps Environment).

```bash
# Deploy POC-specific resources only
az deployment sub create \
  --location centralus \
  --template-file infra/poc-only.bicep \
  --parameters pocName='my-new-poc' \
               existingAcrLoginServer='wiscodevacr-xxx.azurecr.io' \
               acrUsername='wiscodevacr' \
               acrPassword='<acr-password>' \
               sqlConnectionString='Server=tcp:dev-wiscodev.database.windows.net,1433;Database=sandbox;...' \
               schemaName='my_poc_schema'
```

## 📋 What Gets Created

### Full Deployment (`main.bicep`)

| Resource | Type | Purpose | Cost |
|----------|------|---------|------|
| Shared RG | Resource Group | Container for shared resources | $0 |
| POC RG | Resource Group | Container for POC resources | $0 |
| SQL Server | Azure SQL | Database server | $0 |
| sandbox DB | Azure SQL (Serverless) | Shared database with schemas | $0-5/mo |
| ACR | Container Registry (Basic) | Docker image storage | ~$5/mo |
| Container Apps Env | Managed Environment | Container hosting | $0 |
| Static Web App | Static Site (Free) | Frontend hosting | $0 |
| Container App | Container App | API hosting | $0-2/mo |

**Estimated Total: ~$5-7/month**

### POC-Only Deployment (`poc-only.bicep`)

| Resource | Type | Purpose | Cost |
|----------|------|---------|------|
| POC RG | Resource Group | Container for POC resources | $0 |
| Static Web App | Static Site (Free) | Frontend hosting | $0 |
| Container App | Container App | API hosting (uses existing env) | $0-2/mo |

**Estimated Total: ~$0-2/month per additional POC**

## 🗄️ Database Schema Isolation

Each POC uses a **separate SQL schema** within the shared `sandbox` database:

```sql
-- Example schemas
CREATE SCHEMA [todo];           -- TodoApp tables
CREATE SCHEMA [comments];       -- LeaveACommentApp tables
CREATE SCHEMA [predictions];    -- FriendsPrediction tables
```

Configure in EF Core:
```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.HasDefaultSchema("my_poc_schema");
}
```

## 🔧 Customization

### Modify Parameters

Edit `infra/main.bicepparam`:

```bicep
param environmentName = 'staging'
param location = 'eastus2'
param resourcePrefix = 'mycompany'
param pocName = 'awesome-poc'
```

### Add New Module

1. Create `infra/modules/my-resource.bicep`
2. Reference in `main.bicep`:
   ```bicep
   module myResource 'modules/my-resource.bicep' = {
     name: 'my-resource-${uniqueString(resourceGroup.id)}'
     scope: pocResourceGroup
     params: { ... }
   }
   ```

## 📝 ADR Reference

See [ADR-014: Schema-Based Database Isolation](../docs/poc-deployment/DECISIONS.md#adr-014-schema-based-database-isolation) for the architectural decision behind the shared database approach.

## 🧹 Cleanup

### Delete a POC

```bash
# Delete POC resource group
az group delete --name my-new-poc --yes

# Optionally drop the schema in sandbox
sqlcmd -S dev-wiscodev.database.windows.net -d sandbox -U <user> -P <pass> \
  -Q "DROP SCHEMA [my_poc_schema];"
```

### Delete Everything

```bash
# ⚠️ DESTRUCTIVE - Deletes all shared infrastructure
azd down --force --purge
```

## 🔗 Related Documentation

- [POC Deployment Guide](../docs/poc-deployment/GUIDE.md)
- [Architecture Decisions](../docs/poc-deployment/DECISIONS.md)
- [Deployed Resources](../docs/deployed-resources.md)
- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)

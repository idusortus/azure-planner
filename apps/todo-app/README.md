# TODO App - Azure POC Application

**POC Application**: Simple TODO List with persistent data  
**Azure Resource Group**: todo-app (dedicated)  
**Status**: Ready for setup

## Quick Start

### 1. Run Setup Scripts

```bash
cd apps/todo-app
chmod +x *.sh

# Required - Database (on shared SQL Server)
./setup-database.sh

# Required - Resource Group + Static Web App
./setup-static-web-app.sh

# Optional - Key Vault for secrets
./setup-keyvault.sh
```

### 2. Update Secrets

After running setup scripts:
1. Edit `.env.local`
2. Replace `YOUR_PASSWORD_HERE` with actual SQL password
3. (Optional) Store secrets in Key Vault

### 3. Create Aspire Solution

```bash
cd ../../TestPOCApp
dotnet new aspire -n TodoApp
cd TodoApp
dotnet new webapi -n TodoApp.Api -o src/TodoApp.Api
dotnet new web -n TodoApp.Web -o src/TodoApp.Web
dotnet sln add src/TodoApp.Api src/TodoApp.Web
```

### 4. Test Locally

```bash
dotnet run --project src/TodoApp.AppHost
# Open Aspire Dashboard: http://localhost:15888
```

### 5. Deploy to Azure

```bash
azd init  # Select todo-app resource group
azd up
```

## Scripts

| Script | Purpose | Resource Group |
|--------|---------|----------------|
| `setup-database.sh` | Azure SQL Database | Shared |
| `setup-static-web-app.sh` | Resource Group + Static Web App | todo-app |
| `setup-keyvault.sh` | Key Vault for secrets | todo-app |

## Generated Files (git-ignored)

- `azure-config.json` - Database configuration
- `azure-static-web-config.json` - Static Web App details
- `azure-keyvault-config.json` - Key Vault details
- `.env.local` - All connection strings and secrets
- `SETUP_NOTES.md` - Manual documentation

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    todo-app Resource Group                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │ Static Web App  │  │  Container App  │  │  Key Vault  │ │
│  │   (Frontend)    │  │     (API)       │  │  (Secrets)  │ │
│  │   $0/month      │  │   $0-2/month    │  │  ~$0/month  │ │
│  └────────┬────────┘  └────────┬────────┘  └──────┬──────┘ │
│           │                    │                   │        │
└───────────┼────────────────────┼───────────────────┼────────┘
            │                    │                   │
            │                    ▼                   │
            │           ┌─────────────────┐          │
            │           │   Shared RG     │          │
            │           │  ┌───────────┐  │          │
            └──────────▶│  │ SQL Server│◀─┴──────────┘
                        │  │(todo-db)  │  │
                        │  │$0-5/month │  │
                        │  └───────────┘  │
                        └─────────────────┘
```

## Cost Estimate

| Resource | Tier | Monthly Cost |
|----------|------|--------------|
| Static Web App | Free | $0 |
| Container Apps | Consumption | $0-2 |
| SQL Database | Serverless | $0-5 |
| Key Vault | Standard | ~$0.03 |
| **Total** | | **$0-7** |

## Cleanup

```bash
# Delete dedicated resource group (removes SWA, Container App, Key Vault)
az group delete --name todo-app --yes --no-wait

# Delete database from shared SQL Server
az sql db delete --name todo-app-db --server dev-wiscodev --resource-group Shared --yes
```

## Future Enhancements

- [ ] Managed Identity (instead of Key Vault connection strings)
- [ ] Microsoft Entra ID authentication
- [ ] Service Bus for background processing
- [ ] Application Insights monitoring

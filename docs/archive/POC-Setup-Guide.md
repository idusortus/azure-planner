# POC Application Setup Guide

**Version**: 1.0  
**Last Updated**: January 17, 2026  
**Purpose**: Comprehensive guide for creating budget-friendly Azure POC applications using .NET Aspire

---

## Quick Start Checklist

```
□ 1. Create infrastructure folder (apps/{poc-name}/)
□ 2. Run setup-database.sh
□ 3. Run setup-static-web-app.sh  
□ 4. Run setup-keyvault.sh (optional)
□ 5. Run setup-budget-alert.sh (optional)
□ 6. Create Aspire solution in TestPOCApp/ or separate folder
□ 7. Build and test locally
□ 8. Deploy with azd up
□ 9. Verify and document
```

---

## Architecture Overview

### Resource Group Strategy

**Shared Resource Group (`Shared`)**:
- SQL Server (logical server for all POC databases)
- Service Bus namespace (`wiscoshared`)
- Cross-POC infrastructure

**Per-POC Resource Group (`{poc-name}`)**:
- Static Web App (frontend)
- Container App (API)
- Storage Account (if needed)
- Key Vault (secrets)
- Budget alerts

### Target Stack

| Component | Technology | Azure Service | Cost |
|-----------|------------|---------------|------|
| Frontend | Vanilla JavaScript SPA | Static Web Apps (Free) | $0/month |
| Backend | .NET 10 WebAPI | Container Apps (Consumption) | $0-2/month |
| Database | EF Core + SQL | Azure SQL (Serverless) | $0-5/month |
| Orchestration | .NET 10 Aspire | N/A | N/A |
| Secrets | Azure Key Vault | Key Vault | ~$0.03/10K ops |
| **Total** | | | **$0-7/month** |

> **Note**: .NET Aspire fully supports .NET 10. The Aspire templates may default to .NET 9, but all projects should be updated to `net10.0` for consistency with the rest of the codebase.

---

## Phase 1: Infrastructure Setup

### Step 1: Create POC Folder

```bash
cd apps
mkdir {poc-name}
cd {poc-name}
```

### Step 2: Copy Setup Scripts

Copy from `apps/friends-prediction/` or create new scripts:

**Required Scripts**:
- `setup-database.sh` - Creates database on shared SQL Server
- `setup-static-web-app.sh` - Creates resource group + Static Web App

**Optional Scripts**:
- `setup-storage.sh` - Azure Storage Account
- `setup-keyvault.sh` - Azure Key Vault for secrets
- `setup-budget-alert.sh` - Cost monitoring

### Step 3: Update APP_NAME

In each script, update the configuration:
```bash
APP_NAME="your-poc-name"
```

### Step 4: Run Scripts

```bash
chmod +x *.sh

# Required
./setup-database.sh          # SQL Database
./setup-static-web-app.sh    # Resource Group + Static Web App

# Optional
./setup-keyvault.sh          # Key Vault
./setup-budget-alert.sh      # Budget alerts
```

### Step 5: Verify Generated Files

After running scripts, you'll have:
- `azure-config.json` - Database configuration
- `azure-static-web-config.json` - Static Web App details
- `azure-keyvault-config.json` - Key Vault details (if used)
- `.env.local` - All connection strings and secrets
- `SETUP_NOTES.md` - Manual documentation

---

## Phase 2: Aspire Solution

### Step 1: Create Solution

```bash
cd /path/to/solution/folder
dotnet new aspire -n {PocName}
cd {PocName}
```

### Step 2: Add Projects

```bash
# WebAPI
dotnet new webapi -n {PocName}.Api -o src/{PocName}.Api
dotnet sln add src/{PocName}.Api

# Web (static files)
dotnet new web -n {PocName}.Web -o src/{PocName}.Web
dotnet sln add src/{PocName}.Web
```

### Step 3: Configure AppHost

**`src/{PocName}.AppHost/Program.cs`**:
```csharp
var builder = DistributedApplication.CreateBuilder(args);

// Local SQL Server for development
var sqlServer = builder.AddSqlServer("sql")
    .WithLifetime(ContainerLifetime.Persistent);
var database = sqlServer.AddDatabase("appdb");

// API with database reference
var api = builder.AddProject<Projects.{PocName}_Api>("api")
    .WithReference(database)
    .WithExternalHttpEndpoints();

// Web frontend with API reference
builder.AddProject<Projects.{PocName}_Web>("web")
    .WithReference(api)
    .WithExternalHttpEndpoints();

builder.Build().Run();
```

### Step 4: Configure API

**Add packages**:
```bash
cd src/{PocName}.Api
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package Azure.Identity
dotnet add package Azure.Security.KeyVault.Secrets
```

**`appsettings.json`**:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "TO_BE_PROVIDED"
  },
  "KeyVault": {
    "VaultUri": "TO_BE_PROVIDED"
  }
}
```

**DbContext with retry logic**:
```csharp
builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sqlOptions => sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 5,
            maxRetryDelay: TimeSpan.FromSeconds(30),
            errorNumbersToAdd: null));
});
```

### Step 5: Configure Web (Static Files)

**`src/{PocName}.Web/Program.cs`**:
```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();
app.MapFallbackToFile("index.html");

app.Run();
```

**Frontend in `wwwroot/`**:
```
wwwroot/
  index.html
  css/
    styles.css
  js/
    app.js
```

**JavaScript API pattern**:
```javascript
const apiBaseUrl = window.ENV?.API_URL || 'https://localhost:7001';

async function fetchData() {
    const response = await fetch(`${apiBaseUrl}/api/items`);
    return await response.json();
}
```

---

## Phase 3: Local Development

### Step 1: Copy Azure Configuration

Run the configuration script to copy credentials from infrastructure folder:

```bash
cd TestPOCApp/{PocName}
chmod +x copy-config.sh
./copy-config.sh
```

This copies:
- Connection strings from `apps/{poc-name}/.env.local`
- Azure resource details to solution folder
- Updates `appsettings.Development.json` with actual DB password

### Step 2: Apply Database Migrations

```bash
cd src/{PocName}.Api
dotnet ef migrations add InitialCreate
dotnet ef database update
```

This creates tables in your Azure SQL Database (serverless will wake up automatically).

### Step 3: Run Aspire

```bash
cd TestPOCApp/{PocName}
dotnet run --project {PocName}.AppHost
```

### Step 4: Access Services

The Aspire dashboard will open automatically (usually at https://localhost:17135).

From the dashboard:
- View all running services (API, Web)
- Check logs and traces
- Monitor health checks
- Get service URLs

**Typical Service URLs**:
- **Aspire Dashboard**: https://localhost:17135
- **API**: http://localhost:XXXX (check dashboard)
- **Web**: http://localhost:YYYY (check dashboard)

### Step 5: Test Functionality

1. ✅ Open the Web frontend URL from Aspire dashboard
2. ✅ Verify API connection (check browser console for errors)
3. ✅ Test CRUD operations
4. ✅ Verify data persists to Azure SQL Database
5. ✅ Check Aspire dashboard for telemetry and logs

**Common Issues**:
- **CORS errors**: API must allow frontend origin
- **Connection refused**: Check service URLs in Aspire dashboard
- **DB timeout**: Serverless DB may take 30-60s to wake up (retry logic handles this)

---

## Phase 4: Azure Deployment

### Prerequisites

Ensure you have:
- ✅ Azure CLI installed (`az --version`)
- ✅ Azure Developer CLI installed (`azd version`)
- ✅ Authenticated with Azure (`az login`)
- ✅ Local testing completed successfully

### Step 1: Initialize Azure Developer CLI

```bash
cd TestPOCApp/{PocName}
azd init
```

**Configuration prompts**:
- Environment name: `dev` (or `prod`)
- Select subscription: Choose your Azure subscription
- Select location: `centralus`

### Step 2: Configure Azure Resources

The `azd` tool needs to know about your existing resources:

```bash
# Set environment variables for existing resources
azd env set AZURE_RESOURCE_GROUP "{poc-name}"
azd env set AZURE_SQL_SERVER "dev-wiscodev"
azd env set AZURE_SQL_DATABASE "{poc-name}-db"
```

### Step 3: Deploy to Azure

```bash
azd up
```

This automatically:
- ✅ Builds Docker images for API
- ✅ Pushes to Azure Container Registry (creates if needed)
- ✅ Deploys API to Container Apps (Consumption plan)
- ✅ Deploys frontend to existing Static Web App
- ✅ Configures environment variables
- ✅ Sets up networking and service connections

**Expected duration**: 5-10 minutes

### Step 4: Verify Deployment

1. **Check Container Apps**:
   ```bash
   az containerapp list --resource-group {poc-name} --output table
   ```

2. **Get API URL**:
   ```bash
   az containerapp show --name {poc-name}-api --resource-group {poc-name} --query properties.configuration.ingress.fqdn -o tsv
   ```

3. **Test API endpoint**:
   ```bash
   curl https://{api-url}/health
   ```

4. **Access Static Web App**:
   - URL is in `apps/{poc-name}/azure-static-web-config.json`
   - Should automatically connect to deployed API

### Step 5: Monitor and Debug

```bash
# View Container App logs
az containerapp logs show --name {poc-name}-api --resource-group {poc-name} --follow

# Check application insights (if configured)
az monitor app-insights component show --app {poc-name}-insights --resource-group {poc-name}
```

---

## Cleanup

### Delete POC Resources

```bash
# Delete entire resource group (removes all POC resources)
az group delete --name {poc-name} --yes --no-wait

# Or delete individual resources
az staticwebapp delete --name {poc-name}-web --resource-group {poc-name}
az sql db delete --name {poc-name}-db --server dev-wiscodev --resource-group Shared
```

### Keep Shared Resources

Never delete from Shared resource group:
- SQL Server (`dev-wiscodev`)
- Service Bus (`wiscoshared`)

---

## Troubleshooting

### Authentication Issues

```bash
# Re-authenticate
az login
az account set --subscription "Azure subscription 1"
```

### Provider Not Registered

```bash
# Register required providers
az provider register --namespace Microsoft.Web --wait
az provider register --namespace Microsoft.Storage --wait
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.KeyVault --wait
```

### Database Connection Issues

1. Check firewall rules include your IP
2. Verify password in connection string
3. Database may be paused (first connection takes 30-60s)
4. Check retry logic is enabled

### Container App Deployment Issues

```bash
# Check deployment logs
azd monitor

# Redeploy specific service
azd deploy api
```

---

## Cost Monitoring

### Expected Costs

- **Static Web Apps**: $0 (Free tier)
- **Container Apps**: $0-2 (scale to zero)
- **SQL Database**: $0-5 (serverless, auto-pause)
- **Key Vault**: ~$0.03/10K operations
- **Storage**: $0.50-2 (if used)

**Total**: $0-7/month per POC

### Budget Alerts

Run `setup-budget-alert.sh` to create alerts at:
- 80% of $5 budget
- 100% of $5 budget
- 120% of $5 budget

---

## Future Enhancements

**For future POC exploration**:
- [ ] Managed Identity (instead of Key Vault connection strings)
- [ ] Microsoft Entra ID / Keycloak authentication
- [ ] Service Bus integration for background processing
- [ ] Azure Functions for serverless compute
- [ ] Application Insights for monitoring
- [ ] GitHub Actions CI/CD pipelines

---

## Appendix: Completed TODO App Example

The TODO app was successfully deployed using this guide on January 17, 2026.

### Live URLs

| Component | URL |
|-----------|-----|
| **API** | https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io |
| **Health Check** | https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/health |
| **Todos Endpoint** | https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/todos |
| **Frontend** | https://happy-desert-065eace10.6.azurestaticapps.net |

### Resources Created

| Resource | Type | Cost |
|----------|------|------|
| `todo-app` | Resource Group | $0 |
| `todo-app-db` | Azure SQL Serverless | $0-5/month |
| `todo-app-web` | Static Web App (Free) | $0/month |
| `todoapp-env` | Container Apps Environment | $0/month |
| `todoapp-api` | Container App | $0-2/month |
| `wiscodevacr` | Container Registry (Basic) | ~$5/month |

### Deployment Scripts Used

```bash
# 1. Infrastructure (from apps/todo-app/)
./setup-database.sh
./setup-static-web-app.sh

# 2. Copy config to Aspire solution
./copy-config.sh

# 3. Deploy API (from TestPOCApp/TodoApp/)
.\deploy-to-azure.ps1

# 4. Deploy Frontend
.\deploy-frontend.ps1
```

### Key Learnings

1. **Container Registry**: Created a shared ACR (`wiscodevacr`) for all POCs to avoid per-POC registry costs
2. **Admin credentials**: Used ACR admin credentials instead of managed identity for simplicity
3. **Connection strings**: Passed directly as environment variables (consider Key Vault for production)
4. **Scale to zero**: Container Apps with `minReplicas: 0` enables true serverless cost savings
5. **Service discovery**: Frontend uses static `config.js` file with production API URL

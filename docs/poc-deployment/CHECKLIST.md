# POC Deployment Checklist

**Version**: 1.0 | **Last Updated**: January 17, 2026

> Quick reference for deploying .NET Aspire + JS + Azure SQL POC apps.  
> For explanations, see [GUIDE.md](GUIDE.md).

---

## Pre-Flight

```
□ Azure CLI authenticated: az account show
□ Docker Desktop running
□ .NET 10 SDK installed: dotnet --version
□ Node.js installed (for SWA CLI): node --version
```

---

## Phase 1: Infrastructure (15 min)

### 1.1 Create POC Folder
```bash
cd apps
mkdir {poc-name}
cd {poc-name}
```

### 1.2 Copy & Edit Scripts
```bash
cp ../todo-app/setup-database.sh .
cp ../todo-app/setup-static-web-app.sh .
# Edit APP_NAME in each script
```

### 1.3 Run Infrastructure Scripts
```bash
□ ./setup-database.sh          # Creates DB on shared server
□ ./setup-static-web-app.sh    # Creates RG + Static Web App
```

### 1.4 Verify Outputs
```
□ .env.local created with DB credentials
□ azure-config.json created
□ azure-static-web-config.json created with deployment token
```

---

## Phase 2: Aspire Solution (30 min)

### 2.1 Create Solution
```bash
cd ../../TestPOCApp  # or wherever you keep POC code
mkdir {PocName} && cd {PocName}
dotnet new aspire -n {PocName}
```

### 2.2 Update to .NET 10
```bash
# Edit ALL .csproj files: <TargetFramework>net10.0</TargetFramework>
□ {PocName}.AppHost.csproj
□ {PocName}.ServiceDefaults.csproj
```

### 2.3 Create API Project
```bash
mkdir -p src/{PocName}.Api
cd src/{PocName}.Api
dotnet new webapi -n {PocName}.Api --no-https
# Update to net10.0, add to solution
```

### 2.4 Create Web Project
```bash
mkdir -p src/{PocName}.Web
# Create minimal static file host (see GUIDE.md)
```

### 2.5 Configure AppHost
```csharp
// AppHost/AppHost.cs
var api = builder.AddProject<Projects.{PocName}_Api>("api");
var web = builder.AddProject<Projects.{PocName}_Web>("web")
    .WithReference(api);
```

### 2.6 Add EF Core & Models
```bash
cd src/{PocName}.Api
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Design
# Create Models/, Data/, configure DbContext
```

### 2.7 Copy Config & Apply Migration
```bash
□ ./copy-config.sh             # Copy credentials from apps/{poc-name}/
□ dotnet ef migrations add InitialCreate
□ dotnet ef database update
```

---

## Phase 3: Local Testing (10 min)

### 3.1 Run Aspire
```bash
cd {PocName}
dotnet run --project {PocName}.AppHost
```

### 3.2 Verify
```
□ Aspire Dashboard opens (https://localhost:17xxx)
□ API health endpoint works: /health
□ API endpoints work: /api/{resource}
□ Frontend loads and connects to API
□ CRUD operations functional
```

---

## Phase 4: Azure Deployment (20 min)

### 4.1 Create Dockerfile
```bash
# src/{PocName}.Api/Dockerfile - see GUIDE.md for template
```

### 4.2 Build & Push Image
```bash
az acr login --name wiscodevacr
docker build -t wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/{poc-name}-api:latest \
  -f src/{PocName}.Api/Dockerfile .
docker push wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/{poc-name}-api:latest
```

### 4.3 Create Container Apps Environment
```bash
az containerapp env create \
  --name {poc-name}-env \
  --resource-group {poc-name} \
  --location centralus
```

### 4.4 Deploy API
```bash
# Get ACR credentials
ACR_USER=$(az acr credential show --name wiscodevacr --resource-group Shared --query username -o tsv)
ACR_PASS=$(az acr credential show --name wiscodevacr --resource-group Shared --query "passwords[0].value" -o tsv)

# Create container app
az containerapp create \
  --name {poc-name}-api \
  --resource-group {poc-name} \
  --environment {poc-name}-env \
  --image wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/{poc-name}-api:latest \
  --target-port 8080 \
  --ingress external \
  --registry-server wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io \
  --registry-username "$ACR_USER" \
  --registry-password "$ACR_PASS" \
  --min-replicas 0 \
  --max-replicas 1 \
  --env-vars 'ConnectionStrings__{DbName}=Server=dev-wiscodev.database.windows.net;Database={poc-name}-db;User Id={user};Password={pass};TrustServerCertificate=True;'
```

### 4.5 Get API URL
```bash
API_URL=$(az containerapp show --name {poc-name}-api --resource-group {poc-name} \
  --query "properties.configuration.ingress.fqdn" -o tsv)
echo "API: https://$API_URL"
```

### 4.6 Update Frontend Config
```javascript
// src/{PocName}.Web/wwwroot/config.js
window.API_BASE_URL = 'https://{api-url}/api/{resource}';
```

### 4.7 Deploy Frontend
```bash
cd src/{PocName}.Web/wwwroot
swa deploy . --deployment-token "{token-from-azure-static-web-config.json}" --env production
```

---

## Phase 5: Verification

```
□ API health: curl https://{api-url}/health
□ API data: curl https://{api-url}/api/{resource}
□ Frontend loads: https://{swa-url}
□ Frontend connects to API
□ CRUD operations work end-to-end
□ Update docs/deployed-resources.md
```

---

## Quick Reference

### Shared Resources
| Resource | Value |
|----------|-------|
| SQL Server | `dev-wiscodev.database.windows.net` |
| Container Registry | `wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io` |
| Subscription | `e4b6b908-fa56-4b92-9e9c-5b0c855d13fe` |

### Useful Commands
```bash
# Check deployment status
az containerapp show --name {app} --resource-group {rg} -o table

# View logs
az containerapp logs show --name {app} --resource-group {rg} --follow

# Restart container
az containerapp revision restart --name {app} --resource-group {rg} \
  --revision $(az containerapp revision list --name {app} --resource-group {rg} --query "[0].name" -o tsv)

# Delete POC (cleanup)
az group delete --name {poc-name} --yes --no-wait
az sql db delete --name {poc-name}-db --server dev-wiscodev --resource-group Shared --yes
```

---

## Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| DB connection timeout | Wait 30-60s for serverless wake-up |
| Docker build fails | Check Dockerfile paths relative to build context |
| ACR push denied | Run `az acr login --name wiscodevacr` |
| SWA deploy stuck | Use PowerShell: `.\deploy-frontend.ps1` |
| CORS errors | Enable CORS in API: `builder.Services.AddCors()` |
| Container won't start | Check `az containerapp logs show` |

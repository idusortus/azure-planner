# POC Deployment Master Reference

> **Quick reference for deploying .NET Aspire POC applications to Azure**  
> **Last Updated**: January 18, 2026

---

## 🎯 TL;DR - The 5-Minute Overview

| What | How |
|------|-----|
| **Stack** | .NET 10 Aspire API + Vanilla JS SPA + Azure SQL (schema-isolated) |
| **Hosting** | Container Apps (API) + Static Web Apps (Frontend) |
| **Database** | Single `sandbox` database, one schema per POC |
| **Cost** | ~$5-7/month total for ALL POCs combined |
| **Deployment** | Azure CLI commands (fast) or Bicep templates (repeatable) |

---

## 📦 Expected Software Framework

All POC applications follow this structure:

```
my-poc/
├── src/
│   ├── MyPoc.Api/              # .NET 10 Web API
│   │   ├── Data/
│   │   │   ├── AppDbContext.cs        # EF Core with schema config
│   │   │   └── AppDbContextFactory.cs # Design-time factory for migrations
│   │   ├── Dockerfile                  # Multi-stage build for Container Apps
│   │   ├── appsettings.json           # Connection string to sandbox DB
│   │   └── Program.cs
│   ├── MyPoc.Web/              # Static frontend (optional)
│   │   └── wwwroot/
│   │       ├── index.html             # SPA entry with API URL config
│   │       └── assets/                # JS/CSS bundles
│   └── MyPoc.AppHost/          # Aspire orchestrator (local dev only)
└── MyPoc.sln
```

### Key Code Patterns

**AppDbContext.cs** - Schema isolation:
```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    base.OnModelCreating(modelBuilder);
    modelBuilder.HasDefaultSchema("my_poc_schema");  // Isolates from other POCs
}
```

**AppDbContextFactory.cs** - Design-time migrations:
```csharp
public AppDbContext CreateDbContext(string[] args)
{
    var config = new ConfigurationBuilder()
        .SetBasePath(Directory.GetCurrentDirectory())
        .AddJsonFile("appsettings.json")
        .AddJsonFile("appsettings.Development.json", optional: true)
        .Build();
    
    var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
    optionsBuilder.UseSqlServer(config.GetConnectionString("DefaultConnection"));
    return new AppDbContext(optionsBuilder.Options);
}
```

**index.html** - Frontend API configuration:
```html
<script>
  window.ENV = {
    API_URL: 'https://my-poc-api.politeriver-ded1b871.centralus.azurecontainerapps.io'
  };
</script>
```

---

## 🔧 When to Use What

### Azure CLI (Recommended for POCs)

**Use when:**
- ✅ Deploying a single POC quickly
- ✅ Iterating/debugging deployments
- ✅ Learning the Azure resource model
- ✅ One-off operations

**Pros:**
- Fast to execute (~5 minutes)
- Easy to troubleshoot
- Direct control over each step
- No template compilation needed

**Example workflow:**
```bash
# 1. Build and push Docker image
docker build -t wiscodevacr-xxx.azurecr.io/my-poc-api:latest .
docker push wiscodevacr-xxx.azurecr.io/my-poc-api:latest

# 2. Create container app
az containerapp create --name my-poc-api --resource-group todo-app \
  --environment todoapp-env --image wiscodevacr-xxx.azurecr.io/my-poc-api:latest \
  --target-port 8080 --ingress external --min-replicas 0 --max-replicas 1

# 3. Add secrets and env vars
az containerapp secret set --name my-poc-api --resource-group todo-app \
  --secrets 'db-connection=Server=...'
az containerapp update --name my-poc-api --resource-group todo-app \
  --set-env-vars "ConnectionStrings__DefaultConnection=secretref:db-connection"
```

### Bicep Templates (`/azd-bicep`)

**Use when:**
- ✅ Setting up entirely new environments
- ✅ Need repeatable/documented infrastructure
- ✅ CI/CD pipeline deployments
- ✅ Auditing/compliance requirements
- ✅ Multi-environment (dev/staging/prod)

**Pros:**
- Infrastructure as Code - version controlled
- Idempotent - run multiple times safely
- Full environment in one command
- Easy to replicate across subscriptions

**Available templates:**

| Template | Use Case |
|----------|----------|
| `main.bicep` | Full deployment: shared infra + POC resources |
| `poc-only.bicep` | POC resources only (assumes shared infra exists) |

**Example usage:**
```bash
cd azd-bicep

# Full deployment (new environment)
azd up

# POC-only deployment (existing shared infra)
az deployment sub create --location centralus \
  --template-file infra/poc-only.bicep \
  --parameters pocName='my-new-poc' ...
```

---

## 🏗️ Shared Infrastructure Reference

All POCs share these resources to minimize cost:

| Resource | Name | Resource Group | Purpose |
|----------|------|----------------|---------|
| **SQL Server** | `dev-wiscodev` | Shared | Database host ($0) |
| **Database** | `sandbox` | Shared | Shared DB, schema-per-POC ($0 free tier) |
| **Container Registry** | `wiscodevacr` | Shared | Docker images (~$5/mo) |
| **Container Apps Env** | `todoapp-env` | todo-app | App hosting ($0 base) |

### Connection Details

```bash
# SQL Server
Server: dev-wiscodev.database.windows.net
Database: sandbox
Admin: BryceAndConrad

# Container Registry
Login Server: wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io
Username: wiscodevacr
# Password: az acr credential show --name wiscodevacr --query passwords[0].value -o tsv

# Container Apps Environment
Environment: todoapp-env
Domain: politeriver-ded1b871.centralus.azurecontainerapps.io
```

---

## 🚀 Deployment Checklist

### Pre-Deployment

- [ ] EF Core DbContext has `HasDefaultSchema("schema_name")`
- [ ] AppDbContextFactory loads connection string from appsettings
- [ ] Dockerfile exists and builds successfully
- [ ] appsettings.json has sandbox database connection string

### Database Setup

```bash
# 1. Create schema
sqlcmd -S dev-wiscodev.database.windows.net -d sandbox -U BryceAndConrad \
  -P '<password>' -Q "CREATE SCHEMA [my_schema]"

# 2. Apply EF migrations
cd src/MyPoc.Api
dotnet ef database update
```

### API Deployment

```bash
# 1. Login to ACR
az acr login --name wiscodevacr

# 2. Build and push
docker build -t wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/my-poc-api:latest \
  -f src/MyPoc.Api/Dockerfile .
docker push wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/my-poc-api:latest

# 3. Get ACR credentials
ACR_PASSWORD=$(az acr credential show --name wiscodevacr --query passwords[0].value -o tsv)

# 4. Create container app
az containerapp create \
  --name my-poc-api \
  --resource-group todo-app \
  --environment todoapp-env \
  --image wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/my-poc-api:latest \
  --registry-server wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io \
  --registry-username wiscodevacr \
  --registry-password "$ACR_PASSWORD" \
  --target-port 8080 \
  --ingress external \
  --min-replicas 0 \
  --max-replicas 1

# 5. Add database connection (use single quotes to avoid bash expansion)
az containerapp secret set --name my-poc-api --resource-group todo-app \
  --secrets 'db-connection=Server=tcp:dev-wiscodev.database.windows.net,1433;Database=sandbox;User ID=BryceAndConrad;Password=<password>;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

az containerapp update --name my-poc-api --resource-group todo-app \
  --set-env-vars "ConnectionStrings__DefaultConnection=secretref:db-connection"
```

### Frontend Deployment

```bash
# 1. Update index.html with API URL
# window.ENV = { API_URL: 'https://my-poc-api.politeriver-ded1b871.centralus.azurecontainerapps.io' }

# 2. Get SWA deployment token
DEPLOY_TOKEN=$(az staticwebapp secrets list --name my-poc-web --query properties.apiKey -o tsv)

# 3. Deploy static files
cd src/MyPoc.Web/wwwroot
npx @azure/static-web-apps-cli deploy . --deployment-token "$DEPLOY_TOKEN" --env production

# 4. Enable CORS on API
az containerapp ingress cors update --name my-poc-api --resource-group todo-app \
  --allowed-origins "https://my-poc-frontend-url.azurestaticapps.net" \
  --allowed-methods "*" --allowed-headers "*"
```

---

## 📊 Current POC Status

| POC | Schema | API URL | Frontend URL | Status |
|-----|--------|---------|--------------|--------|
| **TodoApp** | `todo` | [todoapp-api](https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io) | [happy-desert](https://happy-desert-065eace10.6.azurestaticapps.net) | ✅ Live |
| **LeaveACommentApp** | `comments` | [leave-a-comment-api](https://leave-a-comment-api.politeriver-ded1b871.centralus.azurecontainerapps.io) | [nice-sand](https://nice-sand-0b0628510.6.azurestaticapps.net) | ✅ Live |
| **FriendsPrediction** | `predictions` | [friends-prediction-api](https://friends-prediction-api.politeriver-ded1b871.centralus.azurecontainerapps.io) | [kind-pebble](https://kind-pebble-0eeaa2310.2.azurestaticapps.net) | ✅ Live |

---

## 💰 Cost Summary

| Resource | Monthly Cost |
|----------|--------------|
| SQL Database (sandbox, free tier) | **$0** |
| Container Registry (Basic) | ~$5 |
| Container Apps (3 POCs) | $0-2 each |
| Static Web Apps (3 POCs) | $0 |
| Log Analytics | $0-1 |
| **Total** | **~$5-10** |

---

## 📚 Related Documentation

| Document | Purpose |
|----------|---------|
| [Deployed Resources](deployed-resources.md) | Full inventory of Azure resources |
| [POC Deployment Guide](poc-deployment/GUIDE.md) | Detailed step-by-step instructions |
| [POC Checklist](poc-deployment/CHECKLIST.md) | Quick deployment checklist |
| [Architecture Decisions](poc-deployment/DECISIONS.md) | ADRs explaining design choices |
| [Bicep Templates](../azd-bicep/README.md) | Infrastructure as Code reference |
| [SQL Credentials](sql-credentials.md) | Database connection info |

---

## 🔍 Troubleshooting Quick Reference

| Problem | Solution |
|---------|----------|
| EF migrations apply to wrong DB | Check `AppDbContextFactory` - must load from appsettings |
| Container app can't pull image | Verify ACR credentials: `--registry-username` and `--registry-password` |
| CORS errors in browser | Add frontend URL to API CORS: `az containerapp ingress cors update` |
| Azure CLI session expired | Re-login: `az login --use-device-code` |
| Bash `!` expansion error | Use single quotes around connection strings with `!` |
| Container app won't start | Check logs: `az containerapp logs show --name <app> --resource-group <rg>` |

# POC Deployment Master Reference

> **The single source of truth for deploying .NET Aspire POC applications to Azure.**  
> **Last Updated**: February 15, 2026

---

## TL;DR

| What | How |
|------|-----|
| **Stack** | .NET 10 Aspire API + Vanilla JS SPA + Azure SQL (schema-isolated) |
| **Hosting** | Container Apps (API) + Static Web Apps (Frontend) |
| **Database** | Single `sandbox` database on `dev-wiscodev`, one schema per POC |
| **Cost** | ~$5-10/month total for ALL POCs combined |
| **Deployment** | Manual Azure CLI commands |

---

## Live POCs

| POC | Schema | API | Frontend | Status |
|-----|--------|-----|----------|--------|
| TodoApp | `todo` | [todoapp-api](https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io) | [happy-desert](https://happy-desert-065eace10.6.azurestaticapps.net) | Live |
| LeaveACommentApp | `comments` | [leave-a-comment-api](https://leave-a-comment-api.politeriver-ded1b871.centralus.azurecontainerapps.io) | [nice-sand](https://nice-sand-0b0628510.6.azurestaticapps.net) | Live |
| FriendsPrediction | `predictions` | [friends-prediction-api](https://friends-prediction-api.politeriver-ded1b871.centralus.azurecontainerapps.io) | [kind-pebble](https://kind-pebble-0eeaa2310.2.azurestaticapps.net) | Live |

---

## Shared Infrastructure

All POCs share these resources to minimize cost:

| Resource | Name | Resource Group | Cost |
|----------|------|----------------|------|
| SQL Server | `dev-wiscodev` | Shared | $0 |
| Database | `sandbox` (free tier) | Shared | $0 |
| Container Registry | `wiscodevacr` | Shared | ~$5/mo |
| Container Apps Env | `todoapp-env` | todo-app | $0 |
| Service Bus | `wiscoshared` | Shared | varies |

**Total fixed cost**: ~$5/month (ACR only). Everything else is consumption/free tier.

### Connection Details

```
SQL Server:   dev-wiscodev.database.windows.net
Database:     sandbox
Admin User:   BryceAndConrad
Password:     (see apps/{poc-name}/.env.local — NEVER commit to git)

ACR:          wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io
ACR Password: az acr credential show --name wiscodevacr --query passwords[0].value -o tsv

Container Apps Domain: politeriver-ded1b871.centralus.azurecontainerapps.io
```

---

## Expected POC Structure

```
{PocName}/
├── {PocName}.sln
├── {PocName}.AppHost/                 # Aspire orchestrator (local dev only)
├── {PocName}.ServiceDefaults/         # At solution root, NOT in src/
├── src/
│   ├── {PocName}.Api/                 # .NET 10 Web API
│   │   ├── Data/
│   │   │   ├── AppDbContext.cs        # EF Core with schema config
│   │   │   └── AppDbContextFactory.cs # Design-time factory
│   │   ├── Models/
│   │   ├── Dockerfile
│   │   ├── appsettings.json
│   │   └── Program.cs
│   └── {PocName}.Web/                 # Static frontend
│       └── wwwroot/
│           ├── index.html
│           ├── css/styles.css
│           └── js/app.js
```

### Key Code Patterns

**DbContext — schema isolation** (each POC gets its own schema in `sandbox`):
```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.HasDefaultSchema("my_poc_schema");
}
```

**Program.cs — EF retry for serverless wake-up**:
```csharp
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sql => sql.EnableRetryOnFailure(5, TimeSpan.FromSeconds(30), null)));
```

**Frontend — API URL from config**:
```html
<script>
  window.ENV = { API_URL: 'https://my-poc-api.politeriver-ded1b871.centralus.azurecontainerapps.io' };
</script>
```

---

## Deploying a New POC

### Phase 1: Infrastructure (~15 min)

```bash
# 1. Create infrastructure folder
cd apps && mkdir {poc-name} && cd {poc-name}

# 2. Copy scripts from existing POC, edit APP_NAME in each
cp ../todo-app/setup-database.sh .
cp ../todo-app/setup-static-web-app.sh .
cp ../todo-app/.gitignore .

# 3. Run scripts
chmod +x *.sh
./setup-database.sh           # Creates schema in sandbox, generates .env.local
./setup-static-web-app.sh     # Creates POC resource group + Static Web App
```

Verify: `.env.local`, `azure-config.json`, `azure-static-web-config.json` all exist.

### Phase 2: Aspire Solution (~30 min)

```bash
# 1. Create solution (Aspire fully supports .NET 10)
cd TestPOCApp && mkdir {PocName} && cd {PocName}
dotnet new aspire -n {PocName}

# 2. Verify all .csproj target net10.0

# 3. Create API project
mkdir -p src/{PocName}.Api
dotnet new webapi -n {PocName}.Api -o src/{PocName}.Api --no-https
dotnet sln add src/{PocName}.Api
cd src/{PocName}.Api
dotnet add reference ../../{PocName}.ServiceDefaults/{PocName}.ServiceDefaults.csproj
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Design
cd ../..

# 4. Create Web project
mkdir -p src/{PocName}.Web
dotnet new web -n {PocName}.Web -o src/{PocName}.Web
dotnet sln add src/{PocName}.Web
cd src/{PocName}.Web
dotnet add reference ../../{PocName}.ServiceDefaults/{PocName}.ServiceDefaults.csproj
cd ../..
# Create wwwroot/ with index.html, css/styles.css, js/app.js

# 5. Add project references to AppHost
cd {PocName}.AppHost
dotnet add reference ../src/{PocName}.Api/{PocName}.Api.csproj
dotnet add reference ../src/{PocName}.Web/{PocName}.Web.csproj
cd ..
```

Configure AppHost:
```csharp
var builder = DistributedApplication.CreateBuilder(args);
var api = builder.AddProject<Projects.{PocName}_Api>("api");
builder.AddProject<Projects.{PocName}_Web>("web")
    .WithReference(api).WaitFor(api);
builder.Build().Run();
```

Create `copy-config.sh` to pull credentials from `apps/{poc-name}/.env.local` into `appsettings.Development.json`.

Apply migrations:
```bash
cd src/{PocName}.Api
dotnet ef migrations add InitialCreate
dotnet ef database update
```

### Phase 3: Local Testing (~10 min)

```bash
dotnet run --project {PocName}.AppHost
```

Verify in Aspire Dashboard: API `/health`, API `/api/{entities}`, frontend loads, CRUD works.

### Phase 4: Azure Deployment (~20 min)

#### Build and push Docker image

```bash
# From solution root (where .sln is)
az acr login --name wiscodevacr

docker build \
  -t wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/{poc-name}-api:latest \
  -f src/{PocName}.Api/Dockerfile .

docker push wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/{poc-name}-api:latest
```

#### Deploy Container App (shared environment)

```bash
# Get shared environment ID (subscription limit: 1 env)
ENV_ID=$(az containerapp env show --name todoapp-env --resource-group todo-app --query id -o tsv)

# Get ACR credentials
ACR_USER=$(az acr credential show --name wiscodevacr --query username -o tsv)
ACR_PASS=$(az acr credential show --name wiscodevacr --query "passwords[0].value" -o tsv)

# Create container app (MSYS_NO_PATHCONV for Git Bash path issues)
MSYS_NO_PATHCONV=1 az containerapp create \
  --name {poc-name}-api \
  --resource-group {poc-name} \
  --environment "$ENV_ID" \
  --image wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/{poc-name}-api:latest \
  --target-port 8080 \
  --ingress external \
  --registry-server wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io \
  --registry-username "$ACR_USER" \
  --registry-password "$ACR_PASS" \
  --min-replicas 0 \
  --max-replicas 1
```

#### Add database connection

```bash
# Use single quotes to avoid bash expansion of special chars
az containerapp secret set --name {poc-name}-api --resource-group {poc-name} \
  --secrets 'db-connection=Server=tcp:dev-wiscodev.database.windows.net,1433;Database=sandbox;User ID=BryceAndConrad;Password=<PASSWORD>;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

az containerapp update --name {poc-name}-api --resource-group {poc-name} \
  --set-env-vars "ConnectionStrings__DefaultConnection=secretref:db-connection"
```

#### Get API URL and update frontend

```bash
API_URL=$(az containerapp show --name {poc-name}-api --resource-group {poc-name} \
  --query "properties.configuration.ingress.fqdn" -o tsv)
echo "API URL: https://$API_URL"
```

Update `wwwroot/index.html` or `config.js` with the API URL.

#### Deploy frontend via GitHub Actions

```bash
# Fix app_location in generated workflow:
# .github/workflows/azure-static-web-apps-*.yml
# Set app_location to: TestPOCApp/{PocName}/src/{PocName}.Web/wwwroot

git add . && git commit -m "Deploy {poc-name}" && git push
```

#### Enable CORS

```bash
SWA_URL=$(az staticwebapp show --name {poc-name}-web --resource-group {poc-name} \
  --query "defaultHostname" -o tsv)

az containerapp ingress cors update --name {poc-name}-api --resource-group {poc-name} \
  --allowed-origins "https://$SWA_URL" \
  --allowed-methods "*" --allowed-headers "*"
```

### Phase 5: Verify and Document

```bash
curl https://{api-url}/health
curl https://{api-url}/api/{entities}
# Open frontend in browser
```

Update [deployed-resources.md](deployed-resources.md).

---

## Key Decisions

Full ADR log: [DECISIONS.md](poc-deployment/DECISIONS.md)

| Decision | Choice | Why |
|----------|--------|-----|
| Database isolation | Schema per POC in shared `sandbox` DB | Free tier, $10-15/mo savings |
| API hosting | Container Apps (consumption) | Scale-to-zero, no daily limits |
| Frontend hosting | Static Web Apps (free) | $0, global CDN |
| Container Apps env | Share `todoapp-env` across all POCs | Subscription limit: 1 env |
| ACR credentials | Admin creds (for now) | Simple; future: Managed Identity |
| Frontend framework | Vanilla JS | No build step, fast iteration |
| Aspire | Local dev only | Dashboard useful; deploy manually |
| Deployment | Manual Azure CLI | More control than `azd` for POCs |

---

## Cost Summary

| Resource | Monthly Cost |
|----------|--------------|
| SQL Database (sandbox, free tier) | **$0** |
| Container Registry (Basic, shared) | ~$5 |
| Container Apps (3 POCs, scale-to-zero) | $0-2 each |
| Static Web Apps (3 POCs, free) | $0 |
| Log Analytics | $0-1 |
| **Total** | **~$5-10** |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| DB connection timeout | Wait 30-60s for serverless wake-up (EF retry handles it) |
| Docker build fails | Run from **solution root**, not API folder |
| Docker push denied | `az acr login --name wiscodevacr` |
| ACR DNS not found | Full server: `wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io` |
| ACR credentials error | Always provide `--registry-username` and `--registry-password` |
| Git Bash mangles paths | Prefix with `MSYS_NO_PATHCONV=1` |
| `!` in password fails bash | Use single quotes around connection strings |
| Env not found (cross-RG) | Use full resource ID, not just env name |
| Container won't start | `az containerapp logs show --name {app} --resource-group {rg} --follow` |
| SWA CLI timeout | Use GitHub Actions deployment instead |
| CORS errors | Enable CORS on Container App ingress |
| EF migrations wrong DB | Check `AppDbContextFactory` loads from correct appsettings |
| ServiceDefaults in Docker | It's at solution root, NOT in `src/` |

---

## Useful Commands

```bash
# Check deployment status
az containerapp show --name {app} --resource-group {rg} -o table

# View container logs
az containerapp logs show --name {app} --resource-group {rg} --follow

# Restart container
az containerapp revision restart --name {app} --resource-group {rg} \
  --revision $(az containerapp revision list --name {app} --resource-group {rg} --query "[0].name" -o tsv)

# List all resources in a group
az resource list --resource-group {rg} --output table

# Delete entire POC
az group delete --name {poc-name} --yes --no-wait
```

---

## Future Exploration

- **Managed Identity** for ACR access (eliminate admin credentials)
- **Azure Key Vault** for secret management
- **Microsoft Entra ID / Keycloak** for authentication
- **Application Insights** for observability
- **`azd up`** for Aspire-native deployment (not used yet, manual CLI preferred)

---

## Related Documents

| Document | Purpose |
|----------|---------|
| [Deployed Resources](deployed-resources.md) | Full inventory of live Azure resources |
| [Architecture Decisions](poc-deployment/DECISIONS.md) | ADRs with rationale |
| [Bicep Templates](../azd-bicep/README.md) | Infrastructure as Code (optional) |
| [Create New POC Prompt](../.github/prompts/create-new-poc.prompt.md) | Copilot prompt for scaffolding |

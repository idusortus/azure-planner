# POC Deployment Guide

**Version**: 1.0 | **Last Updated**: January 17, 2026

> Comprehensive guide for deploying .NET Aspire + JavaScript + Azure SQL POC applications.  
> For quick reference, see [CHECKLIST.md](CHECKLIST.md).

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Decisions](#architecture-decisions)
3. [Prerequisites](#prerequisites)
4. [Phase 1: Infrastructure Setup](#phase-1-infrastructure-setup)
5. [Phase 2: Aspire Solution](#phase-2-aspire-solution)
6. [Phase 3: Local Development](#phase-3-local-development)
7. [Phase 4: Azure Deployment](#phase-4-azure-deployment)
8. [Phase 5: Verification & Documentation](#phase-5-verification--documentation)
9. [Troubleshooting](#troubleshooting)
10. [Cost Management](#cost-management)

---

## Overview

### What We're Building

A repeatable pattern for deploying proof-of-concept applications to Azure with:
- **Frontend**: Vanilla JavaScript SPA hosted on Azure Static Web Apps (Free tier)
- **Backend**: .NET 10 Web API hosted on Azure Container Apps (Consumption plan, scale-to-zero)
- **Database**: Azure SQL Database (Serverless, auto-pause)
- **Orchestration**: .NET Aspire for local development

### Why This Stack?

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Frontend Host | Static Web Apps | Free tier, global CDN, easy deployment |
| Frontend Tech | Vanilla JS | No build step, simple, framework-agnostic |
| Backend Host | Container Apps | Scale-to-zero, consumption pricing, Docker flexibility |
| Backend Tech | .NET 10 | Latest LTS, excellent tooling, Aspire integration |
| Database | Azure SQL Serverless | Auto-pause saves costs, familiar SQL, EF Core support |
| Local Dev | Aspire | Service discovery, unified dashboard, simplified config |

### Cost Target

**$0-7/month per POC** achieved through:
- Free tier services where available
- Serverless/consumption pricing
- Scale-to-zero configuration
- Shared resources (SQL Server, Container Registry)

---

## Architecture Decisions

### Decision 1: Shared SQL Server, Per-POC Databases

**Context**: Azure SQL charges per database, but logical servers are free.

**Decision**: Use a single shared SQL Server (`dev-wiscodev`) with separate databases per POC.

**Rationale**:
- Server is free, only databases cost money
- Easier credential management
- Consistent firewall rules
- Each POC still has isolated data

**Trade-offs**:
- Single point of failure (acceptable for POCs)
- Shared admin credentials (acceptable for dev/POC)

### Decision 2: Shared Container Registry

**Context**: Azure Container Registry Basic tier costs ~$5/month.

**Decision**: Use a single shared ACR (`wiscodevacr`) for all POC images.

**Rationale**:
- Avoid $5/month per POC
- Images are namespaced by POC name
- Simple to manage

**Trade-offs**:
- All POCs share storage quota (500GB Basic tier - plenty)
- Need to coordinate image naming

### Decision 3: Container Apps over App Service

**Context**: Both can host .NET APIs. App Service Free tier has 60 min/day compute limit.

**Decision**: Use Container Apps with scale-to-zero.

**Rationale**:
- True scale-to-zero (no compute charges when idle)
- No daily compute limits
- Docker provides deployment consistency
- Consumption pricing = pay only when running

**Trade-offs**:
- Requires Docker knowledge
- Slightly more complex deployment
- Cold start latency (~2-5s)

### Decision 4: Static Web Apps for Frontend

**Context**: Multiple options exist for hosting static content.

**Decision**: Azure Static Web Apps Free tier.

**Rationale**:
- Completely free
- Built-in CI/CD options
- Global CDN included
- Custom domain support (free)

**Trade-offs**:
- Free tier limited to 2 custom domains
- No staging environments on free tier

### Decision 5: Vanilla JavaScript (No Framework)

**Context**: React, Vue, Angular, etc. are popular but add complexity.

**Decision**: Vanilla JavaScript for POC frontends.

**Rationale**:
- No build step required
- Simpler deployment (just copy files)
- Faster iteration for POCs
- Framework choice can be made later

**Trade-offs**:
- No component architecture
- Manual state management
- May need refactoring for production

### Decision 6: Aspire for Local Development Only

**Context**: Aspire can generate deployment manifests, but adds complexity.

**Decision**: Use Aspire for local orchestration, deploy manually to Azure.

**Rationale**:
- Aspire Dashboard invaluable for local dev
- Manual deployment gives more control
- Simpler to understand and debug
- Can adopt Aspire deployment later

**Trade-offs**:
- Manual configuration sync between local and Azure
- No automatic service discovery in production

---

## Prerequisites

### Required Tools

| Tool | Version | Installation |
|------|---------|--------------|
| .NET SDK | 10.0+ | `winget install Microsoft.DotNet.SDK.10` |
| Azure CLI | 2.50+ | `winget install Microsoft.AzureCLI` |
| Docker Desktop | Latest | `winget install Docker.DockerDesktop` |
| Node.js | 18+ | `winget install OpenJS.NodeJS.LTS` |
| SWA CLI | Latest | `npm install -g @azure/static-web-apps-cli` |

### Azure Setup

1. **Azure Subscription**: Active subscription with sufficient permissions
2. **Authentication**: `az login` completed
3. **Resource Providers**: Registered (scripts handle this automatically):
   - Microsoft.Sql
   - Microsoft.Web
   - Microsoft.App
   - Microsoft.ContainerRegistry

### Shared Resources (One-Time Setup)

These resources are shared across all POCs:

| Resource | Name | Resource Group |
|----------|------|----------------|
| SQL Server | `dev-wiscodev` | `Shared` |
| Container Registry | `wiscodevacr` | `Shared` |

If these don't exist, create them first (see [DECISIONS.md](DECISIONS.md) for setup commands).

---

## Phase 1: Infrastructure Setup

### Overview

In this phase, we create Azure resources specific to the POC:
- Dedicated resource group
- Database on shared SQL Server
- Static Web App for frontend

### Step 1.1: Create POC Infrastructure Folder

```bash
cd apps
mkdir {poc-name}
cd {poc-name}
```

This folder will contain:
- Infrastructure scripts
- Generated configuration files
- Environment-specific settings

### Step 1.2: Copy Infrastructure Scripts

```bash
# Copy from existing POC (todo-app is the template)
cp ../todo-app/setup-database.sh .
cp ../todo-app/setup-static-web-app.sh .
cp ../todo-app/.gitignore .
```

### Step 1.3: Configure Scripts

Edit each script to set your POC name:

```bash
# In setup-database.sh
APP_NAME="your-poc-name"

# In setup-static-web-app.sh
APP_NAME="your-poc-name"
```

### Step 1.4: Run Database Setup

```bash
chmod +x setup-database.sh
./setup-database.sh
```

**What this does**:
1. Checks/creates database on shared SQL Server
2. Adds your current IP to firewall rules
3. Generates `.env.local` with credentials
4. Generates `azure-config.json` with connection details

**Generated files**:
- `.env.local` - Contains sensitive credentials (gitignored)
- `azure-config.json` - Connection strings and server details

### Step 1.5: Run Static Web App Setup

```bash
chmod +x setup-static-web-app.sh
./setup-static-web-app.sh
```

**What this does**:
1. Creates dedicated resource group for the POC
2. Registers required Azure providers (if needed)
3. Creates Static Web App (Free tier)
4. Generates `azure-static-web-config.json` with deployment token

**Generated files**:
- `azure-static-web-config.json` - SWA URL and deployment token

### Verification

After running both scripts, you should have:

```
apps/{poc-name}/
├── .env.local                    # DB credentials (gitignored)
├── .gitignore                    # Protects sensitive files
├── azure-config.json             # Connection strings
├── azure-static-web-config.json  # SWA details + deployment token
├── setup-database.sh             # Infrastructure script
└── setup-static-web-app.sh       # Infrastructure script
```

---

## Phase 2: Aspire Solution

### Overview

Create a .NET Aspire solution with:
- AppHost (orchestrator)
- ServiceDefaults (shared configuration)
- API project (Web API)
- Web project (static file host)

### Step 2.1: Create Aspire Solution

```bash
cd TestPOCApp  # or your POC code location
mkdir {PocName}
cd {PocName}
dotnet new aspire -n {PocName}
```

This creates:
- `{PocName}.sln`
- `{PocName}.AppHost/` - Orchestrator project
- `{PocName}.ServiceDefaults/` - Shared defaults

### Step 2.2: Update to .NET 10

Aspire templates may default to .NET 9. Update all `.csproj` files:

```xml
<PropertyGroup>
  <TargetFramework>net10.0</TargetFramework>
</PropertyGroup>
```

Files to update:
- `{PocName}.AppHost/{PocName}.AppHost.csproj`
- `{PocName}.ServiceDefaults/{PocName}.ServiceDefaults.csproj`

### Step 2.3: Create API Project

```bash
mkdir -p src/{PocName}.Api
cd src/{PocName}.Api
dotnet new webapi -n {PocName}.Api --no-https
```

Configure the API project:

1. **Update to .NET 10** in `.csproj`

2. **Add project reference to ServiceDefaults**:
   ```xml
   <ItemGroup>
     <ProjectReference Include="..\..\{PocName}.ServiceDefaults\{PocName}.ServiceDefaults.csproj" />
   </ItemGroup>
   ```

3. **Add EF Core packages**:
   ```bash
   dotnet add package Microsoft.EntityFrameworkCore.SqlServer
   dotnet add package Microsoft.EntityFrameworkCore.Design
   ```

4. **Add to solution**:
   ```bash
   cd ../..
   dotnet sln add src/{PocName}.Api/{PocName}.Api.csproj
   ```

### Step 2.4: Create Web Project

```bash
mkdir -p src/{PocName}.Web
cd src/{PocName}.Web
dotnet new web -n {PocName}.Web
```

Configure the Web project:

1. **Update to .NET 10** in `.csproj`

2. **Add ServiceDefaults reference**

3. **Create wwwroot folder** with frontend files:
   ```
   wwwroot/
   ├── index.html
   ├── config.js        # API URL injection
   ├── css/
   │   └── styles.css
   └── js/
       └── app.js
   ```

4. **Configure Program.cs** for static files and config endpoint:
   ```csharp
   var builder = WebApplication.CreateBuilder(args);
   builder.AddServiceDefaults();

   var app = builder.Build();
   app.MapDefaultEndpoints();
   
   // Serve config.js with dynamic API URL
   app.MapGet("/config.js", (IConfiguration config) =>
   {
       var apiUrl = config["services:api:https:0"] 
                    ?? config["services:api:http:0"] 
                    ?? "http://localhost:5001";
       return Results.Content(
           $"window.API_BASE_URL = '{apiUrl}/api/todos';",
           "application/javascript"
       );
   });
   
   app.UseDefaultFiles();
   app.UseStaticFiles();
   app.MapFallbackToFile("index.html");
   app.Run();
   ```

5. **Add to solution**:
   ```bash
   dotnet sln add src/{PocName}.Web/{PocName}.Web.csproj
   ```

### Step 2.5: Configure AppHost

Edit `{PocName}.AppHost/AppHost.cs`:

```csharp
var builder = DistributedApplication.CreateBuilder(args);

var api = builder.AddProject<Projects.{PocName}_Api>("api");

var web = builder.AddProject<Projects.{PocName}_Web>("web")
    .WithReference(api)
    .WaitFor(api);

builder.Build().Run();
```

Add project references in `{PocName}.AppHost.csproj`:
```xml
<ItemGroup>
  <ProjectReference Include="..\src\{PocName}.Api\{PocName}.Api.csproj" />
  <ProjectReference Include="..\src\{PocName}.Web\{PocName}.Web.csproj" />
</ItemGroup>
```

### Step 2.6: Create Data Model

In `src/{PocName}.Api/`:

**Models/{Entity}.cs**:
```csharp
namespace {PocName}.Api.Models;

public class {Entity}
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public bool IsComplete { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

**Data/{PocName}DbContext.cs**:
```csharp
using Microsoft.EntityFrameworkCore;
using {PocName}.Api.Models;

namespace {PocName}.Api.Data;

public class {PocName}DbContext : DbContext
{
    public {PocName}DbContext(DbContextOptions<{PocName}DbContext> options) 
        : base(options) { }

    public DbSet<{Entity}> {Entities} => Set<{Entity}>();
}
```

### Step 2.7: Configure Database Connection

In API's `Program.cs`:

```csharp
builder.Services.AddDbContext<{PocName}DbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("{PocName}Db"),
        sqlOptions =>
        {
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 5,
                maxRetryDelay: TimeSpan.FromSeconds(30),
                errorNumbersToAdd: null);
        }));
```

In `appsettings.Development.json`:
```json
{
  "ConnectionStrings": {
    "{PocName}Db": "Server=dev-wiscodev.database.windows.net;Database={poc-name}-db;User Id={user};Password={pass};TrustServerCertificate=True;"
  }
}
```

### Step 2.8: Create Copy-Config Script

Create `copy-config.sh` in the Aspire solution root:

```bash
#!/bin/bash
# Copy configuration from infrastructure folder to Aspire solution

INFRA_DIR="../../apps/{poc-name}"
API_DIR="src/{PocName}.Api"

if [ -f "$INFRA_DIR/.env.local" ]; then
    source "$INFRA_DIR/.env.local"
    
    # Update appsettings.Development.json with actual credentials
    cat > "$API_DIR/appsettings.Development.json" << EOF
{
  "ConnectionStrings": {
    "{PocName}Db": "Server=$SQL_SERVER;Database=$SQL_DATABASE;User Id=$SQL_USER;Password=$SQL_PASSWORD;TrustServerCertificate=True;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}
EOF
    echo "Configuration copied successfully"
else
    echo "Error: $INFRA_DIR/.env.local not found"
    exit 1
fi
```

### Step 2.9: Apply Database Migration

```bash
cd src/{PocName}.Api
dotnet ef migrations add InitialCreate
dotnet ef database update
```

---

## Phase 3: Local Development

### Step 3.1: Run with Aspire

```bash
cd {PocName}
dotnet run --project {PocName}.AppHost
```

The Aspire Dashboard will open automatically (usually at `https://localhost:17135` or similar).

### Step 3.2: Verify Services

From the Aspire Dashboard:

1. **Check service health**: Both `api` and `web` should show "Running"
2. **Click API endpoint**: Should open Swagger or return data
3. **Click Web endpoint**: Should load the frontend
4. **Test full flow**: Create, read, update, delete operations

### Step 3.3: Debug Common Issues

| Issue | Solution |
|-------|----------|
| Database connection failed | Check credentials in appsettings.Development.json |
| API not accessible from frontend | Check CORS configuration in API |
| Services not starting | Check port conflicts, run `netstat -ano` |
| Slow first request | Azure SQL serverless waking up (30-60s) |

---

## Phase 4: Azure Deployment

### Step 4.1: Create Dockerfile

Create `src/{PocName}.Api/Dockerfile`:

```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy csproj files and restore
COPY ["src/{PocName}.Api/{PocName}.Api.csproj", "src/{PocName}.Api/"]
COPY ["{PocName}.ServiceDefaults/{PocName}.ServiceDefaults.csproj", "{PocName}.ServiceDefaults/"]
RUN dotnet restore "src/{PocName}.Api/{PocName}.Api.csproj"

# Copy everything else and build
COPY ["src/{PocName}.Api/", "src/{PocName}.Api/"]
COPY ["{PocName}.ServiceDefaults/", "{PocName}.ServiceDefaults/"]
RUN dotnet build "src/{PocName}.Api/{PocName}.Api.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "src/{PocName}.Api/{PocName}.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "{PocName}.Api.dll"]
```

**Important**: The Dockerfile is designed to be run from the solution root, not the API folder.

### Step 4.2: Build Docker Image

```bash
# From solution root
az acr login --name wiscodevacr

docker build \
  -t wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/{poc-name}-api:latest \
  -f src/{PocName}.Api/Dockerfile .
```

### Step 4.3: Push to Container Registry

```bash
docker push wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/{poc-name}-api:latest
```

### Step 4.4: Create Container Apps Environment

```bash
az containerapp env create \
  --name {poc-name}-env \
  --resource-group {poc-name} \
  --location centralus
```

This automatically creates a Log Analytics workspace for logging.

### Step 4.5: Deploy Container App

```bash
# Get ACR credentials
ACR_USER=$(az acr credential show --name wiscodevacr --resource-group Shared --query username -o tsv)
ACR_PASS=$(az acr credential show --name wiscodevacr --resource-group Shared --query "passwords[0].value" -o tsv)

# Deploy
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
  --env-vars 'ConnectionStrings__{PocName}Db=Server=dev-wiscodev.database.windows.net;Database={poc-name}-db;User Id={user};Password={pass};TrustServerCertificate=True;'
```

**Key configuration**:
- `--min-replicas 0`: Enables scale-to-zero
- `--max-replicas 1`: Limits costs for POC
- `--target-port 8080`: Default ASP.NET Core container port
- `--ingress external`: Makes API publicly accessible

### Step 4.6: Get API URL

```bash
API_URL=$(az containerapp show \
  --name {poc-name}-api \
  --resource-group {poc-name} \
  --query "properties.configuration.ingress.fqdn" -o tsv)

echo "API URL: https://$API_URL"
```

### Step 4.7: Update Frontend Configuration

Create production `config.js`:

```javascript
// src/{PocName}.Web/wwwroot/config.js
window.API_BASE_URL = 'https://{api-fqdn}/api/{entities}';
```

### Step 4.8: Deploy Frontend

```bash
cd src/{PocName}.Web/wwwroot

# Get deployment token from azure-static-web-config.json
TOKEN=$(cat ../../../../apps/{poc-name}/azure-static-web-config.json | jq -r '.staticWebApp.deploymentToken')

swa deploy . --deployment-token "$TOKEN" --env production
```

---

## Phase 5: Verification & Documentation

### Step 5.1: Verify Deployment

```bash
# Test API health
curl https://{api-url}/health

# Test API endpoint
curl https://{api-url}/api/{entities}

# Test frontend (open in browser)
open https://{swa-url}
```

### Step 5.2: Update Deployed Resources

Add entries to `docs/deployed-resources.md`:

```markdown
## POC: {poc-name}

### Resource Group: {poc-name}
- **Type**: Resource Group
- **Location**: centralus
- **Created**: {date}

### Database: {poc-name}-db
- **Type**: Microsoft.Sql/databases
- **Server**: dev-wiscodev (Shared)
- **Tier**: Serverless (0.5-1 vCores)
- **Estimated Cost**: $0-5/month

### Static Web App: {poc-name}-web
- **URL**: https://{swa-url}
- **Tier**: Free
- **Cost**: $0/month

### Container App: {poc-name}-api
- **URL**: https://{api-url}
- **Tier**: Consumption (scale to zero)
- **Cost**: $0-2/month
```

---

## Troubleshooting

### Database Issues

**Connection Timeout on First Request**
- Azure SQL Serverless takes 30-60 seconds to wake up
- Solution: EF Core retry configuration handles this automatically

**IP Not Whitelisted**
- Run `setup-database.sh` again to add current IP
- Or: Azure Portal → SQL Server → Networking → Add client IP

### Docker Issues

**Build Fails: File Not Found**
- Dockerfile paths are relative to build context (solution root)
- Run `docker build` from solution root, not API folder

**Push Denied**
- Run `az acr login --name wiscodevacr`

### Container Apps Issues

**Container Won't Start**
```bash
az containerapp logs show --name {app} --resource-group {rg} --follow
```

**Image Pull Failed**
- Verify ACR credentials are correct
- Check image name matches exactly

### Static Web Apps Issues

**Deploy Hangs**
- SWA CLI can be slow; try PowerShell script instead
- Check deployment token is valid

**404 on Frontend**
- Deployment may still be propagating (wait 1-2 minutes)
- Verify files were uploaded correctly

---

## Cost Management

### Expected Monthly Costs

| Resource | Min | Max | Notes |
|----------|-----|-----|-------|
| SQL Database | $0 | $5 | Auto-pause after 60 min |
| Container Apps | $0 | $2 | Scale to zero |
| Static Web Apps | $0 | $0 | Free tier |
| Container Registry | $5 | $5 | Shared across POCs |
| Log Analytics | $0 | $1 | Based on data volume |
| **Per-POC Total** | $0 | $7 | |

### Cost Optimization Tips

1. **Auto-pause databases**: 60-minute delay is optimal balance
2. **Scale to zero**: Container Apps `minReplicas: 0`
3. **Share resources**: Single ACR for all POCs
4. **Free tiers**: Static Web Apps, Functions (if used)
5. **Budget alerts**: Set alerts at $5 and $10 thresholds

### Monitoring Costs

```bash
# View current month's consumption
az consumption usage list \
  --start-date $(date -d 'month ago' +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --output table
```

---

## Appendix: File Templates

### .gitignore for apps/{poc-name}/

```
.env.local
*.local
```

### Frontend index.html Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{POC Name}</title>
    <link rel="stylesheet" href="css/styles.css">
    <script src="/config.js"></script>
</head>
<body>
    <div class="container">
        <h1>{POC Name}</h1>
        <!-- Your content here -->
    </div>
    <script src="js/app.js"></script>
</body>
</html>
```

### API Program.cs Template

```csharp
using Microsoft.EntityFrameworkCore;
using {PocName}.Api.Data;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

// Database
builder.Services.AddDbContext<{PocName}DbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("{PocName}Db"),
        sqlOptions => sqlOptions.EnableRetryOnFailure(5, TimeSpan.FromSeconds(30), null)));

// CORS
builder.Services.AddCors(options =>
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

var app = builder.Build();

app.MapDefaultEndpoints();
app.UseCors();

// Health endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

// API endpoints
app.MapGet("/api/{entities}", async ({PocName}DbContext db) =>
    await db.{Entities}.ToListAsync());

// ... more endpoints

app.Run();
```

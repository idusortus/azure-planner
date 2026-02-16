---
applyTo: "**/*.cs,**/*.csproj,**/appsettings*.json"
---

# .NET Aspire Development Instructions

**Purpose**: Instructions for GitHub Copilot when developing Aspire-based POC applications

## Framework Version

**IMPORTANT**: Use .NET 10 for all Aspire projects. The Aspire templates may default to `net9.0`, but .NET 10 is fully supported and should be used for consistency.

When creating new projects, ensure all `.csproj` files target `net10.0`:
```xml
<TargetFramework>net10.0</TargetFramework>
```

## Configuration Flow

Infrastructure scripts in `apps/{poc-name}/` generate configuration files:
- `azure-config.json` - Database and resource details
- `azure-static-web-config.json` - Static Web App configuration
- `.env.local` - Connection strings and secrets

Run `copy-config.sh` in the Aspire solution folder to propagate these configs to the API's `appsettings.Development.json`.

## Solution Structure

Standard Aspire solution layout:
```
{PocName}.sln
{PocName}.AppHost/             # Orchestration (local dev only)
{PocName}.ServiceDefaults/     # Shared configs — at SOLUTION ROOT, NOT in src/
src/
  {PocName}.Api/               # .NET WebAPI
  {PocName}.Web/               # Static files (wwwroot/)
```

**IMPORTANT**: `ServiceDefaults` lives at the **solution root**, not inside `src/`. Docker builds must account for this.

## AppHost Configuration

**Program.cs pattern**:
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

// Web frontend
builder.AddProject<Projects.{PocName}_Web>("web")
    .WithReference(api)
    .WithExternalHttpEndpoints();

builder.Build().Run();
```

## API Configuration

### Required Packages
```xml
<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" />
<PackageReference Include="Microsoft.EntityFrameworkCore.Design" />
<PackageReference Include="Azure.Identity" />
<PackageReference Include="Azure.Security.KeyVault.Secrets" />
```

### DbContext with Serverless Resiliency
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

### CORS Configuration
```csharp
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins(
            "https://localhost:5001",
            "https://*.azurestaticapps.net")
        .AllowAnyMethod()
        .AllowAnyHeader();
    });
});
```

### Health Checks
```csharp
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>();

// In app configuration
app.MapHealthChecks("/health");
```

### Connection String Pattern
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "TO_BE_PROVIDED"
  }
}
```

## Web Project (Static Files)

**Program.cs**:
```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();
app.MapFallbackToFile("index.html");

app.Run();
```

## EF Core Migrations

```bash
# Create migration
dotnet ef migrations add {MigrationName} --project src/{PocName}.Api

# Apply locally
dotnet ef database update --project src/{PocName}.Api

# Apply to Azure SQL
dotnet ef database update --project src/{PocName}.Api --connection "{connection-string}"
```

## Local Development

```bash
# Run Aspire
dotnet run --project src/{PocName}.AppHost

# Aspire Dashboard: http://localhost:15888
```

## Database Schema Isolation

All POCs share a single `sandbox` database. Each POC gets its own schema:

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.HasDefaultSchema("{poc_schema_name}");
}
```

## Azure Deployment

Deployment uses **manual Azure CLI** commands (not `azd`). See [docs/MASTER.md](../../docs/MASTER.md) Phase 4 for the full process:

```bash
# Build and push Docker image
az acr login --name wiscodevacr
docker build -t wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/{poc-name}-api:latest -f src/{PocName}.Api/Dockerfile .
docker push wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/{poc-name}-api:latest

# Deploy to shared Container Apps environment
MSYS_NO_PATHCONV=1 az containerapp create \
  --name {poc-name}-api \
  --resource-group {poc-name} \
  --environment "$ENV_ID" \
  --image wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/{poc-name}-api:latest \
  --target-port 8080 --ingress external \
  --min-replicas 0 --max-replicas 1
```

## Key Vault Integration

```csharp
// In Program.cs
if (!builder.Environment.IsDevelopment())
{
    var keyVaultUri = builder.Configuration["KeyVault:VaultUri"];
    builder.Configuration.AddAzureKeyVault(
        new Uri(keyVaultUri),
        new DefaultAzureCredential());
}
```

## Cost Optimization

- Container Apps: Consumption plan, min replicas = 0
- SQL Database: Serverless with auto-pause
- Always use retry logic for serverless database
- Configure health checks for proper scaling

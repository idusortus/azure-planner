---
mode: agent
description: Create and deploy a new POC application using our standard stack
tools: ['run_in_terminal', 'create_file', 'read_file', 'replace_string_in_file', 'list_dir', 'semantic_search']
---

# Create New POC Application

You are helping me create a new POC application using our established patterns.

## Context - Read First!

Before starting, read these documents to understand our patterns:
- `docs/poc-deployment/CHECKLIST.md` - Step-by-step process
- `docs/poc-deployment/GUIDE.md` - Detailed explanations  
- `docs/poc-deployment/DECISIONS.md` - Architecture decisions
- `apps/todo-app/` - Working example infrastructure scripts
- `TestPOCApp/TodoApp/` - Working example Aspire solution

## Our Stack

| Component | Technology | Azure Service |
|-----------|------------|---------------|
| Frontend | Vanilla JavaScript | Static Web Apps (Free) |
| Backend | .NET 10 Web API | Container Apps (Consumption) |
| Database | EF Core + SQL Server | Azure SQL Serverless |
| Orchestration | .NET 10 Aspire | Local dev only |

## Shared Resources (Already Created)

- **SQL Server**: `dev-wiscodev.database.windows.net` (in `Shared` RG)
- **Container Registry**: `wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io` (in `Shared` RG)
- **Subscription**: `e4b6b908-fa56-4b92-9e9c-5b0c855d13fe`

## Process Overview

### Phase 1: Infrastructure (`apps/{poc-name}/`)

1. Create folder: `apps/{poc-name}/`
2. Copy scripts from `apps/todo-app/`:
   - `setup-database.sh` (update APP_NAME)
   - `setup-static-web-app.sh` (update APP_NAME)
   - `.gitignore`
3. **ASK me before running scripts** (don't run automatically)
4. Verify generated config files exist

### Phase 2: Aspire Solution (`TestPOCApp/{PocName}/`)

1. Create Aspire solution: `dotnet new aspire`
2. **CRITICAL: Update ALL .csproj files to `net10.0`**
3. Create API project with:
   - EF Core DbContext with retry logic (5 retries, 30s delay)
   - Models for the business domain
   - CRUD endpoints via minimal APIs
   - Health endpoint at `/health`
   - CORS enabled for all origins
4. Create Web project with:
   - Static file hosting
   - `/config.js` endpoint for Aspire service discovery
   - `wwwroot/` with HTML, CSS, JS
5. Configure AppHost with project references and `WithReference()`
6. Create `copy-config.sh` to sync credentials from `apps/{poc-name}/`

### Phase 3: Local Testing

1. Run `./copy-config.sh`
2. Apply EF migrations: `dotnet ef migrations add InitialCreate && dotnet ef database update`
3. Run with Aspire: `dotnet run --project {PocName}.AppHost`
4. Verify in Aspire Dashboard

### Phase 4: Azure Deployment

1. Create Dockerfile (paths relative to solution root!)
2. Build and push to shared ACR
3. Create Container Apps environment in `{poc-name}` RG
4. Deploy API with connection string env var
5. Create production `config.js` with Container App URL
6. Deploy frontend with SWA CLI

### Phase 5: Documentation

1. Update `docs/deployed-resources.md` with new resources
2. Update `docs/poc-deployment/` docs if we learned something new

## Critical Patterns

### EF Core Retry (handles serverless DB wake-up)
```csharp
options.UseSqlServer(connectionString, sqlOptions =>
    sqlOptions.EnableRetryOnFailure(
        maxRetryCount: 5,
        maxRetryDelay: TimeSpan.FromSeconds(30),
        errorNumbersToAdd: null));
```

### Service Discovery (config.js endpoint in Web project)
```csharp
app.MapGet("/config.js", (IConfiguration config) =>
{
    var apiUrl = config["services:api:https:0"] 
                 ?? config["services:api:http:0"] 
                 ?? "http://localhost:5001";
    return Results.Content(
        $"window.API_BASE_URL = '{apiUrl}/api/{entities}';",
        "application/javascript");
});
```

### Docker Image Tag
```
wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/{poc-name}-api:latest
```

### Connection String Format
```
Server=dev-wiscodev.database.windows.net;Database={poc-name}-db;User Id={user};Password={pass};TrustServerCertificate=True;
```

## Living Documentation Rule

After completing the POC, if we learn something new:
1. Update `docs/poc-deployment/CHECKLIST.md` if process changed
2. Update `docs/poc-deployment/GUIDE.md` if explanations needed
3. Add decisions to `docs/poc-deployment/DECISIONS.md`
4. Update this prompt if instructions need refinement

**Do this automatically without me asking!**

## User Input Required

Please provide:
1. **POC Name**: kebab-case (e.g., `my-new-app`)
2. **Description**: What does this POC demonstrate?
3. **Main Entity**: Primary data model (e.g., "Task", "Product")
4. **Entity Fields**: Key properties (name, type, required)

---

# My Request

{user_input}

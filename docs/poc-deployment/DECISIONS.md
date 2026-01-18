# Architecture Decision Records

**Purpose**: Document key decisions made during POC platform development.

---

## ADR-001: Shared SQL Server with Per-POC Databases

**Date**: January 17, 2026  
**Status**: ~~Accepted~~ **SUPERSEDED by ADR-014** (Schema-Based Database Isolation)

### Context
Azure SQL charges per database. We need multiple POCs but want to minimize costs.

### Decision
~~Use a single shared SQL Server (`dev-wiscodev`) in the `Shared` resource group. Each POC gets its own database on this server.~~

**UPDATE (January 18, 2026)**: This approach was superseded by ADR-014 which consolidates all POCs into a single `sandbox` database using SQL schemas for isolation. See ADR-014 for details.

### Consequences
- ✅ Server is free (only databases cost money)
- ✅ Simplified credential management
- ✅ Consistent firewall rules across POCs
- ⚠️ Single point of failure (acceptable for POCs)
- ⚠️ Shared admin credentials (acceptable for dev)

---

## ADR-002: Shared Container Registry

**Date**: January 17, 2026  
**Status**: Accepted

### Context
Azure Container Registry Basic tier costs ~$5/month. Multiple POCs would multiply this cost.

### Decision
Use a single shared ACR (`wiscodevacr`) for all POC images. Images are namespaced by POC name (e.g., `{poc-name}-api`).

### Consequences
- ✅ Avoids $5/month per POC
- ✅ 500GB storage shared across all POCs
- ⚠️ Requires coordinated image naming
- ⚠️ Single registry failure affects all POCs

---

## ADR-003: Container Apps over App Service

**Date**: January 17, 2026  
**Status**: Accepted

### Context
Need to host .NET APIs cost-effectively. Options considered:
- App Service Free (F1): 60 min/day compute limit
- App Service Basic (B1): ~$13/month always-on
- Container Apps Consumption: Pay-per-use, scale-to-zero
- Azure Functions: Good for event-driven, not traditional APIs

### Decision
Use Azure Container Apps with Consumption plan and `minReplicas: 0`.

### Consequences
- ✅ True scale-to-zero (no charges when idle)
- ✅ No daily compute limits
- ✅ Docker provides consistency
- ⚠️ Requires Docker knowledge
- ⚠️ Cold start latency (~2-5 seconds)
- ⚠️ More complex deployment than App Service

---

## ADR-004: Static Web Apps for Frontend

**Date**: January 17, 2026  
**Status**: Accepted

### Context
Need free/cheap hosting for JavaScript frontends. Options:
- Azure Blob Storage + CDN: Requires configuration
- App Service: Overkill for static files
- Static Web Apps: Built for this purpose

### Decision
Use Azure Static Web Apps Free tier.

### Consequences
- ✅ Completely free
- ✅ Global CDN included
- ✅ Easy deployment via CLI
- ⚠️ Free tier: 2 custom domains max
- ⚠️ No staging environments on free tier

---

## ADR-005: Vanilla JavaScript Frontend

**Date**: January 17, 2026  
**Status**: Accepted

### Context
POCs need quick iteration. Framework options add build complexity.

### Decision
Use vanilla JavaScript for POC frontends. No React, Vue, Angular, etc.

### Consequences
- ✅ No build step required
- ✅ Faster iteration
- ✅ Framework choice deferred to production
- ⚠️ No component architecture
- ⚠️ Manual state management
- ⚠️ May need rewrite for production

---

## ADR-006: Aspire for Local Development Only

**Date**: January 17, 2026  
**Status**: Accepted

### Context
.NET Aspire provides both local orchestration and deployment capabilities. Could use Aspire deployment or manual deployment.

### Decision
Use Aspire only for local development. Deploy manually using Azure CLI.

### Consequences
- ✅ Aspire Dashboard for local dev
- ✅ More control over deployment
- ✅ Easier to understand and debug
- ⚠️ Manual config sync between local/Azure
- ⚠️ No automatic service discovery in production

---

## ADR-007: EF Core Retry Configuration

**Date**: January 17, 2026  
**Status**: Accepted

### Context
Azure SQL Serverless databases pause after 60 minutes of inactivity. First connection can take 30-60 seconds to wake up.

### Decision
Configure EF Core with retry logic: 5 retries, 30-second max delay.

```csharp
sqlOptions.EnableRetryOnFailure(
    maxRetryCount: 5,
    maxRetryDelay: TimeSpan.FromSeconds(30),
    errorNumbersToAdd: null);
```

### Consequences
- ✅ Handles serverless wake-up gracefully
- ✅ Transparent to application code
- ⚠️ First request may be slow (up to 60s)
- ⚠️ Health checks may timeout initially

---

## ADR-008: Service Discovery via Static Config

**Date**: January 17, 2026  
**Status**: Accepted

### Context
Aspire provides automatic service discovery locally. In production, we need a different approach.

### Decision
Frontend loads `/config.js` which contains the API URL:
- Local: Aspire injects URL via Web backend endpoint
- Production: Static `config.js` file with hardcoded API URL

### Consequences
- ✅ Simple to implement
- ✅ Works with Static Web Apps
- ⚠️ Requires updating config.js for each environment
- ⚠️ API URL exposed in client-side code (acceptable for POCs)

---

## ADR-009: ACR Admin Credentials over Managed Identity

**Date**: January 17, 2026  
**Status**: Accepted (for now)

### Context
Container Apps can pull from ACR using:
- Managed Identity (more secure, complex setup)
- Admin credentials (simpler, less secure)

### Decision
Use ACR admin credentials for POC deployments. Consider managed identity for production.

### Consequences
- ✅ Simple deployment commands
- ✅ Works immediately without role assignments
- ⚠️ Admin credentials less secure
- ⚠️ Should migrate to managed identity for production

---

## ADR-010: .NET 10 for All Projects

**Date**: January 17, 2026  
**Status**: Accepted

### Context
Aspire templates may default to .NET 9. We have .NET 10 SDK installed.

### Decision
Update all projects to `net10.0` for consistency and to use latest features.

### Consequences
- ✅ Latest .NET features available
- ✅ Consistent across all projects
- ⚠️ May need to watch for compatibility issues
- ⚠️ Docker images must use `mcr.microsoft.com/dotnet/*:10.0`

---

## ADR-011: GitHub Actions for Static Web App Deployment

**Date**: January 17, 2026  
**Status**: Accepted

### Context
Initial approach used SWA CLI for frontend deployment, which consistently timed out due to network/firewall issues in corporate environments. Static Web Apps were created without GitHub integration.

### Decision
Create Static Web Apps **with GitHub integration** from the start using `az staticwebapp create --source --branch --token`. This automatically sets up GitHub Actions workflows for deployment.

### Implementation
```bash
az staticwebapp create \
  --name {poc-name}-web \
  --resource-group {poc-name} \
  --location centralus \
  --source https://github.com/{org}/{repo} \
  --branch main \
  --token {github-token}
```

Azure automatically:
1. Creates the Static Web App
2. Generates a GitHub Actions workflow in `.github/workflows/`
3. Configures deployment on push to `main`

Manual step: Fix `app_location` in generated workflow to point to `TestPOCApp/{PocName}/src/{PocName}.Web/wwwroot`.

### Consequences
- ✅ Eliminates SWA CLI timeout issues
- ✅ Automatic deployments on every push to main
- ✅ Deployment logs visible in GitHub Actions
- ✅ Works in corporate environments with restrictive firewalls
- ✅ No manual deployment steps required
- ⚠️ Requires GitHub personal access token during setup
- ⚠️ Must remember to fix `app_location` in generated workflow

### Alternatives Considered
- **SWA CLI manual deployment**: Consistently timed out
- **Portal file upload**: Manual and not repeatable
- **Recreating SWA**: Didn't solve the root CLI timeout issue

---

## ADR-012: Shared Container Apps Environment

**Date**: January 17, 2026  
**Status**: Accepted

### Context
Azure subscription has a limit of 1 Container Apps environment per region (on free/trial subscriptions). Creating a new environment for each POC fails.

### Decision
Share the existing Container Apps environment (`todoapp-env` in `todo-app` resource group) across all POCs.

### Implementation
When deploying a new POC's Container App:
1. Get the full resource ID of the shared environment:
   ```bash
   ENV_ID=$(az containerapp env show --name todoapp-env --resource-group todo-app --query id -o tsv)
   ```
2. Reference by full ID (use `MSYS_NO_PATHCONV=1` in Git Bash to prevent path mangling):
   ```bash
   MSYS_NO_PATHCONV=1 az containerapp create \
     --environment "$ENV_ID" \
     ...
   ```

### Consequences
- ✅ Works around subscription environment limit
- ✅ Saves on Log Analytics workspace costs (shared)
- ✅ Faster deployment (no env creation wait)
- ⚠️ Cross-resource-group reference requires full resource ID
- ⚠️ Git Bash mangles paths - must use `MSYS_NO_PATHCONV=1`
- ⚠️ Environment name/RG in cleanup commands differ from app's RG

---

## ADR-013: ACR Credentials Must Be Explicit

**Date**: January 17, 2026  
**Status**: Accepted

### Context
Azure Container Apps doesn't auto-detect ACR credentials even when logged in with `az acr login`. This causes "Failed to retrieve credentials" errors.

### Decision
Always provide explicit `--registry-username` and `--registry-password` parameters when creating Container Apps.

### Implementation
```bash
ACR_USER=$(az acr credential show --name wiscodevacr --query username -o tsv)
ACR_PASS=$(az acr credential show --name wiscodevacr --query "passwords[0].value" -o tsv)

az containerapp create \
  --registry-server wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io \
  --registry-username "$ACR_USER" \
  --registry-password "$ACR_PASS" \
  ...
```

### Consequences
- ✅ Reliable deployment without credential lookup failures
- ⚠️ Credentials visible in command history (acceptable for POCs)
- 📋 Future: Consider managed identity for production

---

## ADR-014: Schema-Based Database Isolation

**Date**: January 18, 2026  
**Status**: Accepted (supersedes ADR-001)

### Context
ADR-001 created separate databases per POC on a shared SQL Server. While serverless with auto-pause, each database still incurred potential costs ($0-5/month each) and was outside the free tier quota (1 free database).

### Decision
Consolidate all POC data into a **single `sandbox` database** using **SQL schemas** for isolation:

| App | Schema | EF Core Config |
|-----|--------|----------------|
| TodoApp | `todo` | `modelBuilder.HasDefaultSchema("todo")` |
| LeaveACommentApp | `comments` | `modelBuilder.HasDefaultSchema("comments")` |
| FriendsPrediction | `predictions` | (future) |

### Implementation

1. **Create schemas in sandbox database**:
   ```sql
   CREATE SCHEMA [todo];
   CREATE SCHEMA [comments];
   ```

2. **Configure EF Core DbContext**:
   ```csharp
   protected override void OnModelCreating(ModelBuilder modelBuilder)
   {
       modelBuilder.HasDefaultSchema("todo"); // or "comments"
       // ... rest of configuration
   }
   ```

3. **Update connection strings** to point to `sandbox` database:
   ```
   Server=tcp:dev-wiscodev.database.windows.net,1433;Database=sandbox;...
   ```

4. **Regenerate migrations** (delete old migrations, create new with schema):
   ```bash
   rm -rf Migrations/
   dotnet ef migrations add InitialCreate_{Schema}Schema
   dotnet ef database update
   ```

5. **Delete old databases**:
   ```bash
   az sql db delete --name todo-app-db --server dev-wiscodev --resource-group Shared --yes
   az sql db delete --name leave-a-comment-app-db --server dev-wiscodev --resource-group Shared --yes
   az sql db delete --name friends-prediction-db --server dev-wiscodev --resource-group Shared --yes
   ```

### Consequences
- ✅ **$10-15/month savings** - single free-tier database instead of multiple
- ✅ **Simplified management** - one database to monitor/backup
- ✅ **Clean isolation** - each app only sees its schema tables
- ✅ **Free tier eligible** - sandbox is the one free serverless DB
- ⚠️ **Shared connection pool** - all apps share same DB resources
- ⚠️ **Schema awareness required** - EF migrations must be schema-aware
- ⚠️ **Manual schema creation** - schemas must be created before first migration

### Migration Notes
- **Development connection string** must also point to `sandbox` for EF tools to work correctly
- EF Core `__EFMigrationsHistory` table is shared (in `dbo` schema) but migrations are per-app
- Each app's migrations track their own schema's changes independently

---

## ADR-015: Git Bash Path Mangling Workaround

**Date**: January 17-18, 2026  
**Status**: Accepted

### Context
Git Bash on Windows converts forward-slash paths to Unix-style paths, which breaks Azure CLI commands that pass resource IDs.

### Decision
Prefix all `az` commands that include resource IDs with `MSYS_NO_PATHCONV=1`.

### Implementation
```bash
# Without prefix - FAILS (path mangled)
az containerapp update --name myapp --resource-group myrg --set-env-vars "ConnectionStrings__MyDb=$CONN_STR"

# With prefix - WORKS
MSYS_NO_PATHCONV=1 az containerapp update --name myapp --resource-group myrg --set-env-vars "ConnectionStrings__MyDb=$CONN_STR"
```

### Consequences
- ✅ Commands work correctly in Git Bash
- ⚠️ Easy to forget prefix (add to documentation)
- 📋 Alternative: Use PowerShell for Azure commands

---

## Future Considerations

### Accepted & In Use
- ✅ **GitHub Actions CI/CD**: Now standard for Static Web App deployments (ADR-011)
- ✅ **Shared Container Apps Environment**: Required due to subscription limits (ADR-012)
- ✅ **Explicit ACR Credentials**: Required for reliable deployments (ADR-013)

### Under Evaluation
- **Managed Identity for ACR**: More secure than admin credentials
- **Azure Key Vault**: Better secret management than env vars
- **Application Insights**: Better observability

### Explicitly Deferred
- **Multi-region deployment**: Not needed for POCs
- **Custom domains**: Can add later if needed
- **SSL certificates**: Static Web Apps provides automatic HTTPS
- **API versioning**: Not needed for simple POCs

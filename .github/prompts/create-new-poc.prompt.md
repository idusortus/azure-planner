# Create New POC Application

Use this prompt to start a new POC application in this workspace.

## Instructions

When I ask you to create a new POC application, follow this process:

### Phase 1: Infrastructure Setup

1. **Create POC folder**: `apps/{poc-name}/`

2. **Copy and customize setup scripts** from `apps/friends-prediction/`:
   - `setup-database.sh` - Update `APP_NAME="{poc-name}"`
   - `setup-static-web-app.sh` - Update `APP_NAME="{poc-name}"`
   - `setup-keyvault.sh` (optional) - Update `APP_NAME="{poc-name}"`
   - `setup-budget-alert.sh` (optional) - Update `APP_NAME="{poc-name}"`

3. **Create `.gitignore`** for sensitive files:
   ```
   .env*
   azure-*.json
   SETUP_NOTES.md
   *.connection.json
   ```

4. **Create `README.md`** with setup instructions

5. **Run setup scripts** (with user confirmation):
   ```bash
   ./setup-database.sh
   ./setup-static-web-app.sh
   ```

### Phase 2: Aspire Solution

1. **Create solution** in appropriate folder:
   ```bash
   dotnet new aspire -n {PocName}
   dotnet new webapi -n {PocName}.Api -o src/{PocName}.Api
   dotnet new web -n {PocName}.Web -o src/{PocName}.Web
   dotnet sln add src/{PocName}.Api src/{PocName}.Web
   ```

2. **Configure AppHost** with SQL Server and project references

3. **Build API** with:
   - EF Core DbContext with retry logic
   - Controllers for business logic
   - Health checks
   - CORS configuration

4. **Build Frontend** in `wwwroot/`:
   - Vanilla JavaScript SPA
   - Environment-aware API URL
   - Responsive CSS

### Phase 3: Test & Deploy

1. **Test locally**: `dotnet run --project src/{PocName}.AppHost`
2. **Apply migrations**: `dotnet ef database update`
3. **Deploy**: `azd init && azd up`

## Configuration Reference

**Shared Resources** (in `Shared` resource group):
- SQL Server: `dev-wiscodev.database.windows.net`
- Service Bus: `wiscoshared`

**Per-POC Resources** (in `{poc-name}` resource group):
- Static Web App: `{poc-name}-web`
- Container App: Created by `azd up`
- Key Vault: `{poc-name}-kv` (optional)
- Storage: `{poc-name}storage` (optional)

**Cost Target**: $0-7/month per POC

## Reference Documents

- Full setup guide: `/docs/POC-Setup-Guide.md`
- Aspire conversion: `/docs/github-copilot-aspire-conversion-prompt.md`
- Azure operations: `/.github/instructions/azure-operations.instructions.md`

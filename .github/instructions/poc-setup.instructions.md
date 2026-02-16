---
applyTo: "apps/**"
---

# POC Application Setup Instructions

**Purpose**: Instructions for GitHub Copilot when setting up new POC applications

## Context

This workspace uses a standardized approach for creating budget-friendly Azure POC applications:

- **Infrastructure**: Bash scripts in `apps/{poc-name}/` provision Azure resources
- **Application**: .NET 10 Aspire solutions with WebAPI + JavaScript SPA
- **Database**: Azure SQL Serverless on shared SQL Server (`dev-wiscodev`), shared `sandbox` database with schema-per-POC isolation
- **Deployment**: Azure Container Apps + Static Web Apps via manual Azure CLI (see `docs/MASTER.md`)

## Infrastructure Scripts

Each POC folder should contain setup scripts. Reference `apps/friends-prediction/` for templates.

### Required Scripts

**`setup-database.sh`**:
- Creates schema in shared `sandbox` database (NOT a separate database)
- Configures firewall rules
- Generates connection string
- Outputs to `azure-config.json` and `.env.local`

**`setup-static-web-app.sh`**:
- Creates dedicated resource group for POC
- Creates Static Web App (Free tier)
- Generates deployment token
- Auto-registers Microsoft.Web provider if needed

### Optional Scripts

**`setup-storage.sh`**: Azure Storage Account  
**`setup-keyvault.sh`**: Azure Key Vault  
**`setup-budget-alert.sh`**: Cost monitoring alerts

## Script Configuration

When creating or modifying scripts, update these variables:
```bash
APP_NAME="{poc-name}"           # Used for resource naming
RESOURCE_GROUP="${APP_NAME}"    # Dedicated RG per POC
LOCATION="centralus"            # Standard region
SQL_SERVER_NAME="dev-wiscodev"  # Shared SQL Server
SQL_DATABASE="sandbox"          # Shared database (schema isolation)
```

## Resource Group Strategy

**Shared (`Shared` RG)**:
- SQL Server: `dev-wiscodev`
- Service Bus: `wiscoshared`

**Per-POC (`{poc-name}` RG)**:
- Static Web App
- Container App (via Aspire)
- Storage Account
- Key Vault

## Generated Files

Setup scripts create these files (all git-ignored):
- `azure-config.json` - Database configuration
- `azure-static-web-config.json` - Static Web App details  
- `azure-storage-config.json` - Storage configuration
- `azure-keyvault-config.json` - Key Vault details
- `.env.local` - All connection strings and secrets
- `SETUP_NOTES.md` - Manual documentation

## Script Requirements

All scripts must:
1. Check Azure CLI authentication
2. Be idempotent (check existence before creating)
3. Auto-register resource providers if needed
4. Show progress for long-running operations
5. Generate configuration files
6. Provide cleanup commands
7. Display cost estimates

## Cost Targets

- **Static Web Apps**: $0 (Free tier)
- **Container Apps**: $0-2 (consumption, scale-to-zero)
- **SQL Database**: $0-5 (serverless, auto-pause)
- **Key Vault**: ~$0.03/10K ops
- **Storage**: $0.50-2 (LRS)
- **Total per POC**: $0-7/month

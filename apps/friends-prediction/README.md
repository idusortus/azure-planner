# Friends Prediction - Azure Configuration

**POC Application**: Friends Prediction Market  
**Azure Resource Group**: Shared (centralus)  
**Status**: Ready for setup

## Quick Start

Run these scripts in order to set up your Azure infrastructure:

### 1. Database Setup

```bash
cd apps/friends-prediction
chmod +x setup-database.sh
./setup-database.sh
```

The script will:
- ✅ Check Azure authentication
- ✅ Create SQL Server (if needed)
- ✅ Create database (idempotent)
- ✅ Configure firewall rules
- ✅ Generate connection strings
- ✅ Create configuration files

### 2. Static Web App Setup

```bash
chmod +x setup-static-web-app.sh
./setup-static-web-app.sh
```

The script will:
- ✅ Create/verify resource group
- ✅ Create Static Web App (free tier)
- ✅ Generate deployment token
- ✅ Create deployment configurations
- ✅ Optionally create GitHub Actions workflow

### 3. Configure Your Application

After running the setup script:

1. **Update password** in `.env.local`
2. **Copy connection string** to your Aspire application:
   ```json
   // In src/FriendsPrediction.Api/appsettings.json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Server=tcp://YOUR_SERVER.database.windows.net,1433;Database=friends-prediction-db;User ID=sqladmin;Password=YOUR_PASSWORD;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
     }
   }
   ```

3. **Run EF Core migrations**:
   ```bash
   dotnet ef database update --project src/FriendsPrediction.Api
   ```

## Azure Resources

Resources will be documented in `azure-config.json` after running setup script.

**Expected Resources**:
- SQL Server: `{server-name}.database.windows.net`
- Database: `friends-prediction-db`
- Firewall Rules: Your IP + Azure Services

**Estimated Cost**: $0-5/month (serverless with auto-pause)

## Scripts

- `setup-database.sh` - Database and SQL Server setup (run first)
- `setup-static-web-app.sh` - Static Web App setup (run second)

## Generated Files (git-ignored)

- `azure-config.json` - Database configuration
- `azure-static-web-config.json` - Static Web App configuration
- `.env.local` - Environment variables for local development
- `.github/workflows/azure-static-web-apps.yml` - Optional deployment workflow

## Manual Setup (Alternative)

If you prefer manual setup:

### Create Database
```bash
az sql db create \
  --resource-group Shared \
  --server YOUR_SERVER_NAME \
  --name friends-prediction-db \
  --edition GeneralPurpose \
  --compute-model Serverless \
  --family Gen5 \
  --capacity 1 \
  --auto-pause-delay 60 \
  --min-capacity 0.5 \
  --backup-storage-redundancy Local
```

### Add Firewall Rules
```bash
# Your IP
az sql server firewall-rule create \
  --resource-group Shared \
  --server YOUR_SERVER_NAME \
  --name AllowMyIP \
  --start-ip-address YOUR_IP \
  --end-ip-address YOUR_IP

# Azure Services
az sql server firewall-rule create \
  --resource-group Shared \
  --server YOUR_SERVER_NAME \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### Get Connection String
```bash
az sql db show-connection-string \
  -Deployment Options

After running both setup scripts, you can deploy your frontend:

### Option A: Azure Static Web Apps CLI
```bash
npm install -g @azure/static-web-apps-cli
swa deploy ./dist --deployment-token $SWA_DEPLOYMENT_TOKEN
```

### Option B: GitHub Actions
1. Add `AZURE_STATIC_WEB_APPS_API_TOKEN` secret to GitHub repo
2. Push code - automatic deployment via GitHub Actions

### Option C: Azure Portal
Upload built files manually through the portal

## Cleanup

When you're done with this POC:

```bash
# Delete database (keeps SQL Server for other POCs)
az sql db delete \
  --name friends-prediction-db \
  --server YOUR_SERVER_NAME \
  --resource-group Shared \
  --yes

# Delete Static Web App
az staticwebapp delete \
  --name friends-prediction-web \
  --resource-group Shared

# Delete entire resource group (if you created a dedicated one)
az group delete --name friends-prediction --yes --no-wait
# Delete firewall rule (optional)
az sql server firewall-rule delete \
  --name AllowMyIP-YOUR-IP \
  --server YOUR_SERVER_NAME \
  --resource-group Shared
```

## Troubleshooting

**Authentication Failed**
```bash
az login
az account set --subscription "Azure subscription 1"
```

**Can't Connect to Database**
- Check firewall rules include your current IP
- Verify password is correct
- Ensure database isn't paused (first connection may take 10-30 seconds)

**Script Permission Denied**
```bash
chmod +x setup-database.sh
```

## Next Steps

1. Run the setup script
2. Convert your POC to Aspire format (see `/docs/github-copilot-aspire-conversion-prompt.md`)
3. Configure connection string in Aspire application
4. Deploy to Azure Container Apps

# Azure Developer CLI (azd) Deployment Guide

## Prerequisites

### 1. Install Azure Developer CLI

**Windows (PowerShell)**:
```powershell
winget install microsoft.azd
```

**Windows (Chocolatey)**:
```powershell
choco install azd
```

**macOS**:
```bash
brew tap azure/azd
brew install azd
```

**Linux**:
```bash
curl -fsSL https://aka.ms/install-azd.sh | bash
```

Verify installation:
```bash
azd version
```

### 2. Authenticate with Azure

```bash
az login
azd auth login
```

## Deployment Steps

### Option 1: Use Existing Resources (Recommended)

Since we already have Azure resources created, we'll configure azd to use them:

```bash
cd TestPOCApp/TodoApp

# Initialize azd
azd init

# When prompted:
# - Environment name: dev
# - Use current directory: Yes

# Configure to use existing resource group
azd env set AZURE_RESOURCE_GROUP "todo-app"
azd env set AZURE_LOCATION "centralus"
azd env set AZURE_SUBSCRIPTION_ID "e4b6b908-fa56-4b92-9e9c-5b0c855d13fe"

# Deploy
azd up
```

### Option 2: Manual Container Deployment

If `azd` has issues with Aspire, deploy manually:

#### API to Container Apps

```bash
# Build and push Docker image
cd src/TodoApp.Api
az acr create --name todoappregistry --resource-group todo-app --sku Basic
az acr login --name todoappregistry

# Build image
docker build -t todoappregistry.azurecr.io/todoapp-api:latest .
docker push todoappregistry.azurecr.io/todoapp-api:latest

# Create Container App
az containerapp create \
  --name todoapp-api \
  --resource-group todo-app \
  --image todoappregistry.azurecr.io/todoapp-api:latest \
  --environment todoapp-env \
  --ingress external \
  --target-port 8080 \
  --env-vars \
    "ConnectionStrings__TodoDb=Server=tcp:dev-wiscodev.database.windows.net,1433;Database=todo-app-db;User ID=BryceAndConrad;Password=Tolerance0715#!;Encrypt=True;" \
  --cpu 0.5 \
  --memory 1.0Gi \
  --min-replicas 0 \
  --max-replicas 1
```

#### Frontend to Static Web App

Static Web App is already created. Update its linked API:

```bash
# Get Container App URL
API_URL=$(az containerapp show --name todoapp-api --resource-group todo-app --query properties.configuration.ingress.fqdn -o tsv)

# Update Static Web App configuration
az staticwebapp appsettings set \
  --name todo-app-web \
  --resource-group todo-app \
  --setting-names API_BASE_URL="https://$API_URL/api/todos"
```

Deploy frontend:
```bash
cd src/TodoApp.Web

# Install SWA CLI (if not installed)
npm install -g @azure/static-web-apps-cli

# Deploy
swa deploy \
  --app-location ./wwwroot \
  --deployment-token "YOUR_DEPLOYMENT_TOKEN_FROM_azure-static-web-config.json"
```

## Post-Deployment

### Verify API

```bash
# Get API URL
API_URL=$(az containerapp show --name todoapp-api --resource-group todo-app --query properties.configuration.ingress.fqdn -o tsv)

# Test health endpoint
curl https://$API_URL/health

# Test todos endpoint
curl https://$API_URL/api/todos
```

### Verify Frontend

```bash
# Get Static Web App URL (from azure-static-web-config.json)
# Should be: https://happy-desert-065eace10.6.azurestaticapps.net
```

### Monitor Logs

```bash
# Container App logs
az containerapp logs show \
  --name todoapp-api \
  --resource-group todo-app \
  --follow

# Static Web App logs (via portal)
# https://portal.azure.com -> todo-app-web -> Log stream
```

## Cost Monitoring

```bash
# Check current costs
az consumption usage list \
  --start-date $(date -d '7 days ago' +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query "[?contains(instanceName, 'todo-app')].{Name:instanceName, Cost:pretaxCost}" \
  --output table
```

## Cleanup

When done testing:

```bash
# Delete Container App (keeps database)
az containerapp delete --name todoapp-api --resource-group todo-app --yes

# Or delete entire resource group
az group delete --name todo-app --yes --no-wait

# Delete database from shared SQL Server
az sql db delete --name todo-app-db --server dev-wiscodev --resource-group Shared --yes
```

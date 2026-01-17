#!/bin/bash
# Friends Prediction - Azure Static Web App Setup Script
# This script idempotently creates and configures Azure Static Web App resources

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="friends-prediction"
RESOURCE_GROUP="${RESOURCE_GROUP:-$APP_NAME}"  # Default to dedicated RG per POC
LOCATION="centralus"
STATIC_WEB_APP_NAME="${APP_NAME}-web"
STORAGE_ACCOUNT_NAME="${APP_NAME//-/}storage"  # Remove hyphens for storage account name
SKU="Free"

# GitHub repo settings (optional - can be added later via portal)
GITHUB_REPO="${GITHUB_REPO:-}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Friends Prediction - Static Web App Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed${NC}"
    echo "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check authentication
echo -e "${YELLOW}🔐 Checking Azure authentication...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not authenticated with Azure${NC}"
    echo "Run: az login"
    exit 1
fi

ACCOUNT_NAME=$(az account show --query "user.name" -o tsv)
SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
echo -e "${GREEN}✓ Authenticated as: ${ACCOUNT_NAME}${NC}"
echo -e "${GREEN}✓ Subscription: ${SUBSCRIPTION_ID}${NC}"
echo ""

# Check and register Microsoft.Web provider if needed
echo -e "${YELLOW}🔍 Checking Microsoft.Web provider registration...${NC}"
PROVIDER_STATE=$(az provider show --namespace Microsoft.Web --query "registrationState" -o tsv 2>/dev/null || echo "NotRegistered")

if [ "$PROVIDER_STATE" != "Registered" ]; then
    echo -e "${YELLOW}⚠️  Microsoft.Web provider not registered${NC}"
    echo -e "${YELLOW}Registering provider (this may take 1-2 minutes)...${NC}"
    
    az provider register --namespace Microsoft.Web --wait
    
    echo -e "${GREEN}✓ Microsoft.Web provider registered${NC}"
else
    echo -e "${GREEN}✓ Microsoft.Web provider already registered${NC}"
fi
echo ""

# Ask about resource group preference
echo -e "${YELLOW}Resource Group Configuration${NC}"
echo ""
echo -e "Options:"
echo -e "  1) Create dedicated '${APP_NAME}' resource group (recommended - easier cleanup)"
echo -e "  2) Use 'Shared' resource group (for shared infrastructure only)"
echo ""
echo -e "${BLUE}Note: Shared resources (SQL Server, Service Bus) should stay in 'Shared' RG${NC}"
echo -e "${BLUE}      POC apps (Static Web App, Container App, Storage) get dedicated RG${NC}"
echo ""
read -p "Enter choice (1 or 2) [default: 1]: " RG_CHOICE
RG_CHOICE=${RG_CHOICE:-1}

if [ "$RG_CHOICE" == "2" ]; then
    RESOURCE_GROUP="Shared"
    echo -e "${YELLOW}Will use shared resource group: ${RESOURCE_GROUP}${NC}"
else
    RESOURCE_GROUP="$APP_NAME"
    echo -e "${YELLOW}Will use dedicated resource group: ${RESOURCE_GROUP}${NC}"
fi
echo ""

# Check if resource group exists, create if needed
echo -e "${YELLOW}🔍 Checking resource group...${NC}"
RG_EXISTS=$(az group exists --name "$RESOURCE_GROUP")

if [ "$RG_EXISTS" == "false" ]; then
    echo -e "${YELLOW}Creating resource group: ${RESOURCE_GROUP}${NC}"
    
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --tags "app=$APP_NAME" "cost-center=poc" "environment=development"
    
    echo -e "${GREEN}✓ Resource group created: ${RESOURCE_GROUP}${NC}"
else
    echo -e "${GREEN}✓ Resource group exists: ${RESOURCE_GROUP}${NC}"
fi
echo ""

# Check if Static Web App exists
echo -e "${YELLOW}🔍 Checking if Static Web App exists...${NC}"
SWA_EXISTS=$(az staticwebapp list --resource-group "$RESOURCE_GROUP" --query "[?name=='$STATIC_WEB_APP_NAME'].name" -o tsv)

if [ -z "$SWA_EXISTS" ]; then
    echo -e "${YELLOW}Creating Static Web App: ${STATIC_WEB_APP_NAME}${NC}"
    
    if [ -n "$GITHUB_REPO" ]; then
        echo -e "${YELLOW}  With GitHub repository: ${GITHUB_REPO}${NC}"
        
        az staticwebapp create \
            --name "$STATIC_WEB_APP_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku "$SKU" \
            --source "$GITHUB_REPO" \
            --branch "$GITHUB_BRANCH" \
            --app-location "/" \
            --output-location "dist" \
            --tags "app=$APP_NAME" "cost-center=poc" "environment=development"
    else
        echo -e "${YELLOW}  Without GitHub integration (can be added later)${NC}"
        
        az staticwebapp create \
            --name "$STATIC_WEB_APP_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku "$SKU" \
            --tags "app=$APP_NAME" "cost-center=poc" "environment=development"
    fi
    
    echo -e "${GREEN}✓ Static Web App created: ${STATIC_WEB_APP_NAME}${NC}"
else
    echo -e "${GREEN}✓ Static Web App already exists: ${STATIC_WEB_APP_NAME}${NC}"
fi
echo ""

# Get Static Web App details
echo -e "${YELLOW}📝 Retrieving Static Web App details...${NC}"
SWA_DETAILS=$(az staticwebapp show --name "$STATIC_WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" -o json)
SWA_URL=$(echo "$SWA_DETAILS" | grep -o '"defaultHostname": "[^"]*"' | cut -d'"' -f4)
SWA_ID=$(echo "$SWA_DETAILS" | grep -o '"id": "[^"]*"' | cut -d'"' -f4)

echo -e "${GREEN}✓ Static Web App URL: https://${SWA_URL}${NC}"
echo ""

# Get deployment token
echo -e "${YELLOW}🔑 Retrieving deployment token...${NC}"
DEPLOYMENT_TOKEN=$(az staticwebapp secrets list --name "$STATIC_WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" --query "properties.apiKey" -o tsv)
echo -e "${GREEN}✓ Deployment token retrieved${NC}"
echo ""

# Create configuration file
CONFIG_FILE="./azure-static-web-config.json"
echo -e "${YELLOW}📝 Creating configuration file...${NC}"

cat > "$CONFIG_FILE" <<EOF
{
  "appName": "$APP_NAME",
  "resourceGroup": "$RESOURCE_GROUP",
  "location": "$LOCATION",
  "staticWebApp": {
    "name": "$STATIC_WEB_APP_NAME",
    "url": "https://$SWA_URL",
    "sku": "$SKU",
    "resourceId": "$SWA_ID",
    "deploymentToken": "$DEPLOYMENT_TOKEN"
  },
  "deployment": {
    "recommended": "Azure Static Web Apps CLI (swa)",
    "githubActions": {
      "note": "Configure in GitHub repo settings",
      "secret": "AZURE_STATIC_WEB_APPS_API_TOKEN",
      "value": "[Use deploymentToken above]"
    }
  },
  "estimatedCost": {
    "staticWebApp": "$0/month",
    "note": "Free tier includes 100GB bandwidth/month"
  }
}
EOF

echo -e "${GREEN}✓ Configuration saved to: ${CONFIG_FILE}${NC}"
echo ""

# Update .env file if it exists
ENV_FILE="./.env.local"
if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}📝 Updating existing .env file...${NC}"
    
    # Check if SWA variables already exist
    if grep -q "SWA_DEPLOYMENT_TOKEN" "$ENV_FILE"; then
        echo -e "${GREEN}✓ Static Web App variables already in .env file${NC}"
    else
        cat >> "$ENV_FILE" <<EOF

# Static Web App Configuration
SWA_DEPLOYMENT_TOKEN=${DEPLOYMENT_TOKEN}
SWA_URL=https://${SWA_URL}
SWA_NAME=${STATIC_WEB_APP_NAME}
EOF
        echo -e "${GREEN}✓ Static Web App variables added to .env file${NC}"
    fi
else
    echo -e "${YELLOW}📝 Creating .env file...${NC}"
    
    cat > "$ENV_FILE" <<EOF
# Friends Prediction - Local Development Configuration
# Generated: $(date)

# Static Web App Configuration
SWA_DEPLOYMENT_TOKEN=${DEPLOYMENT_TOKEN}
SWA_URL=https://${SWA_URL}
SWA_NAME=${STATIC_WEB_APP_NAME}

# API Configuration (update after running setup-database.sh)
API_PORT=7001
API_BASE_URL=https://localhost:7001

# Frontend Configuration
WEB_PORT=5000
EOF
    
    echo -e "${GREEN}✓ Environment file created: ${ENV_FILE}${NC}"
fi
echo ""

# Create deployment workflow (optional)
echo -e "${YELLOW}Would you like to create a GitHub Actions workflow for automatic deployment?${NC}"
read -p "Create workflow file? (y/n) [default: n]: " CREATE_WORKFLOW
CREATE_WORKFLOW=${CREATE_WORKFLOW:-n}

if [[ "$CREATE_WORKFLOW" =~ ^[Yy]$ ]]; then
    WORKFLOW_DIR="./.github/workflows"
    WORKFLOW_FILE="$WORKFLOW_DIR/azure-static-web-apps.yml"
    
    mkdir -p "$WORKFLOW_DIR"
    
    cat > "$WORKFLOW_FILE" <<'EOF'
name: Azure Static Web Apps CI/CD

on:
  push:
    branches:
      - main
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches:
      - main

jobs:
  build_and_deploy:
    if: github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.action != 'closed')
    runs-on: ubuntu-latest
    name: Build and Deploy
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: true

      - name: Build And Deploy
        id: builddeploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "/" # App source code path
          api_location: "" # API source code path - optional
          output_location: "dist" # Built app content directory

  close_pull_request:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    name: Close Pull Request
    steps:
      - name: Close Pull Request
        id: closepullrequest
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          action: "close"
EOF
    
    echo -e "${GREEN}✓ GitHub Actions workflow created: ${WORKFLOW_FILE}${NC}"
    echo -e "${YELLOW}  Remember to add AZURE_STATIC_WEB_APPS_API_TOKEN secret to GitHub repo${NC}"
    echo ""
fi

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Resources Created/Verified:${NC}"
echo -e "  Resource Group: ${RESOURCE_GROUP}"
echo -e "  Static Web App: ${STATIC_WEB_APP_NAME}"
echo -e "  URL: https://${SWA_URL}"
echo -e "  SKU: ${SKU} ($0/month)"
echo ""
echo -e "${GREEN}Configuration Files:${NC}"
echo -e "  ${CONFIG_FILE} - Static Web App details"
echo -e "  ${ENV_FILE} - Environment variables"
if [[ "$CREATE_WORKFLOW" =~ ^[Yy]$ ]]; then
    echo -e "  .github/workflows/azure-static-web-apps.yml - Deployment workflow"
fi
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo -e "${BLUE}Option 1: Deploy with Azure Static Web Apps CLI${NC}"
echo -e "  1. Install: ${BLUE}npm install -g @azure/static-web-apps-cli${NC}"
echo -e "  2. Deploy: ${BLUE}swa deploy ./dist --deployment-token \$SWA_DEPLOYMENT_TOKEN${NC}"
echo ""
echo -e "${BLUE}Option 2: Deploy with GitHub Actions${NC}"
echo -e "  1. Push code to GitHub repository"
echo -e "  2. Add secret AZURE_STATIC_WEB_APPS_API_TOKEN in repo settings"
echo -e "     Value: ${DEPLOYMENT_TOKEN}"
echo -e "  3. Commit .github/workflows/azure-static-web-apps.yml"
echo -e "  4. Push to main branch - automatic deployment!"
echo ""
echo -e "${BLUE}Option 3: Manual Deployment${NC}"
echo -e "  Use the Azure Portal to upload your built app files"
echo ""
echo -e "${YELLOW}Configure API URL in your frontend:${NC}"
echo -e "  After deploying your API, update frontend to use:"
echo -e "  ${BLUE}https://YOUR_API_URL/api${NC}"
echo ""
echo -e "${YELLOW}View your app:${NC}"
echo -e "  ${GREEN}https://${SWA_URL}${NC}"
echo ""
echo -e "${YELLOW}Cleanup (when done with POC):${NC}"
if [ "$RESOURCE_GROUP" == "Shared" ]; then
    echo -e "  ${RED}az staticwebapp delete --name ${STATIC_WEB_APP_NAME} --resource-group ${RESOURCE_GROUP}${NC}"
else
    echo -e "  ${RED}az group delete --name ${RESOURCE_GROUP} --yes --no-wait${NC}"
fi
echo ""
echo -e "${GREEN}✅ All done!${NC}"

#!/bin/bash
# TODO App - Azure Key Vault Setup Script
# This script idempotently creates and configures Azure Key Vault

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="todo-app"
RESOURCE_GROUP="${APP_NAME}"  # Use POC's resource group
LOCATION="centralus"
KEYVAULT_NAME="${APP_NAME}-kv"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}TODO App - Key Vault Setup${NC}"
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
USER_OBJECT_ID=$(az ad signed-in-user show --query "id" -o tsv 2>/dev/null || echo "")
echo -e "${GREEN}✓ Authenticated as: ${ACCOUNT_NAME}${NC}"
echo -e "${GREEN}✓ Subscription: ${SUBSCRIPTION_ID}${NC}"
echo ""

# Check and register Microsoft.KeyVault provider if needed
echo -e "${YELLOW}🔍 Checking Microsoft.KeyVault provider registration...${NC}"
PROVIDER_STATE=$(az provider show --namespace Microsoft.KeyVault --query "registrationState" -o tsv 2>/dev/null || echo "NotRegistered")

if [ "$PROVIDER_STATE" != "Registered" ]; then
    echo -e "${YELLOW}⚠️  Microsoft.KeyVault provider not registered${NC}"
    echo -e "${YELLOW}Registering provider (this may take 1-2 minutes)...${NC}"
    
    az provider register --namespace Microsoft.KeyVault --wait
    
    echo -e "${GREEN}✓ Microsoft.KeyVault provider registered${NC}"
else
    echo -e "${GREEN}✓ Microsoft.KeyVault provider already registered${NC}"
fi
echo ""

# Check if resource group exists
echo -e "${YELLOW}🔍 Checking resource group...${NC}"
RG_EXISTS=$(az group exists --name "$RESOURCE_GROUP")

if [ "$RG_EXISTS" == "false" ]; then
    echo -e "${RED}❌ Resource group '${RESOURCE_GROUP}' does not exist${NC}"
    echo -e "${YELLOW}Run setup-static-web-app.sh first to create the resource group${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Resource group exists: ${RESOURCE_GROUP}${NC}"
echo ""

# Check if Key Vault exists
echo -e "${YELLOW}🔍 Checking if Key Vault exists...${NC}"
KV_EXISTS=$(az keyvault list --resource-group "$RESOURCE_GROUP" --query "[?name=='$KEYVAULT_NAME'].name" -o tsv)

if [ -z "$KV_EXISTS" ]; then
    echo -e "${YELLOW}Creating Key Vault: ${KEYVAULT_NAME}${NC}"
    echo -e "${YELLOW}This may take 30-60 seconds, please wait...${NC}"
    echo -ne "${YELLOW}⏳ Progress: "
    
    # Create Key Vault
    (
        az keyvault create \
            --name "$KEYVAULT_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku standard \
            --enable-rbac-authorization false \
            --tags "app=$APP_NAME" "cost-center=poc" "environment=development" \
            --output none 2>&1
    ) &
    
    CREATION_PID=$!
    
    # Show progress while waiting
    while kill -0 $CREATION_PID 2>/dev/null; do
        echo -n "."
        sleep 2
    done
    
    wait $CREATION_PID
    CREATION_EXIT_CODE=$?
    
    echo -e "${NC}"
    
    if [ $CREATION_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✓ Key Vault created: ${KEYVAULT_NAME}${NC}"
    else
        echo -e "${RED}❌ Key Vault creation failed${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Key Vault already exists: ${KEYVAULT_NAME}${NC}"
fi
echo ""

# Get Key Vault details
echo -e "${YELLOW}📝 Retrieving Key Vault details...${NC}"
KV_URI=$(az keyvault show --name "$KEYVAULT_NAME" --resource-group "$RESOURCE_GROUP" --query "properties.vaultUri" -o tsv)
echo -e "${GREEN}✓ Key Vault URI: ${KV_URI}${NC}"
echo ""

# Set access policy for current user
if [ -n "$USER_OBJECT_ID" ]; then
    echo -e "${YELLOW}🔑 Setting access policy for current user...${NC}"
    
    az keyvault set-policy \
        --name "$KEYVAULT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --object-id "$USER_OBJECT_ID" \
        --secret-permissions get list set delete \
        --output none
    
    echo -e "${GREEN}✓ Access policy set for user${NC}"
else
    echo -e "${YELLOW}⚠️  Could not retrieve user object ID, set access policy manually${NC}"
fi
echo ""

# Store database connection string if .env.local exists
if [ -f "./.env.local" ]; then
    echo -e "${YELLOW}Would you like to store database connection string in Key Vault?${NC}"
    read -p "Store secrets? (y/n) [default: y]: " STORE_SECRETS
    STORE_SECRETS=${STORE_SECRETS:-y}

    if [[ "$STORE_SECRETS" =~ ^[Yy]$ ]]; then
        # Read connection string from .env.local
        DB_CONNECTION=$(grep "^CONNECTION_STRING=" ./.env.local | cut -d'=' -f2-)
        
        if [ -n "$DB_CONNECTION" ] && [[ "$DB_CONNECTION" != *"YOUR_PASSWORD_HERE"* ]]; then
            echo -e "${YELLOW}Storing database connection string in Key Vault...${NC}"
            
            az keyvault secret set \
                --vault-name "$KEYVAULT_NAME" \
                --name "DbConnectionString" \
                --value "$DB_CONNECTION" \
                --output none
            
            echo -e "${GREEN}✓ Secret 'DbConnectionString' stored in Key Vault${NC}"
        else
            echo -e "${YELLOW}⚠️  Connection string not found or contains placeholder${NC}"
            echo -e "${YELLOW}   Update .env.local with actual password first!${NC}"
        fi
    fi
fi
echo ""

# Create configuration file
CONFIG_FILE="./azure-keyvault-config.json"
echo -e "${YELLOW}📝 Creating configuration file...${NC}"

cat > "$CONFIG_FILE" <<EOF
{
  "appName": "$APP_NAME",
  "resourceGroup": "$RESOURCE_GROUP",
  "location": "$LOCATION",
  "keyVault": {
    "name": "$KEYVAULT_NAME",
    "uri": "$KV_URI",
    "sku": "standard"
  },
  "secrets": {
    "DbConnectionString": "Database connection string"
  },
  "usage": {
    "dotnet": "builder.Configuration.AddAzureKeyVault(new Uri(\"$KV_URI\"), new DefaultAzureCredential());",
    "azureCli": "az keyvault secret show --vault-name $KEYVAULT_NAME --name SecretName --query value -o tsv"
  },
  "estimatedCost": {
    "keyVault": "~\$0.03/10K operations",
    "note": "Minimal cost for POC usage"
  }
}
EOF

echo -e "${GREEN}✓ Configuration saved to: ${CONFIG_FILE}${NC}"
echo ""

# Update .env file
ENV_FILE="./.env.local"
if [ -f "$ENV_FILE" ]; then
    if ! grep -q "KEYVAULT_URI" "$ENV_FILE"; then
        cat >> "$ENV_FILE" <<EOF

# Azure Key Vault Configuration
KEYVAULT_NAME=${KEYVAULT_NAME}
KEYVAULT_URI=${KV_URI}
EOF
        echo -e "${GREEN}✓ Key Vault variables added to .env file${NC}"
    fi
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Resources Created/Verified:${NC}"
echo -e "  Key Vault: ${KEYVAULT_NAME}"
echo -e "  URI: ${KV_URI}"
echo ""
echo -e "${YELLOW}Store a secret:${NC}"
echo -e "  az keyvault secret set --vault-name ${KEYVAULT_NAME} --name MySecret --value \"secret-value\""
echo ""
echo -e "${YELLOW}Use in .NET:${NC}"
echo -e "  builder.Configuration.AddAzureKeyVault(new Uri(\"${KV_URI}\"), new DefaultAzureCredential());"
echo ""
echo -e "${GREEN}✅ All done!${NC}"

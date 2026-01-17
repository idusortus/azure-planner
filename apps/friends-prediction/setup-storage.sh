#!/bin/bash
# Friends Prediction - Azure Storage Account Setup Script
# This script idempotently creates and configures Azure Storage Account

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="friends-prediction"
RESOURCE_GROUP="${APP_NAME}"  # Use POC's resource group
LOCATION="centralus"
STORAGE_ACCOUNT_NAME="${APP_NAME//-/}storage"  # Remove hyphens, add 'storage'
SKU="Standard_LRS"  # Locally redundant storage (cheapest)
KIND="StorageV2"     # General purpose v2

# Container names (customize as needed)
DEFAULT_CONTAINERS=("uploads" "assets" "backups")

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Friends Prediction - Storage Account Setup${NC}"
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

# Check and register Microsoft.Storage provider if needed
echo -e "${YELLOW}🔍 Checking Microsoft.Storage provider registration...${NC}"
PROVIDER_STATE=$(az provider show --namespace Microsoft.Storage --query "registrationState" -o tsv 2>/dev/null || echo "NotRegistered")

if [ "$PROVIDER_STATE" != "Registered" ]; then
    echo -e "${YELLOW}⚠️  Microsoft.Storage provider not registered${NC}"
    echo -e "${YELLOW}Registering provider (this may take 1-2 minutes)...${NC}"
    
    az provider register --namespace Microsoft.Storage --wait
    
    echo -e "${GREEN}✓ Microsoft.Storage provider registered${NC}"
else
    echo -e "${GREEN}✓ Microsoft.Storage provider already registered${NC}"
fi
echo ""

# Validate storage account name (must be 3-24 chars, lowercase alphanumeric)
STORAGE_NAME_LENGTH=${#STORAGE_ACCOUNT_NAME}
if [ $STORAGE_NAME_LENGTH -lt 3 ] || [ $STORAGE_NAME_LENGTH -gt 24 ]; then
    echo -e "${RED}❌ Storage account name must be 3-24 characters${NC}"
    echo -e "${RED}   Current name: ${STORAGE_ACCOUNT_NAME} (${STORAGE_NAME_LENGTH} chars)${NC}"
    exit 1
fi

if [[ ! "$STORAGE_ACCOUNT_NAME" =~ ^[a-z0-9]+$ ]]; then
    echo -e "${RED}❌ Storage account name can only contain lowercase letters and numbers${NC}"
    echo -e "${RED}   Current name: ${STORAGE_ACCOUNT_NAME}${NC}"
    exit 1
fi

echo -e "${YELLOW}Storage account name: ${STORAGE_ACCOUNT_NAME}${NC}"
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

# Check if storage account exists
echo -e "${YELLOW}🔍 Checking if storage account exists...${NC}"
STORAGE_EXISTS=$(az storage account check-name --name "$STORAGE_ACCOUNT_NAME" --query "nameAvailable" -o tsv)

if [ "$STORAGE_EXISTS" == "false" ]; then
    # Check if it's in our resource group
    STORAGE_RG=$(az storage account list --query "[?name=='$STORAGE_ACCOUNT_NAME'].resourceGroup" -o tsv)
    
    if [ "$STORAGE_RG" == "$RESOURCE_GROUP" ]; then
        echo -e "${GREEN}✓ Storage account already exists: ${STORAGE_ACCOUNT_NAME}${NC}"
    else
        echo -e "${RED}❌ Storage account '${STORAGE_ACCOUNT_NAME}' exists in different resource group: ${STORAGE_RG}${NC}"
        echo -e "${YELLOW}Choose a different name or use existing account${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Creating storage account: ${STORAGE_ACCOUNT_NAME}${NC}"
    echo -e "${YELLOW}This may take 30-60 seconds, please wait...${NC}"
    echo -ne "${YELLOW}⏳ Progress: "
    
    # Create storage account - show dots for progress
    (
        az storage account create \
            --name "$STORAGE_ACCOUNT_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku "$SKU" \
            --kind "$KIND" \
            --access-tier Hot \
            --allow-blob-public-access false \
            --min-tls-version TLS1_2 \
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
        echo -e "${GREEN}✓ Storage account created: ${STORAGE_ACCOUNT_NAME}${NC}"
        echo -e "${GREEN}  SKU: ${SKU} (Locally redundant)${NC}"
        echo -e "${GREEN}  Kind: ${KIND}${NC}"
    else
        echo -e "${RED}❌ Storage account creation failed${NC}"
        exit 1
    fi
fi
echo ""

# Get storage account key
echo -e "${YELLOW}🔑 Retrieving storage account key...${NC}"
STORAGE_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP" --account-name "$STORAGE_ACCOUNT_NAME" --query "[0].value" -o tsv)
echo -e "${GREEN}✓ Storage key retrieved${NC}"
echo ""

# Get connection string
echo -e "${YELLOW}🔗 Generating connection string...${NC}"
CONNECTION_STRING=$(az storage account show-connection-string --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --query "connectionString" -o tsv)
echo -e "${GREEN}✓ Connection string generated${NC}"
echo ""

# Ask about static website hosting
echo -e "${YELLOW}Enable static website hosting?${NC}"
echo -e "  (Useful for hosting additional static content or SPAs)"
read -p "Enable static website hosting? (y/n) [default: n]: " ENABLE_STATIC_WEB
ENABLE_STATIC_WEB=${ENABLE_STATIC_WEB:-n}

if [[ "$ENABLE_STATIC_WEB" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Enabling static website hosting...${NC}"
    
    az storage blob service-properties update \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --static-website \
        --404-document "404.html" \
        --index-document "index.html"
    
    STATIC_WEB_URL=$(az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --query "primaryEndpoints.web" -o tsv)
    echo -e "${GREEN}✓ Static website hosting enabled${NC}"
    echo -e "${GREEN}  URL: ${STATIC_WEB_URL}${NC}"
    echo ""
fi

# Create default blob containers
echo -e "${YELLOW}📦 Creating default blob containers...${NC}"
for container in "${DEFAULT_CONTAINERS[@]}"; do
    CONTAINER_EXISTS=$(az storage container exists --name "$container" --account-name "$STORAGE_ACCOUNT_NAME" --account-key "$STORAGE_KEY" --query "exists" -o tsv)
    
    if [ "$CONTAINER_EXISTS" == "true" ]; then
        echo -e "${GREEN}✓ Container exists: ${container}${NC}"
    else
        az storage container create \
            --name "$container" \
            --account-name "$STORAGE_ACCOUNT_NAME" \
            --account-key "$STORAGE_KEY" \
            --public-access off
        
        echo -e "${GREEN}✓ Container created: ${container}${NC}"
    fi
done
echo ""

# Get blob endpoint
BLOB_ENDPOINT=$(az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --query "primaryEndpoints.blob" -o tsv)

# Create configuration file
CONFIG_FILE="./azure-storage-config.json"
echo -e "${YELLOW}📝 Creating configuration file...${NC}"

cat > "$CONFIG_FILE" <<EOF
{
  "appName": "$APP_NAME",
  "resourceGroup": "$RESOURCE_GROUP",
  "location": "$LOCATION",
  "storageAccount": {
    "name": "$STORAGE_ACCOUNT_NAME",
    "sku": "$SKU",
    "kind": "$KIND",
    "blobEndpoint": "$BLOB_ENDPOINT",
    "connectionString": "$CONNECTION_STRING"
  },
  "containers": $(printf '%s\n' "${DEFAULT_CONTAINERS[@]}" | jq -R . | jq -s .),
  "staticWebsite": {
    "enabled": $([ "$ENABLE_STATIC_WEB" == "y" ] && echo "true" || echo "false"),
    "url": "${STATIC_WEB_URL:-null}"
  },
  "estimatedCost": {
    "storage": "$0.50-2/month",
    "note": "LRS (locally redundant), minimal usage"
  }
}
EOF

echo -e "${GREEN}✓ Configuration saved to: ${CONFIG_FILE}${NC}"
echo ""

# Update .env file if it exists
ENV_FILE="./.env.local"
if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}📝 Updating existing .env file...${NC}"
    
    # Check if storage variables already exist
    if grep -q "AZURE_STORAGE_ACCOUNT_NAME" "$ENV_FILE"; then
        echo -e "${GREEN}✓ Storage account variables already in .env file${NC}"
    else
        cat >> "$ENV_FILE" <<EOF

# Azure Storage Configuration
AZURE_STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME}
AZURE_STORAGE_ACCOUNT_KEY=${STORAGE_KEY}
AZURE_STORAGE_CONNECTION_STRING=${CONNECTION_STRING}
AZURE_STORAGE_BLOB_ENDPOINT=${BLOB_ENDPOINT}
EOF
        echo -e "${GREEN}✓ Storage account variables added to .env file${NC}"
    fi
else
    echo -e "${YELLOW}📝 Creating .env file...${NC}"
    
    cat > "$ENV_FILE" <<EOF
# Friends Prediction - Local Development Configuration
# Generated: $(date)

# Azure Storage Configuration
AZURE_STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME}
AZURE_STORAGE_ACCOUNT_KEY=${STORAGE_KEY}
AZURE_STORAGE_CONNECTION_STRING=${CONNECTION_STRING}
AZURE_STORAGE_BLOB_ENDPOINT=${BLOB_ENDPOINT}
EOF
    
    echo -e "${GREEN}✓ Environment file created: ${ENV_FILE}${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Resources Created/Verified:${NC}"
echo -e "  Resource Group: ${RESOURCE_GROUP}"
echo -e "  Storage Account: ${STORAGE_ACCOUNT_NAME}"
echo -e "  SKU: ${SKU}"
echo -e "  Blob Endpoint: ${BLOB_ENDPOINT}"
echo -e "  Containers: ${DEFAULT_CONTAINERS[*]}"
if [[ "$ENABLE_STATIC_WEB" =~ ^[Yy]$ ]]; then
    echo -e "  Static Website: ${STATIC_WEB_URL}"
fi
echo ""
echo -e "${GREEN}Configuration Files:${NC}"
echo -e "  ${CONFIG_FILE} - Storage account details"
echo -e "  ${ENV_FILE} - Environment variables"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo -e "${BLUE}Using in .NET/C# (Aspire/WebAPI):${NC}"
echo -e "  1. Add package: ${BLUE}dotnet add package Azure.Storage.Blobs${NC}"
echo -e "  2. In Program.cs:"
echo -e "     ${BLUE}builder.AddAzureBlobClient(\"storage\");${NC}"
echo -e "  3. Connection string in appsettings.json or environment"
echo ""
echo -e "${BLUE}Using in JavaScript:${NC}"
echo -e "  1. Install: ${BLUE}npm install @azure/storage-blob${NC}"
echo -e "  2. Use connection string from .env file"
echo ""
echo -e "${BLUE}Upload files via CLI:${NC}"
echo -e "  ${BLUE}az storage blob upload \\${NC}"
echo -e "    ${BLUE}--account-name ${STORAGE_ACCOUNT_NAME} \\${NC}"
echo -e "    ${BLUE}--container-name uploads \\${NC}"
echo -e "    ${BLUE}--name myfile.txt \\${NC}"
echo -e "    ${BLUE}--file ./myfile.txt${NC}"
echo ""
echo -e "${YELLOW}Cleanup (when done with POC):${NC}"
echo -e "  Storage account will be deleted with resource group:"
echo -e "  ${RED}az group delete --name ${RESOURCE_GROUP} --yes --no-wait${NC}"
echo ""
echo -e "${GREEN}✅ All done!${NC}"

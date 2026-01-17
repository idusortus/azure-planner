#!/bin/bash
# TODO App - Azure Database Setup Script
# This script idempotently creates and configures Azure SQL Database resources

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="todo-app"
RESOURCE_GROUP="Shared"
LOCATION="centralus"
SQL_SERVER_NAME="${SQL_SERVER_NAME:-dev-wiscodev}"  # Use existing shared SQL Server
DB_NAME="${APP_NAME}-db"
SQL_ADMIN_USER="sqladmin"
SQL_ADMIN_PASSWORD="${SQL_ADMIN_PASSWORD:-}"  # Will prompt if not set

# Database Configuration (Serverless, budget-friendly)
DB_EDITION="GeneralPurpose"
DB_COMPUTE_MODEL="Serverless"
DB_FAMILY="Gen5"
DB_CAPACITY=1
DB_MIN_CAPACITY=0.5
DB_AUTO_PAUSE_DELAY=60
DB_BACKUP_STORAGE="Local"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}TODO App - Database Setup${NC}"
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

# Check if SQL Server exists
echo -e "${YELLOW}🔍 Checking if SQL Server exists...${NC}"
SERVER_EXISTS=$(az sql server list --resource-group "$RESOURCE_GROUP" --query "[?name=='$SQL_SERVER_NAME'].name" -o tsv)

if [ -z "$SERVER_EXISTS" ]; then
    echo -e "${YELLOW}⚠️  SQL Server '$SQL_SERVER_NAME' does not exist${NC}"
    echo -e "${YELLOW}Creating new SQL Server...${NC}"
    
    # Get admin password if not provided
    if [ -z "$SQL_ADMIN_PASSWORD" ]; then
        echo -e "${YELLOW}Enter SQL admin password (will be hidden):${NC}"
        read -s SQL_ADMIN_PASSWORD
        echo ""
        
        if [ -z "$SQL_ADMIN_PASSWORD" ]; then
            echo -e "${RED}❌ Admin password is required${NC}"
            exit 1
        fi
    fi
    
    # Create SQL Server
    az sql server create \
        --name "$SQL_SERVER_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --admin-user "$SQL_ADMIN_USER" \
        --admin-password "$SQL_ADMIN_PASSWORD" \
        --enable-public-network true
    
    echo -e "${GREEN}✓ SQL Server created: ${SQL_SERVER_NAME}${NC}"
else
    echo -e "${GREEN}✓ SQL Server exists: ${SQL_SERVER_NAME}${NC}"
fi
echo ""

# Check if database exists
echo -e "${YELLOW}🔍 Checking if database exists...${NC}"
DB_EXISTS=$(az sql db list --resource-group "$RESOURCE_GROUP" --server "$SQL_SERVER_NAME" --query "[?name=='$DB_NAME'].name" -o tsv)

if [ -z "$DB_EXISTS" ]; then
    echo -e "${YELLOW}Creating database: ${DB_NAME}${NC}"
    echo -e "${YELLOW}This may take 30-60 seconds...${NC}"
    
    az sql db create \
        --resource-group "$RESOURCE_GROUP" \
        --server "$SQL_SERVER_NAME" \
        --name "$DB_NAME" \
        --edition "$DB_EDITION" \
        --compute-model "$DB_COMPUTE_MODEL" \
        --family "$DB_FAMILY" \
        --capacity "$DB_CAPACITY" \
        --auto-pause-delay "$DB_AUTO_PAUSE_DELAY" \
        --min-capacity "$DB_MIN_CAPACITY" \
        --backup-storage-redundancy "$DB_BACKUP_STORAGE" \
        --zone-redundant false \
        --tags "app=$APP_NAME" "cost-center=poc" "environment=development"
    
    echo -e "${GREEN}✓ Database created: ${DB_NAME}${NC}"
    echo -e "${GREEN}  Edition: ${DB_EDITION} (${DB_COMPUTE_MODEL})${NC}"
    echo -e "${GREEN}  Capacity: ${DB_MIN_CAPACITY}-${DB_CAPACITY} vCores${NC}"
    echo -e "${GREEN}  Auto-pause: ${DB_AUTO_PAUSE_DELAY} minutes${NC}"
else
    echo -e "${GREEN}✓ Database already exists: ${DB_NAME}${NC}"
fi
echo ""

# Get current IP address
echo -e "${YELLOW}🌐 Getting current IP address...${NC}"
CURRENT_IP=$(curl -s https://api.ipify.org)
echo -e "${GREEN}✓ Your IP: ${CURRENT_IP}${NC}"
echo ""

# Add firewall rule for current IP
FIREWALL_RULE_NAME="AllowMyIP-${CURRENT_IP//./-}"
echo -e "${YELLOW}🔥 Configuring firewall rules...${NC}"

# Check if rule exists
RULE_EXISTS=$(az sql server firewall-rule list --resource-group "$RESOURCE_GROUP" --server "$SQL_SERVER_NAME" --query "[?name=='$FIREWALL_RULE_NAME'].name" -o tsv)

if [ -z "$RULE_EXISTS" ]; then
    az sql server firewall-rule create \
        --resource-group "$RESOURCE_GROUP" \
        --server "$SQL_SERVER_NAME" \
        --name "$FIREWALL_RULE_NAME" \
        --start-ip-address "$CURRENT_IP" \
        --end-ip-address "$CURRENT_IP"
    
    echo -e "${GREEN}✓ Firewall rule created for your IP: ${CURRENT_IP}${NC}"
else
    echo -e "${GREEN}✓ Firewall rule already exists for IP: ${CURRENT_IP}${NC}"
fi

# Add Azure services firewall rule
AZURE_RULE_NAME="AllowAzureServices"
AZURE_RULE_EXISTS=$(az sql server firewall-rule list --resource-group "$RESOURCE_GROUP" --server "$SQL_SERVER_NAME" --query "[?name=='$AZURE_RULE_NAME'].name" -o tsv)

if [ -z "$AZURE_RULE_EXISTS" ]; then
    az sql server firewall-rule create \
        --resource-group "$RESOURCE_GROUP" \
        --server "$SQL_SERVER_NAME" \
        --name "$AZURE_RULE_NAME" \
        --start-ip-address 0.0.0.0 \
        --end-ip-address 0.0.0.0
    
    echo -e "${GREEN}✓ Azure services firewall rule created${NC}"
else
    echo -e "${GREEN}✓ Azure services firewall rule already exists${NC}"
fi
echo ""

# Get connection string
echo -e "${YELLOW}🔗 Generating connection string...${NC}"
CONNECTION_STRING="Server=tcp:${SQL_SERVER_NAME}.database.windows.net,1433;Database=${DB_NAME};User ID=${SQL_ADMIN_USER};Password=YOUR_PASSWORD_HERE;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Create configuration file
CONFIG_FILE="./azure-config.json"
echo -e "${YELLOW}📝 Creating configuration file...${NC}"

cat > "$CONFIG_FILE" <<EOF
{
  "appName": "$APP_NAME",
  "resourceGroup": "$RESOURCE_GROUP",
  "location": "$LOCATION",
  "sqlServer": {
    "name": "$SQL_SERVER_NAME",
    "fullyQualifiedName": "${SQL_SERVER_NAME}.database.windows.net",
    "adminUser": "$SQL_ADMIN_USER"
  },
  "database": {
    "name": "$DB_NAME",
    "edition": "$DB_EDITION",
    "computeModel": "$DB_COMPUTE_MODEL",
    "capacity": {
      "min": $DB_MIN_CAPACITY,
      "max": $DB_CAPACITY
    },
    "autoPauseDelay": $DB_AUTO_PAUSE_DELAY
  },
  "connectionStrings": {
    "ado.net": "$CONNECTION_STRING",
    "note": "Replace YOUR_PASSWORD_HERE with actual password"
  },
  "estimatedCost": {
    "database": "\$0-5/month",
    "note": "Serverless with auto-pause, minimal activity"
  }
}
EOF

echo -e "${GREEN}✓ Configuration saved to: ${CONFIG_FILE}${NC}"
echo ""

# Create .env file for local development
ENV_FILE="./.env.local"
echo -e "${YELLOW}📝 Creating .env file for local development...${NC}"

cat > "$ENV_FILE" <<EOF
# TODO App - Local Development Configuration
# Generated: $(date)

# Azure SQL Database
DB_SERVER=${SQL_SERVER_NAME}.database.windows.net
DB_NAME=${DB_NAME}
DB_USER=${SQL_ADMIN_USER}
DB_PASSWORD=YOUR_PASSWORD_HERE

# Connection String (replace YOUR_PASSWORD_HERE)
CONNECTION_STRING=${CONNECTION_STRING}

# API Configuration
API_PORT=7001
API_BASE_URL=https://localhost:7001

# Frontend Configuration
WEB_PORT=5000
EOF

echo -e "${GREEN}✓ Environment file created: ${ENV_FILE}${NC}"
echo -e "${YELLOW}⚠️  Remember to update YOUR_PASSWORD_HERE in ${ENV_FILE}${NC}"
echo ""

# Create SETUP_NOTES.md for manual documentation
NOTES_FILE="./SETUP_NOTES.md"
echo -e "${YELLOW}📝 Creating setup notes file...${NC}"

cat > "$NOTES_FILE" <<EOF
# TODO App - Setup Notes

**Created**: $(date)
**POC Name**: $APP_NAME

## Azure Resources

### Database
- **Server**: ${SQL_SERVER_NAME}.database.windows.net
- **Database**: ${DB_NAME}
- **Resource Group**: ${RESOURCE_GROUP}
- **Admin User**: ${SQL_ADMIN_USER}

### Connection String
\`\`\`
${CONNECTION_STRING}
\`\`\`
**IMPORTANT**: Replace YOUR_PASSWORD_HERE with actual password!

## Manual Notes

_Add your notes here during development..._

### Deployment Notes
- Date deployed:
- Issues encountered:
- Configuration changes:

### Testing Notes
- Tests run:
- Results:

## Cleanup Commands

\`\`\`bash
# Delete database only
az sql db delete --name ${DB_NAME} --server ${SQL_SERVER_NAME} --resource-group ${RESOURCE_GROUP} --yes

# Delete entire resource group (if dedicated)
az group delete --name ${APP_NAME} --yes --no-wait
\`\`\`
EOF

echo -e "${GREEN}✓ Setup notes created: ${NOTES_FILE}${NC}"
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Resources Created/Verified:${NC}"
echo -e "  SQL Server: ${SQL_SERVER_NAME}.database.windows.net"
echo -e "  Database: ${DB_NAME}"
echo -e "  Resource Group: ${RESOURCE_GROUP}"
echo -e "  Location: ${LOCATION}"
echo ""
echo -e "${GREEN}Configuration Files:${NC}"
echo -e "  ${CONFIG_FILE} - Azure resource details"
echo -e "  ${ENV_FILE} - Local development environment"
echo -e "  ${NOTES_FILE} - Manual documentation"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Update password in ${ENV_FILE}"
echo -e "  2. Run setup-static-web-app.sh"
echo -e "  3. Create Aspire solution"
echo -e "  4. Run EF Core migrations:"
echo -e "     ${BLUE}dotnet ef database update --connection \"\$CONNECTION_STRING\"${NC}"
echo ""
echo -e "${YELLOW}Cleanup (when done with POC):${NC}"
echo -e "  ${RED}az sql db delete --name ${DB_NAME} --server ${SQL_SERVER_NAME} --resource-group ${RESOURCE_GROUP} --yes${NC}"
echo ""
echo -e "${GREEN}✅ All done!${NC}"

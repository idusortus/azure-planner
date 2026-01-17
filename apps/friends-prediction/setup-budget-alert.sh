#!/bin/bash
# POC Application - Azure Budget Alert Setup Script
# This script creates budget alerts for cost monitoring

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
BUDGET_NAME="${APP_NAME}-budget"
BUDGET_AMOUNT=5  # $5/month
ALERT_EMAIL="${ALERT_EMAIL:-}"  # Will prompt if not set

# Alert thresholds (percentages)
THRESHOLD_80=80
THRESHOLD_100=100
THRESHOLD_120=120

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}${APP_NAME} - Budget Alert Setup${NC}"
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

# Check if resource group exists
echo -e "${YELLOW}🔍 Checking resource group...${NC}"
RG_EXISTS=$(az group exists --name "$RESOURCE_GROUP")

if [ "$RG_EXISTS" == "false" ]; then
    echo -e "${RED}❌ Resource group '${RESOURCE_GROUP}' does not exist${NC}"
    echo -e "${YELLOW}Run setup-static-web-app.sh first to create the resource group${NC}"
    exit 1
fi

RESOURCE_GROUP_ID=$(az group show --name "$RESOURCE_GROUP" --query "id" -o tsv)
echo -e "${GREEN}✓ Resource group exists: ${RESOURCE_GROUP}${NC}"
echo ""

# Get email for notifications
if [ -z "$ALERT_EMAIL" ]; then
    echo -e "${YELLOW}Enter email address for budget alerts:${NC}"
    echo -e "  (Press Enter to use: ${ACCOUNT_NAME})"
    read -r ALERT_EMAIL
    
    if [ -z "$ALERT_EMAIL" ]; then
        ALERT_EMAIL="$ACCOUNT_NAME"
    fi
fi

echo -e "${GREEN}✓ Alert email: ${ALERT_EMAIL}${NC}"
echo ""

# Calculate budget period (current month)
CURRENT_YEAR=$(date +%Y)
CURRENT_MONTH=$(date +%m)
START_DATE="${CURRENT_YEAR}-${CURRENT_MONTH}-01"

echo -e "${YELLOW}💰 Budget Configuration:${NC}"
echo -e "  Amount: \$${BUDGET_AMOUNT}/month"
echo -e "  Start Date: ${START_DATE}"
echo -e "  Alerts at: ${THRESHOLD_80}%, ${THRESHOLD_100}%, ${THRESHOLD_120}%"
echo ""

# Check if budget already exists
echo -e "${YELLOW}🔍 Checking if budget exists...${NC}"
BUDGET_EXISTS=$(az consumption budget list --query "[?name=='$BUDGET_NAME'].name" -o tsv 2>/dev/null || echo "")

if [ -n "$BUDGET_EXISTS" ]; then
    echo -e "${GREEN}✓ Budget already exists: ${BUDGET_NAME}${NC}"
    echo -e "${YELLOW}Updating existing budget...${NC}"
    
    az consumption budget delete --budget-name "$BUDGET_NAME" 2>/dev/null || true
fi

# Create budget with alerts
echo -e "${YELLOW}Creating budget: ${BUDGET_NAME}${NC}"

# Note: Resource group scoped budgets require specific format
az consumption budget create \
    --budget-name "$BUDGET_NAME" \
    --amount "$BUDGET_AMOUNT" \
    --category "Cost" \
    --time-grain "Monthly" \
    --start-date "$START_DATE" \
    --end-date "2030-12-31" \
    --resource-group "$RESOURCE_GROUP"

echo -e "${GREEN}✓ Budget created: ${BUDGET_NAME}${NC}"
echo ""

# Note: Alert rules are created separately using Action Groups
# For simplicity, we'll provide the Azure Portal link and CLI commands

echo -e "${YELLOW}📧 Alert Configuration${NC}"
echo ""
echo -e "${YELLOW}To complete alert setup, create alert notifications in Azure Portal:${NC}"
echo -e "${BLUE}1. Go to: https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/budgets${NC}"
echo -e "${BLUE}2. Select budget: ${BUDGET_NAME}${NC}"
echo -e "${BLUE}3. Add alert conditions:${NC}"
echo -e "   - Alert at ${THRESHOLD_80}% of \$${BUDGET_AMOUNT} (\$$(echo "scale=2; $BUDGET_AMOUNT * $THRESHOLD_80 / 100" | bc))"
echo -e "   - Alert at ${THRESHOLD_100}% of \$${BUDGET_AMOUNT} (\$$(echo "scale=2; $BUDGET_AMOUNT * $THRESHOLD_100 / 100" | bc))"
echo -e "   - Alert at ${THRESHOLD_120}% of \$${BUDGET_AMOUNT} (\$$(echo "scale=2; $BUDGET_AMOUNT * $THRESHOLD_120 / 100" | bc))"
echo -e "${BLUE}4. Add notification email: ${ALERT_EMAIL}${NC}"
echo ""

# Alternative: Create cost alert via monitor
echo -e "${YELLOW}Alternative: Create cost alert using Azure Monitor${NC}"
echo -e "Run these commands to create action group and alert rule:"
echo ""
echo -e "${BLUE}# Create action group for email notifications${NC}"
echo "az monitor action-group create \\"
echo "  --resource-group ${RESOURCE_GROUP} \\"
echo "  --name ${APP_NAME}-alerts \\"
echo "  --short-name ${APP_NAME:0:12} \\"
echo "  --action email admin-email ${ALERT_EMAIL}"
echo ""

# Create configuration file
CONFIG_FILE="./azure-budget-config.json"
echo -e "${YELLOW}📝 Creating configuration file...${NC}"

cat > "$CONFIG_FILE" <<EOF
{
  "appName": "$APP_NAME",
  "resourceGroup": "$RESOURCE_GROUP",
  "budget": {
    "name": "$BUDGET_NAME",
    "amount": $BUDGET_AMOUNT,
    "currency": "USD",
    "timeGrain": "Monthly",
    "startDate": "$START_DATE"
  },
  "alerts": {
    "thresholds": [$THRESHOLD_80, $THRESHOLD_100, $THRESHOLD_120],
    "email": "$ALERT_EMAIL"
  },
  "portalLink": "https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/budgets"
}
EOF

echo -e "${GREEN}✓ Configuration saved to: ${CONFIG_FILE}${NC}"
echo ""

# Update .env file if it exists
ENV_FILE="./.env.local"
if [ -f "$ENV_FILE" ]; then
    # Check if budget variables already exist
    if ! grep -q "BUDGET_NAME" "$ENV_FILE"; then
        cat >> "$ENV_FILE" <<EOF

# Budget Alert Configuration
BUDGET_NAME=${BUDGET_NAME}
BUDGET_AMOUNT=${BUDGET_AMOUNT}
ALERT_EMAIL=${ALERT_EMAIL}
EOF
        echo -e "${GREEN}✓ Budget variables added to .env file${NC}"
    fi
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Budget Created:${NC}"
echo -e "  Name: ${BUDGET_NAME}"
echo -e "  Amount: \$${BUDGET_AMOUNT}/month"
echo -e "  Resource Group: ${RESOURCE_GROUP}"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo -e "  Budget is created but email alerts require manual setup in Azure Portal."
echo -e "  Visit: https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/budgets"
echo ""
echo -e "${YELLOW}Check current spending:${NC}"
echo -e "  ${BLUE}az consumption usage list --start-date \$(date -d 'month ago' +%Y-%m-%d) --end-date \$(date +%Y-%m-%d) --query \"[].{Cost:pretaxCost}\" -o table${NC}"
echo ""
echo -e "${YELLOW}View budget status:${NC}"
echo -e "  ${BLUE}az consumption budget show --budget-name ${BUDGET_NAME}${NC}"
echo ""
echo -e "${GREEN}✅ All done!${NC}"

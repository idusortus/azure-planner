#!/bin/bash
# LeaveACommentApp - Copy configuration from apps/leave-a-comment-app/
# Run this before starting the application locally

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../../apps/leave-a-comment-app"

echo "📋 Copying configuration from apps/leave-a-comment-app/..."

# Check if config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo "❌ Configuration directory not found: $CONFIG_DIR"
    echo "   Run setup-database.sh and setup-static-web-app.sh first!"
    exit 1
fi

# Check for .env.local
if [ ! -f "$CONFIG_DIR/.env.local" ]; then
    echo "❌ .env.local not found in $CONFIG_DIR"
    exit 1
fi

# Read specific variables from .env.local (safer than source)
DB_SERVER=$(grep "^DB_SERVER=" "$CONFIG_DIR/.env.local" | cut -d'=' -f2)
DB_NAME=$(grep "^DB_NAME=" "$CONFIG_DIR/.env.local" | cut -d'=' -f2)
DB_USER=$(grep "^DB_USER=" "$CONFIG_DIR/.env.local" | cut -d'=' -f2)
DB_PASSWORD=$(grep "^DB_PASSWORD=" "$CONFIG_DIR/.env.local" | cut -d'=' -f2)

# Build connection string
CONNECTION_STRING="Server=${DB_SERVER};Database=${DB_NAME};User Id=${DB_USER};Password=${DB_PASSWORD};TrustServerCertificate=True;"

echo "✓ Connection string loaded"
echo "  Server: $DB_SERVER"
echo "  Database: $DB_NAME"

# Update appsettings.json for API
API_SETTINGS="$SCRIPT_DIR/src/LeaveACommentApp.Api/appsettings.json"
if [ -f "$API_SETTINGS" ]; then
    # Use jq if available, otherwise use sed
    if command -v jq &> /dev/null; then
        jq --arg cs "$CONNECTION_STRING" '.ConnectionStrings.CommentDb = $cs' "$API_SETTINGS" > "$API_SETTINGS.tmp" && mv "$API_SETTINGS.tmp" "$API_SETTINGS"
    else
        # Fallback to sed for simple replacement
        sed -i "s|\"CommentDb\": \".*\"|\"CommentDb\": \"$CONNECTION_STRING\"|" "$API_SETTINGS"
    fi
    echo "✓ Updated $API_SETTINGS"
fi

# Also create/update appsettings.Development.json
DEV_SETTINGS="$SCRIPT_DIR/src/LeaveACommentApp.Api/appsettings.Development.json"
cat > "$DEV_SETTINGS" << EOF
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore": "Information"
    }
  },
  "ConnectionStrings": {
    "CommentDb": "$CONNECTION_STRING"
  }
}
EOF
echo "✓ Created $DEV_SETTINGS"

echo ""
echo "✅ Configuration copied successfully!"
echo ""
echo "Next steps:"
echo "  1. Run EF migrations:"
echo "     cd src/LeaveACommentApp.Api"
echo "     dotnet ef migrations add InitialCreate"
echo "     dotnet ef database update"
echo ""
echo "  2. Start the application:"
echo "     dotnet run --project LeaveACommentApp.AppHost"

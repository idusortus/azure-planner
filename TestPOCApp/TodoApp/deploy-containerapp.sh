#!/bin/bash
set -e

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name wiscodevacr --resource-group Shared --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name wiscodevacr --resource-group Shared --query "passwords[0].value" -o tsv)

# Connection string with password
CONN_STR='Server=dev-wiscodev.database.windows.net;Database=todo-app-db;User Id=BryceAndConrad;Password=Tolerance0715#!;TrustServerCertificate=True;'

# Update container app
az containerapp update \
  --name todoapp-api \
  --resource-group todo-app \
  --set-env-vars "ConnectionStrings__TodoDb=$CONN_STR" \
  --registry-server wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io \
  --registry-username "$ACR_USERNAME" \
  --registry-password "$ACR_PASSWORD"

echo "Container app updated successfully"

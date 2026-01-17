# Deploy TODO App to Azure Container Apps
# This script deploys the containerized API to Azure

Write-Host "=== TODO App Azure Deployment ===" -ForegroundColor Green

# Variables
$ResourceGroup = "todo-app"
$AppName = "todoapp-api"
$Environment = "todoapp-env"
$RegistryName = "wiscodevacr"
$RegistryRG = "Shared"
$ImageName = "wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/todoapp-api:latest"
$ConnectionString = "Server=dev-wiscodev.database.windows.net;Database=todo-app-db;User Id=BryceAndConrad;Password=Tolerance0715#!;TrustServerCertificate=True;"

Write-Host "`n1. Getting ACR Credentials..." -ForegroundColor Yellow
$ACRUsername = az acr credential show --name $RegistryName --resource-group $RegistryRG --query username -o tsv
$ACRPassword = az acr credential show --name $RegistryName --resource-group $RegistryRG --query "passwords[0].value" -o tsv

Write-Host "`n2. Deleting existing container app (if exists)..." -ForegroundColor Yellow
az containerapp delete --name $AppName --resource-group $ResourceGroup --yes 2>$null

Write-Host "`n3. Creating new container app..." -ForegroundColor Yellow
az containerapp create `
  --name $AppName `
  --resource-group $ResourceGroup `
  --environment $Environment `
  --image $ImageName `
  --target-port 8080 `
  --ingress external `
  --registry-server wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io `
  --registry-username $ACRUsername `
  --registry-password $ACRPassword `
  --min-replicas 0 `
  --max-replicas 1 `
  --env-vars "ConnectionStrings__TodoDb=$ConnectionString"

Write-Host "`n4. Getting API URL..." -ForegroundColor Yellow
$ApiUrl = az containerapp show --name $AppName --resource-group $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
Write-Host "API URL: https://$ApiUrl" -ForegroundColor Cyan
Write-Host "Test health endpoint: https://$ApiUrl/health" -ForegroundColor Cyan
Write-Host "Test API endpoint: https://$ApiUrl/api/todos" -ForegroundColor Cyan

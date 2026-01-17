# Deploy Frontend to Azure Static Web Apps
# Run this from PowerShell

Write-Host "=== Deploying TODO App Frontend ===" -ForegroundColor Green

$DeploymentToken = "1fed3b09ded045dadc8187eea8c31c7ef67f5a57e63b07cb607a49ca88416c0f06-f15f5094-5e0e-45bd-804f-1ddeec9122a00102008065eace10"
$FrontendPath = "C:\dev\side-projects\azure-planner\TestPOCApp\TodoApp\src\TodoApp.Web\wwwroot"

Write-Host "`nDeploying from: $FrontendPath" -ForegroundColor Yellow

# Change to the frontend directory
Set-Location $FrontendPath

# Deploy using SWA CLI
Write-Host "`nStarting deployment..." -ForegroundColor Yellow
swa deploy . --deployment-token $DeploymentToken --env production

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
Write-Host "Frontend URL: https://happy-desert-065eace10.6.azurestaticapps.net" -ForegroundColor Cyan
Write-Host "API URL: https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io" -ForegroundColor Cyan

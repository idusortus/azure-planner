targetScope = 'subscription'

// ============================================================================
// AZURE POC PLATFORM - Main Infrastructure Template
// ============================================================================
// This template provisions shared infrastructure for POC applications:
// - Resource Group
// - SQL Server + Sandbox Database (with schema isolation)
// - Container Registry
// - Container Apps Environment
// - Static Web App (per POC)
// - Container App (per POC API)
// ============================================================================

// ----------------------------------------------------------------------------
// Parameters
// ----------------------------------------------------------------------------

@description('Environment name (used for resource naming)')
@allowed(['dev', 'staging', 'prod'])
param environmentName string = 'dev'

@description('Primary Azure region for resources')
param location string = 'centralus'

@description('Name prefix for all resources (e.g., "wiscodev")')
@minLength(3)
@maxLength(15)
param resourcePrefix string

@description('POC name for this deployment (e.g., "todo-app", "leave-a-comment-app")')
@minLength(3)
@maxLength(30)
param pocName string

@description('SQL Server administrator username')
@secure()
param sqlAdminUsername string

@description('SQL Server administrator password')
@secure()
param sqlAdminPassword string

@description('Tags to apply to all resources')
param tags object = {
  project: 'azure-planner'
  environment: environmentName
  'cost-center': 'poc'
  'managed-by': 'azd'
}

// ----------------------------------------------------------------------------
// Variables
// ----------------------------------------------------------------------------

var resourceGroupName = 'Shared'
var pocResourceGroupName = pocName
var sqlServerName = '${environmentName}-${resourcePrefix}'
var containerRegistryName = '${resourcePrefix}acr'
var containerAppsEnvName = '${pocName}-env'

// ----------------------------------------------------------------------------
// Resource Groups
// ----------------------------------------------------------------------------

// Shared resource group (SQL Server, ACR)
resource sharedResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// POC-specific resource group
resource pocResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: pocResourceGroupName
  location: location
  tags: union(tags, {
    'poc-name': pocName
  })
}

// ----------------------------------------------------------------------------
// Shared Infrastructure Modules
// ----------------------------------------------------------------------------

// SQL Server + Sandbox Database
module sqlServer 'modules/sql-server.bicep' = {
  name: 'sql-server-${uniqueString(sharedResourceGroup.id)}'
  scope: sharedResourceGroup
  params: {
    serverName: sqlServerName
    location: location
    administratorLogin: sqlAdminUsername
    administratorPassword: sqlAdminPassword
    databaseName: 'sandbox'
    tags: tags
  }
}

// Container Registry (shared across all POCs)
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'acr-${uniqueString(sharedResourceGroup.id)}'
  scope: sharedResourceGroup
  params: {
    registryName: containerRegistryName
    location: location
    tags: tags
  }
}

// ----------------------------------------------------------------------------
// POC-Specific Infrastructure Modules  
// ----------------------------------------------------------------------------

// Container Apps Environment
module containerAppsEnv 'modules/container-apps-env.bicep' = {
  name: 'cae-${uniqueString(pocResourceGroup.id)}'
  scope: pocResourceGroup
  params: {
    environmentName: containerAppsEnvName
    location: location
    tags: tags
  }
}

// Static Web App for frontend
module staticWebApp 'modules/static-web-app.bicep' = {
  name: 'swa-${uniqueString(pocResourceGroup.id)}'
  scope: pocResourceGroup
  params: {
    appName: '${pocName}-web'
    location: location
    tags: tags
  }
}

// Container App for API (optional - can be deployed separately)
module containerApp 'modules/container-app.bicep' = {
  name: 'ca-${uniqueString(pocResourceGroup.id)}'
  scope: pocResourceGroup
  params: {
    appName: '${pocName}-api'
    location: location
    environmentId: containerAppsEnv.outputs.environmentId
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    containerRegistryUsername: containerRegistry.outputs.adminUsername
    containerRegistryPassword: containerRegistry.outputs.adminPassword
    imageName: '${pocName}-api'
    imageTag: 'latest'
    sqlConnectionString: sqlServer.outputs.connectionString
    tags: tags
  }
}

// ----------------------------------------------------------------------------
// Outputs
// ----------------------------------------------------------------------------

@description('SQL Server FQDN')
output AZURE_SQL_SERVER_FQDN string = sqlServer.outputs.serverFqdn

@description('SQL Database name')
output AZURE_SQL_DATABASE_NAME string = sqlServer.outputs.databaseName

@description('Container Registry login server')
output AZURE_CONTAINER_REGISTRY_LOGIN_SERVER string = containerRegistry.outputs.loginServer

@description('Container Registry name')
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.registryName

@description('Container Apps Environment name')
output AZURE_CONTAINER_APPS_ENVIRONMENT_NAME string = containerAppsEnv.outputs.environmentName

@description('Container Apps Environment ID')
output AZURE_CONTAINER_APPS_ENVIRONMENT_ID string = containerAppsEnv.outputs.environmentId

@description('Static Web App URL')
output AZURE_STATIC_WEB_APP_URL string = staticWebApp.outputs.defaultHostname

@description('Container App API URL')
output AZURE_CONTAINER_APP_API_URL string = containerApp.outputs.fqdn

@description('Shared Resource Group name')
output AZURE_SHARED_RESOURCE_GROUP string = sharedResourceGroup.name

@description('POC Resource Group name')
output AZURE_POC_RESOURCE_GROUP string = pocResourceGroup.name

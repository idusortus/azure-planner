targetScope = 'subscription'

// ============================================================================
// POC-ONLY DEPLOYMENT TEMPLATE
// ============================================================================
// Use this template when shared infrastructure already exists.
// This creates only POC-specific resources:
// - POC Resource Group
// - Static Web App
// - Container App (using existing environment)
// ============================================================================

// ----------------------------------------------------------------------------
// Parameters
// ----------------------------------------------------------------------------

@description('POC name for this deployment')
@minLength(3)
@maxLength(30)
param pocName string

@description('Azure region')
param location string = 'centralus'

@description('Existing shared resource group name')
param sharedResourceGroupName string = 'Shared'

@description('Existing Container Apps Environment name')
param existingEnvironmentName string = 'todoapp-env'

@description('Resource group containing the existing environment')
param existingEnvironmentResourceGroup string = 'todo-app'

@description('Existing Container Registry login server')
param existingAcrLoginServer string

@description('Container Registry username')
param acrUsername string

@description('Container Registry password')
@secure()
param acrPassword string

@description('SQL connection string for the POC')
@secure()
param sqlConnectionString string

@description('Schema name for this POC in the sandbox database')
param schemaName string

@description('Connection string environment variable name')
param connectionStringEnvVarName string = 'ConnectionStrings__DefaultConnection'

@description('Resource tags')
param tags object = {}

// ----------------------------------------------------------------------------
// Variables
// ----------------------------------------------------------------------------

var pocResourceGroupName = pocName

// ----------------------------------------------------------------------------
// POC Resource Group
// ----------------------------------------------------------------------------

resource pocResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: pocResourceGroupName
  location: location
  tags: union(tags, {
    'poc-name': pocName
    'db-schema': schemaName
  })
}

// ----------------------------------------------------------------------------
// Reference Existing Container Apps Environment
// ----------------------------------------------------------------------------

resource existingEnvResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: existingEnvironmentResourceGroup
}

module containerAppsEnvRef 'modules/container-apps-env-existing.bicep' = {
  name: 'cae-ref-${uniqueString(pocResourceGroup.id)}'
  scope: existingEnvResourceGroup
  params: {
    environmentName: existingEnvironmentName
  }
}

// ----------------------------------------------------------------------------
// Static Web App
// ----------------------------------------------------------------------------

module staticWebApp 'modules/static-web-app.bicep' = {
  name: 'swa-${uniqueString(pocResourceGroup.id)}'
  scope: pocResourceGroup
  params: {
    appName: '${pocName}-web'
    location: location
    tags: tags
  }
}

// ----------------------------------------------------------------------------
// Container App
// ----------------------------------------------------------------------------

module containerApp 'modules/container-app.bicep' = {
  name: 'ca-${uniqueString(pocResourceGroup.id)}'
  scope: pocResourceGroup
  params: {
    appName: '${pocName}-api'
    location: location
    environmentId: containerAppsEnvRef.outputs.environmentId
    containerRegistryLoginServer: existingAcrLoginServer
    containerRegistryUsername: acrUsername
    containerRegistryPassword: acrPassword
    imageName: '${pocName}-api'
    imageTag: 'latest'
    sqlConnectionString: sqlConnectionString
    connectionStringEnvVarName: connectionStringEnvVarName
    tags: tags
  }
}

// ----------------------------------------------------------------------------
// Outputs
// ----------------------------------------------------------------------------

@description('POC Resource Group name')
output pocResourceGroupName string = pocResourceGroup.name

@description('Static Web App URL')
output staticWebAppUrl string = staticWebApp.outputs.defaultHostname

@description('Container App API URL')
output containerAppApiUrl string = containerApp.outputs.fqdn

@description('Schema name in sandbox database')
output schemaName string = schemaName

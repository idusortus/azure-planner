// ============================================================================
// Static Web App Module
// ============================================================================
// Creates an Azure Static Web App (Free tier) for frontend hosting.
// Free tier includes: Global CDN, SSL, custom domains (2 max).
// ============================================================================

@description('Static Web App name')
param appName string

@description('Azure region')
param location string

@description('SKU tier')
@allowed(['Free', 'Standard'])
param sku string = 'Free'

@description('Resource tags')
param tags object = {}

// ----------------------------------------------------------------------------
// Static Web App
// ----------------------------------------------------------------------------

resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' = {
  name: appName
  location: location
  tags: union(tags, {
    purpose: 'poc-frontend'
  })
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
    buildProperties: {
      skipGithubActionWorkflowGeneration: true  // We manage workflows ourselves
    }
  }
}

// ----------------------------------------------------------------------------
// Outputs
// ----------------------------------------------------------------------------

@description('Static Web App default hostname')
output defaultHostname string = staticWebApp.properties.defaultHostname

@description('Static Web App name')
output appName string = staticWebApp.name

@description('Static Web App resource ID')
output appId string = staticWebApp.id

@description('Deployment token for GitHub Actions')
@secure()
output deploymentToken string = staticWebApp.listSecrets().properties.apiKey

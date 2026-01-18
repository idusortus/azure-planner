// ============================================================================
// Container Apps Environment Module
// ============================================================================
// Creates a Container Apps Environment (Consumption plan).
// Note: Some subscriptions limit to 1 environment per region.
// This environment can be shared across multiple Container Apps.
// ============================================================================

@description('Environment name')
param environmentName string

@description('Azure region')
param location string

@description('Resource tags')
param tags object = {}

// ----------------------------------------------------------------------------
// Log Analytics Workspace (required for Container Apps)
// ----------------------------------------------------------------------------

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${environmentName}-logs'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// ----------------------------------------------------------------------------
// Container Apps Environment
// ----------------------------------------------------------------------------

resource containerAppsEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  tags: union(tags, {
    purpose: 'poc-container-hosting'
  })
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    zoneRedundant: false
  }
}

// ----------------------------------------------------------------------------
// Outputs
// ----------------------------------------------------------------------------

@description('Container Apps Environment ID')
output environmentId string = containerAppsEnv.id

@description('Container Apps Environment name')
output environmentName string = containerAppsEnv.name

@description('Default domain for Container Apps')
output defaultDomain string = containerAppsEnv.properties.defaultDomain

@description('Static IP address')
output staticIp string = containerAppsEnv.properties.staticIp

@description('Log Analytics Workspace ID')
output logAnalyticsWorkspaceId string = logAnalytics.id

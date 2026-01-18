// ============================================================================
// Azure Container Registry Module
// ============================================================================
// Creates a shared Container Registry for all POC Docker images.
// Uses Basic tier (~$5/month) which is sufficient for development.
// ============================================================================

@description('Container Registry name (must be globally unique, alphanumeric only)')
@minLength(5)
@maxLength(50)
param registryName string

@description('Azure region')
param location string

@description('SKU tier')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Basic'

@description('Enable admin user for simple authentication')
param adminUserEnabled bool = true

@description('Resource tags')
param tags object = {}

// ----------------------------------------------------------------------------
// Container Registry
// ----------------------------------------------------------------------------

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  tags: union(tags, {
    purpose: 'shared-poc-registry'
  })
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Enabled'
    policies: {
      retentionPolicy: {
        status: 'disabled'  // Basic tier doesn't support retention policy
      }
    }
  }
}

// ----------------------------------------------------------------------------
// Outputs
// ----------------------------------------------------------------------------

@description('Container Registry login server')
output loginServer string = containerRegistry.properties.loginServer

@description('Container Registry name')
output registryName string = containerRegistry.name

@description('Container Registry resource ID')
output registryId string = containerRegistry.id

@description('Admin username (if admin user enabled)')
output adminUsername string = adminUserEnabled ? containerRegistry.listCredentials().username : ''

@description('Admin password (if admin user enabled)')
@secure()
output adminPassword string = adminUserEnabled ? containerRegistry.listCredentials().passwords[0].value : ''

// ============================================================================
// Existing Container Apps Environment Reference
// ============================================================================
// Use this module to reference an existing Container Apps Environment
// when deploying POC-specific resources.
// ============================================================================

@description('Name of the existing Container Apps Environment')
param environmentName string

// ----------------------------------------------------------------------------
// Reference Existing Environment
// ----------------------------------------------------------------------------

resource existingEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: environmentName
}

// ----------------------------------------------------------------------------
// Outputs
// ----------------------------------------------------------------------------

@description('Container Apps Environment ID')
output environmentId string = existingEnvironment.id

@description('Container Apps Environment name')
output environmentName string = existingEnvironment.name

@description('Default domain for Container Apps')
output defaultDomain string = existingEnvironment.properties.defaultDomain

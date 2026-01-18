using 'main.bicep'

// ============================================================================
// AZURE POC PLATFORM - Parameters File
// ============================================================================
// Edit these parameters to customize your deployment.
// Run: azd up
// ============================================================================

// Environment configuration
param environmentName = 'dev'
param location = 'centralus'
param resourcePrefix = 'wiscodev'

// POC configuration
param pocName = 'my-poc-app'

// SQL credentials (will be prompted if not set)
// Consider using Azure Key Vault or environment variables for production
param sqlAdminUsername = ''
param sqlAdminPassword = ''

// Resource tags
param tags = {
  project: 'azure-planner'
  environment: 'dev'
  'cost-center': 'poc'
  'managed-by': 'azd'
}

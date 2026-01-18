// ============================================================================
// SQL Server + Serverless Database Module
// ============================================================================
// Creates a SQL Server with a serverless database optimized for POC workloads:
// - Auto-pause after 60 minutes of inactivity
// - Scale-to-zero capability
// - Free tier eligible (1 free serverless DB per subscription)
// ============================================================================

@description('SQL Server name')
param serverName string

@description('Azure region')
param location string

@description('Administrator login username')
@secure()
param administratorLogin string

@description('Administrator login password')
@secure()
param administratorPassword string

@description('Database name')
param databaseName string = 'sandbox'

@description('Resource tags')
param tags object = {}

// ----------------------------------------------------------------------------
// SQL Server
// ----------------------------------------------------------------------------

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// Allow Azure services to access the server
resource firewallAllowAzure 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: sqlServer
  name: 'AllowAllAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// ----------------------------------------------------------------------------
// Serverless Database (Free Tier Eligible)
// ----------------------------------------------------------------------------

resource database 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: union(tags, {
    purpose: 'shared-poc-database'
    isolation: 'schema-based'
  })
  sku: {
    name: 'GP_S_Gen5'      // General Purpose Serverless Gen5
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1             // 1 vCore max
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 34359738368  // 32 GB
    autoPauseDelay: 60         // Auto-pause after 60 minutes
    minCapacity: json('0.5')   // Minimum 0.5 vCores (scale to near-zero)
    zoneRedundant: false
    requestedBackupStorageRedundancy: 'Local'
  }
}

// ----------------------------------------------------------------------------
// Outputs
// ----------------------------------------------------------------------------

@description('SQL Server FQDN')
output serverFqdn string = sqlServer.properties.fullyQualifiedDomainName

@description('SQL Server name')
output serverName string = sqlServer.name

@description('Database name')
output databaseName string = database.name

@description('Connection string template (replace {password} with actual password)')
output connectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Database=${database.name};User ID=${administratorLogin};Password={password};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

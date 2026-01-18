// ============================================================================
// Container App Module
// ============================================================================
// Creates a Container App for API hosting with:
// - Scale-to-zero (minReplicas: 0)
// - External ingress (HTTPS)
// - Connection string injection
// ============================================================================

@description('Container App name')
param appName string

@description('Azure region')
param location string

@description('Container Apps Environment ID')
param environmentId string

@description('Container Registry login server')
param containerRegistryLoginServer string

@description('Container Registry username')
param containerRegistryUsername string

@description('Container Registry password')
@secure()
param containerRegistryPassword string

@description('Docker image name (without registry prefix)')
param imageName string

@description('Docker image tag')
param imageTag string = 'latest'

@description('SQL connection string')
@secure()
param sqlConnectionString string

@description('Connection string environment variable name')
param connectionStringEnvVarName string = 'ConnectionStrings__DefaultConnection'

@description('Target port for the container')
param targetPort int = 8080

@description('CPU allocation (cores)')
param cpu string = '0.5'

@description('Memory allocation')
param memory string = '1Gi'

@description('Minimum replicas (0 for scale-to-zero)')
@minValue(0)
@maxValue(10)
param minReplicas int = 0

@description('Maximum replicas')
@minValue(1)
@maxValue(30)
param maxReplicas int = 1

@description('Resource tags')
param tags object = {}

// ----------------------------------------------------------------------------
// Container App
// ----------------------------------------------------------------------------

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  tags: union(tags, {
    purpose: 'poc-api'
  })
  properties: {
    managedEnvironmentId: environmentId
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          server: containerRegistryLoginServer
          username: containerRegistryUsername
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        {
          name: 'acr-password'
          value: containerRegistryPassword
        }
        {
          name: 'sql-connection-string'
          value: sqlConnectionString
        }
      ]
    }
    template: {
      containers: [
        {
          name: appName
          image: '${containerRegistryLoginServer}/${imageName}:${imageTag}'
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: [
            {
              name: connectionStringEnvVarName
              secretRef: 'sql-connection-string'
            }
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Production'
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

// ----------------------------------------------------------------------------
// Outputs
// ----------------------------------------------------------------------------

@description('Container App FQDN')
output fqdn string = containerApp.properties.configuration.ingress.fqdn

@description('Container App name')
output appName string = containerApp.name

@description('Container App resource ID')
output appId string = containerApp.id

@description('Latest revision name')
output latestRevisionName string = containerApp.properties.latestRevisionName

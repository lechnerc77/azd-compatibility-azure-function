param location string
param principalId string = ''
param resourceToken string
param tags object

var abbrs = loadJsonContent('abbreviations.json')
var blobContainerName = 'players'
var blobStorageName = 'blobfunc'
var blobStorageSecretName = 'BLOB-CONNECTION-STRING'

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: '${abbrs.storageStorageAccounts}${resourceToken}'
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource blobstorageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: '${abbrs.storageStorageAccounts}${resourceToken}${blobStorageName}'
  location: location
  tags: tags
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${blobstorageAccount.name}/default/${blobContainerName}'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${abbrs.webServerFarms}${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
  }
  kind: 'functionapp'
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: '${abbrs.webSitesFunctions}api-${resourceToken}'
  location: location
  tags: union(tags, { 'azd-service-name': 'blob-output-binding' })
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'NODE|16'
      alwaysOn: false
      functionAppScaleLimit: 200
      minimumElasticInstanceCount: 0
      ftpsState: 'Disabled'
      use32BitWorkerProcess: false
    }
    clientAffinityEnabled: false
    httpsOnly: true
  }

  identity: {
    type: 'SystemAssigned'
  }

  resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsResources.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING
      AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storage.listKeys().keys[0].value}'
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'node'
      SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
      BLOB_STORAGE_CONNECTION_STRING: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/${blobStorageSecretName})'
      AZURE_KEY_VAULT_ENDPOINT: keyVault.properties.vaultUri
    }
  }

  resource logs 'config' = {
    name: 'logs'
    properties: {
      applicationLogs: {
        fileSystem: {
          level: 'Verbose'
        }
      }
      detailedErrorMessages: {
        enabled: true
      }
      failedRequestsTracing: {
        enabled: true
      }
      httpLogs: {
        fileSystem: {
          enabled: true
          retentionInDays: 1
          retentionInMb: 35
        }
      }
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${abbrs.keyVaultVaults}${resourceToken}'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: concat([
        {
          objectId: functionApp.identity.principalId
          permissions: {
            secrets: [
              'get'
              'list'
            ]
          }
          tenantId: subscription().tenantId
        }
      ], !empty(principalId) ? [
        {
          objectId: principalId
          permissions: {
            secrets: [
              'get'
              'list'
            ]
          }
          tenantId: subscription().tenantId
        }
      ] : [])
  }

  resource blobConnectionString 'secrets@2022-07-01' = {
    name: '${blobStorageSecretName}'
    properties: {
      value: 'DefaultEndpointsProtocol=https;AccountName=${blobstorageAccount.name};AccountKey=${blobstorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
  location: location
  tags: tags
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

module applicationInsightsResources 'applicationinsights.bicep' = {
  name: 'applicationinsights-resources'
  params: {
    resourceToken: resourceToken
    location: location
    tags: tags
    workspaceId: logAnalyticsWorkspace.id
  }
}

output AZURE_BLOB_CONNECTION_STRING_KEY string = 'BLOB_STORAGE_CONNECTION_STRING'
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.properties.vaultUri
output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsightsResources.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING
output FUNCTIONS_URI string = 'https://${functionApp.properties.defaultHostName}'

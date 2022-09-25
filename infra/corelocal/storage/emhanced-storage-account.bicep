param environmentName string
param location string = resourceGroup().location
param blobStorageNamePostfix string = ''

param allowBlobPublicAccess bool = false
param kind string = 'StorageV2'
param minimumTlsVersion string = 'TLS1_2'
param sku object = { name: 'Standard_LRS' }

var abbrs = loadJsonContent('../../abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }
var storageName = blobStorageNamePostfix != '' ? '${abbrs.storageStorageAccounts}${resourceToken}${blobStorageNamePostfix}' : '${abbrs.storageStorageAccounts}${resourceToken}'

resource enhancedStorage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageName
  location: location
  tags: tags
  kind: kind
  sku: sku
  properties: {
    minimumTlsVersion: minimumTlsVersion
    allowBlobPublicAccess: allowBlobPublicAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

output name string = enhancedStorage.name

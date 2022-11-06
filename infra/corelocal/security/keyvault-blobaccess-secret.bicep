param name string
param tags object = {}

param keyVaultName string
param blobStorageName string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource playerStorage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: blobStorageName
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: name
  tags: tags
  parent: keyVault
  properties: {
    contentType: 'string'
    value: 'DefaultEndpointsProtocol=https;AccountName=${playerStorage.name};AccountKey=${playerStorage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
  }
}

param environmentName string
param keyVaultName string = ''
param secretName string = ''
param blobStorageName string = ''

var tags = { 'azd-env-name': environmentName }

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource enhancedStorage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: blobStorageName
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: secretName
  tags: tags
  parent: keyVault
  properties: {
    contentType: 'string'
    value: 'DefaultEndpointsProtocol=https;AccountName=${enhancedStorage.name};AccountKey=${enhancedStorage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
  }
}

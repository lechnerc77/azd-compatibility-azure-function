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

var accessString = 'DefaultEndpointsProtocol=https;AccountName=${playerStorage.name};AccountKey=${playerStorage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'

//attach output storage to keyvault
module outputStorageSecret '../core/security/keyvault-secret.bicep' = {
  name: 'keyVaultSecretForBlob'
  params: {
    name: name
    tags: tags
    keyVaultName: keyVault.name
    secretValue: accessString
  }
}

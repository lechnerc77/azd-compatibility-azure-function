param blobStorageName string = ''
param blobContainerName string = 'dev'

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${blobStorageName}/default/${blobContainerName}'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}

param environmentName string
param location string = resourceGroup().location

var blobStorageNamePostfix = 'blobfunc'
var blobContainerName = 'players'

// Backing storage for Azure functions output binding
module blobStorageAccount '../corelocal/storage/enhanced-storage-account.bicep' = {
  name: 'outputStorageAccount'
  params: {
    blobStorageNamePostfix: blobStorageNamePostfix
    environmentName: environmentName
    location: location
  }
}

// Container in the storage account
module blobStorageContainer '../corelocal/storage/storage-container.bicep' = {
  name: 'storageContainer'
  params: {
    blobStorageName: blobStorageAccount.outputs.name
    blobContainerName: blobContainerName
  }
}


output blobStorageName string = blobStorageAccount.outputs.name

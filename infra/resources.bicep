param environmentName string
param location string = resourceGroup().location
param principalId string = ''

var blobStorageSecretName = 'BLOB-CONNECTION-STRING'

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan-functions.bicep' = {
  name: 'appserviceplan'
  params: {
    environmentName: environmentName
    location: location
  }
}

// Backing storage for Azure Functions
module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  params: {
    environmentName: environmentName
    location: location
  }
}

// Second Storage Account for Output Binding
module outputstorage './app/storage-output.bicep' = {
  name: 'outputstorage'
  params: {
    environmentName: environmentName
    location: location
  }
}

// Store secrets in a keyvault
module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    environmentName: environmentName
    location: location
    principalId: principalId
  }
}

// attach output storage to keyvault
module outputStorageSecret './corelocal/security/keyvault-blobaccess-secret.bicep' = {
  name: 'keyVaultSecretForBlob'
  params: {
    environmentName: environmentName
    blobStorageName: outputstorage.outputs.blobStorageName
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: blobStorageSecretName
  }
}

// The function app
module function './app/function.bicep' = {
  name: 'function'
  params: {
    environmentName: environmentName
    location: location
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    storageAccountName: storage.outputs.name
    keyVaultName: keyVault.outputs.keyVaultName
    appSettings: {
      BLOB_STORAGE_CONNECTION_STRING: '@Microsoft.KeyVault(SecretUri=${keyVault.outputs.keyVaultEndpoint}secrets/${blobStorageSecretName})'
    }
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    environmentName: environmentName
    location: location
  }
}

output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.keyVaultEndpoint
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output FUNCTIONS_URI string = function.outputs.FUNCTION_URI

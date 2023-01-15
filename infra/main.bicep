targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param functionName string = ''
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param appServicePlanName string = ''
param keyVaultName string = ''
param logAnalyticsName string = ''
param resourceGroupName string = ''
param storageAccountName string = ''

@description('Id of the user or app to assign application roles')
param principalId string = ''

// Additonal app sepcific parameters (defaulted) 
param storageContainerName string = 'players'
param blobStorageSecretName string = 'BLOB-CONNECTION-STRING'

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// name of the blob storage secret in key vault
var blobStorageForPlayersName = '${abbrs.storageStorageAccounts}${resourceToken}blobfunc'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'Y1'
      tier: 'Dynamic'
    }
  }
}

// Backing storage for Azure Functions
module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
  }
}

// Second Storage Account for Output Binding
module outputstorage './core/storage/storage-account.bicep' = {
  name: 'outputstorage'
  scope: rg
  params: {
    name: blobStorageForPlayersName
    location: location
    tags: tags
    containers: [
      {
        name: storageContainerName
      }
    ]
  }
}

// Store secrets in a keyvault
module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

// Give the API access to KeyVault
module apiKeyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'api-keyvault-access'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: function.outputs.FUNCTION_IDENTITY_PRINCIPAL_ID
  }
}

// Add Connection String to KeyVault
module blobStorageConnectionSecret 'app/blobStorageConnectionSecret.bicep' = {
  name: 'blobStorageConnectionSecret'
  scope: rg
  params: {
    name: blobStorageSecretName
    tags: tags
    blobStorageName: outputstorage.outputs.name
    keyVaultName: keyVault.outputs.name
  }
}

// The function app
module function './app/function.bicep' = {
  name: 'function'
  scope: rg
  params: {
    name: !empty(functionName) ? functionName : '${abbrs.webSitesFunctions}api-${resourceToken}'
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    storageAccountName: storage.outputs.name
    appSettings: {
      BLOB_STORAGE_CONNECTION_STRING: '@Microsoft.KeyVault(SecretUri=${keyVault.outputs.endpoint}secrets/${blobStorageSecretName})'
    }
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}

output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output FUNCTION_URL string = function.outputs.FUNCTION_URI
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId

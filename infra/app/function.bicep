param location string = resourceGroup().location
param environmentName string

param applicationInsightsName string
param appServicePlanId string
param appSettings object = {}
param serviceName string = 'blob-output-binding'
param storageAccountName string
param keyVaultName string = ''

module function '../core/host/functions-node.bicep' = {
  name: '${serviceName}-functions-node-module'
  params: {
    environmentName: environmentName
    location: location
    appSettings: appSettings
    applicationInsightsName: applicationInsightsName
    appServicePlanId: appServicePlanId
    serviceName: serviceName
    storageAccountName: storageAccountName
    keyVaultName: keyVaultName
  }
}

output FUNCTION_IDENTITY_PRINCIPAL_ID string = function.outputs.identityPrincipalId
output FUNCTION_NAME string = function.outputs.name
output FUNCTION_URI string = function.outputs.uri

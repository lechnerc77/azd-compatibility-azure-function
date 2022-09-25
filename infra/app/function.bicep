param environmentName string
param location string = resourceGroup().location

param applicationInsightsName string
param appServicePlanId string
param appSettings object = {}
param serviceName string = 'api'
param storageAccountName string

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
  }
}

output FUNCTION_IDENTITY_PRINCIPAL_ID string = function.outputs.identityPrincipalId
output FUNCTION_NAME string = function.outputs.name
output FUNCTION_URI string = function.outputs.uri

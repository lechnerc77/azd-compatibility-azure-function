param name string
param location string = resourceGroup().location
param tags object = {}

param allowedOrigins array = []
param applicationInsightsName string = ''
param appServicePlanId string
param appSettings object = {}
param keyVaultName string
param serviceName string = 'blob-output-binding'
param storageAccountName string

module function '../core/host/functions.bicep' = {
  name: '${serviceName}-functions-node-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    allowedOrigins: allowedOrigins
    alwaysOn: false
    appSettings: appSettings
    applicationInsightsName: applicationInsightsName
    appServicePlanId: appServicePlanId
    keyVaultName: keyVaultName
    runtimeName: 'node'
    runtimeVersion: '16'
    storageAccountName: storageAccountName
  }
}

output FUNCTION_IDENTITY_PRINCIPAL_ID string = function.outputs.identityPrincipalId
output FUNCTION_NAME string = function.outputs.name
output FUNCTION_URI string = function.outputs.uri

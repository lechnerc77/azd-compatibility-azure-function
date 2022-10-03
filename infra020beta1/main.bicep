targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var tags = { 'azd-env-name': name }
var abbrs = loadJsonContent('abbreviations.json')

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${name}'
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  name: 'resources'
  scope: rg
  params: {
    location: location
    principalId: principalId
    resourceToken: resourceToken
    tags: tags
  }
}


output AZURE_COSMOS_CONNECTION_STRING_KEY string = resources.outputs.AZURE_BLOB_CONNECTION_STRING_KEY
output AZURE_KEY_VAULT_ENDPOINT string = resources.outputs.AZURE_KEY_VAULT_ENDPOINT
output APPLICATIONINSIGHTS_CONNECTION_STRING string = resources.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING
output FUNCTION_URL string = resources.outputs.FUNCTIONS_URI
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
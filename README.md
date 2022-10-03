# Sample compatibility journey for the Azure Developer CLI - Updates with azd 0.2.0-beta.2

> ⚠ **The steps and the code presented in this branch are described and built in accordance to the new infrastructure setup Azure Developer CLI version [0.2.0-beta.2 (2022-09-21)](https://github.com/Azure/azure-dev/releases/tag/azure-dev-cli_0.2.0-beta.2) and later**

## Introduction

With the update of the Azure Developer CLI to version [0.2.0-beta.2 (2022-09-21)](https://github.com/Azure/azure-dev/releases/tag/azure-dev-cli_0.2.0-beta.2) a change was introduced that affects the structuring of the bicep templates i.e., structuring them via modules (see also pull request [Rearrange Bicep Modules #548](https://github.com/Azure/azure-dev/pull/548)).

> 📝 Remark: The setup presented here is also valid with the CLI version [0.3.0-beta.1](https://github.com/Azure/azure-dev/releases/tag/azure-dev-cli_0.3.0-beta.1).

## What has changed

Up to the version 0.2.0-beta.1 the `infra` folder contained the bicep files in a structured but "flat" manner. It was well defined, but all files have been gathered in one directory:

![azd infra directory structure beta1](./assets/infrafolder-020-beta1.png)

Although this setup is easy to understand and might be a good fit for small projects, it will face some limitations:

- The more complex the setup the bigger the `resources-bicep` file will become. This will decrease the maintainability and the code will be hard to understand. The mitigation would be to split the files. This can again become messy, and governance needs to be put in place to assure a uniform structuring across projects.
- Some copy and paste must happen in between projects, so even after introducing `azd` as best practice for development teams in a company to unify the infrastructure provisioning each team must take care individually to keep central resource definition up to date.

The creators of the `azd` seem to be well aware of this and their solution proposal is available with version 0.2.0-beta.**2** of the Azure Developer CLI. The main change is that the bicep files are refactored into [modules](https://learn.microsoft.com/azure/azure-resource-manager/bicep/modules). The new `infra` folder has the following structure:

![azd infra directory structure beta 2](./assets/infrafolder-020-beta2.png)

While the foundational files like `main.bicep` and `resources.bicep` remain, we see two new folder namely `app` and `core`. Let us take a closer look into them.

### The `core` folder

The `core` folder can be interpreted as the central *reuse* folder comprising a repository of resources that are used in the different sample projects. The structure is based on the semantics of the resources contained in the folders, like `storage`, `database` or `security`:

![azd infra directory structure beta 2 - Core folder](./assets/infrafolder-020-beta2-core.png)

We find the corresponding `*.bicep` files of the resources in each folder. Instead of explicitly coding the different resources in the `resource.bicep` file they are referenced via [modules](https://learn.microsoft.com/azure/azure-resource-manager/bicep/modules). This we way we reduce redundant code and have one source of truth.

### The `app` folder

The resources that define your app are placed in a dedicated folder called `app`. The reuse is established via bicep modules from the `core` folder. This leads to a clean setup compared to the one in prior `azd` versions.

## Refactoring the Azure Functions sample

To get a hands-on impression on these changes I decided to test it for an existing azd-compatible project. The starting point is the azd-compatible Azure Functions project that I described in the blog post [The Azure Developer CLI - Compatibility journey for an Azure Functions Project](https://dev.to/lechnerc77/the-azure-developer-cli-compatibility-journey-for-an-azure-functions-project-3mc1). The focus lies onm restructuring the `infra` folder to get it compliant with the new setup.

### Step 1 - Cleaning up the folders

First, I renamed the existing `infra` folder to `infra020beta1` to have my existing and working setup still available and to cross check in case of issues. We can even use this folder in the project by pointing the `azure.yaml` file to the folder:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/Azure/azure-dev/main/schemas/v1.0/azure.yaml.json

name: azure-functions-blob
metadata:
  template: azure-functions-blob@0.0.1-beta
services:
  blob-output-binding:
    project: src
    language: ts
    host: function 
infra:
  path: infra020beta1   
```

For this blog post we leave the `infra` section out of the `azure.yaml` file, so that `azd` will use the default which is the `infra` folder. Consequently, we create a new folder and call it `infra`. We copy the following files from `infra020beta1` to `infra`:

- `abbreviations.json`
- `main.bicep`
- `main.parameters.bicep`
- `resources.bicep`

In order to have the new `core` folder I created an `azd` project from a template and copied the `core` folder as is into the `infra` folder of my Azure Functions project. The content of the `core` folder is independent of the template you used; it always contains *all* reusable `.bicep` files.

In addition, I created a new folder called `app` which will become the home of my app-specific `.bicep` files. I put two empty files into this folder namely:

- `function.bicep`: this file will contain the modules that need to be called to create the Azure Function
- `storage-output.bicep`: this folder will contain the modules that need to be called in order create the dedicated storage for the output binding of the Azure Function

With that the basic folder structure is in place and we can move on to change the content.

### Step 2 - The `main*.bicep` files

Let us first take a look at the `main.bicep` and the `main.parameters.bicep` files:

- The `main.parameters.bicep` remains unchanged
- The `main.bicep` gets a small change as a consequence to the change of the parameters of the `resources.bicep` file. The `tags` have gone and the `environment` is now part of the parameters. They look like this:

   ```bicep
   module resources 'resources.bicep' = {
   name: 'resources'
   scope: rg
   params: {
     location: location
     principalId: principalId
     environmentName: name
    }
   }  
   ```

### Step 3 - the `resources.bicep` file

This file gets a completely new setup based on the modules provided in the `core` folder. As we already saw the parameters changed:

```bicep
param environmentName string
param location string = resourceGroup().location
param principalId string = ''
```

In addition, we define the secret name for the Blob Storage access here:

```bicep
var blobStorageSecretName = 'BLOB-CONNECTION-STRING'
```

And now ... drum roll ... we can reuse the modules from the `core` folder to create the usual suspects of resources like App Service Plan or monitoring:

```bicep
// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan-functions.bicep' = {
  name: 'appserviceplan'
  params: {
    environmentName: environmentName
    location: location
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
```

You already see the advantage of the new setup: no more "spaghetti code" for declaring the resources. In case of changes on the basic setup, those can be managed in one central place. The downside is that you need to take a dive into the files as they might be stacked (one module calling another one) with some defaulting and merging going on along the way.

I added the basic module-based setup also for the following resources:

- Storage Account for the Azure Function via  `./core/storage/storage-account.bicep`
- Key Vault via `./core/security/keyvault.bicep`.

In accordance with the new setup, I added the application specific setups (Azure Function *per se* and the Azure Storage Account for the output binding) via:

```bicep
// Second Storage Account for Output Binding
module outputstorage './app/storage-output.bicep' = {
  name: 'outputstorage'
  params: {
    environmentName: environmentName
    location: location
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
```

> 📝 Remark - Be aware that we define the `BLOB_STORAGE_CONNECTION_STRING` via a reference to an Azure Key Vault secret. We will create the prerequisites for this in the next sections.

With the very basic setup in place, we now focus on our specifics.

### Step 4 - Our special storage setup

For the output binding we need an additional Azure Storage Account. Taking a closer look at the file `storage-account.bicep` in the `core/storage` folder we see that we have no option to influence the name of the storage account e.g., via a postfix. It is predefined by:

```bicep
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: '${abbrs.storageStorageAccounts}${resourceToken}'
```

In addition, we need to create a container inside of the storage account which is not foreseen in the current content of the `core` modules. To stay in line with the setup I created a new folder called `corelocal` where I centralized my own reusable modules. I also mimicked the sub-folder structure, so I added a folder `storage`. Now I could add my own Storage Account `bicep` file called `enhanced-storage-account.bicep`:

```bicep
param environmentName string
param location string = resourceGroup().location
param blobStorageNamePostfix string = ''

param allowBlobPublicAccess bool = false
param kind string = 'StorageV2'
param minimumTlsVersion string = 'TLS1_2'
param sku object = { name: 'Standard_LRS' }

var abbrs = loadJsonContent('../../abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }
var storageName = blobStorageNamePostfix != '' ? '${abbrs.storageStorageAccounts}${resourceToken}${blobStorageNamePostfix}' : '${abbrs.storageStorageAccounts}${resourceToken}dev'

resource enhancedStorage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageName
  location: location
  tags: tags
  kind: kind
  sku: sku
  properties: {
    minimumTlsVersion: minimumTlsVersion
    allowBlobPublicAccess: allowBlobPublicAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

output name string = enhancedStorage.name
```

Basically, it is a copy & paste from the original one, with some additional logic to add a postfix, that is handed in via a parameter. I created the resource in a way that one could use this template also for the original storage account setup.

In addition, we need a container created in the storage account. For that I created an additional `bicep` file called `storage-container.bicep`:

```bicep
param blobStorageName string = ''
param blobContainerName string = 'dev'

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${blobStorageName}/default/${blobContainerName}'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}
```

I referenced the parent Storage in the `name` parameter of my container using it as part of the relative path. You can also use the `parent` parameter, but then must adjust the `name` parameter accordingly as providing the parent information is only allowed in one place for this resource.

Having this in place we are good to go to create the `infra\app\storage-output.bicep` file using the new building blocks as modules:

```bicep
param environmentName string
param location string = resourceGroup().location

var blobStorageNamePostfix = 'blobfunc'
var blobContainerName = 'players'

// Storage for Azure functions output binding
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
```

That was not too complicated, so let us move on to the storage of the connection string to this Blob Storage in the Azure Key Vault.

### Step 5 - Storing the secret

We want to store the connection string to our Blob Storage in Azure Key Vault and later access it as a reference from the Azure Function app configuration. First things first, let us create the secret. As in the previous section there is no pre-defined `bicep` file available, so let us create one. To do so I created a `security` folder underneath the `corelocal` folder. Here we place the `bicep` file for the secret:

```bicep
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
```

As we need to attach the secret to the storage and construct the value of our secret using information from the storage account, we must integrate the existing resources into this `bicep` file. To do so we use the `existing` keyword as described in the [official documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/existing-resource).

This new module is then referenced from the `resources.bicep` file with the parameters filled via the output of the corresponding module calls:

```bicep
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
```

This was a bit tricky (at least for a `bicep` newbie), but doable and fits into the new infrastructure setup.

Now we need to bring the pieces together in the Azure Function and the Azure Key Vault to get access to the secret.

### Step 6 - Mind the access

What do we need to do to grant the Azure Function app access to the Azure Key Vault? There are two things needed to get things going:

1. Create a system assigned identity for the Azure Functions app
2. Create the access policy in Key Vault for this identity via its principal ID

Can we achieve that with the existing modules from `core`? Yes, we can, but to understand what is going on you must take a dive into the hierarchy for Azure Functions and the Azure Functions app. Let us start from our part, namely the `function.bicep` that we create in the `app` folder:

```bicep
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
```

> 📝 Remark - We implemented the call in the `resources.bicep` in a prior step. Be aware that we provided the parameter `keyVaultName` from there. This is important for wiring things up the right way.

For the access we need to make sure that a system assigned identity is created in our Azure Functions App and that the access policy in Azure Key Vault is set accordingly. What do we have to set where?

We now need to dive into the code of the predefined `bicep` files, to get it:

- From our file the next stop is the `functions-node.bicep`. There is nothing relevant for our investigation, however it is interesting to see the defaulting of some parameters.
- Next stop is the `functions.bicep` file. And here we get our first clue about the managed identity:

   ```bicep
   param managedIdentity bool = !(empty(keyVaultName))

   ...
   module functions 'appservice.bicep' = {
     name: '${serviceName}-functions'
     params: {
       ...
       kind: kind
       linuxFxVersion: linuxFxVersion
       managedIdentity: managedIdentity
       minimumElasticInstanceCount: minimumElasticInstanceCount
       ...
       }
   }
   ```

The creation of a managed identity is based ion the fact if the keyVaultName is provided or not. That is really important to know and understand. So the first prerequisite is fulfilled for our setup. What about the second one namely the Key Vault Access policies? Let's dive deeper a bit deeper:

The next stop is the `appservice.bicep` file that conatins the last missing puzzle pieces. In this file the access policy is created via:

```bicep
module keyVaultAccess '../security/keyvault-access.bicep' = if (!(empty(keyVaultName))) {
  name: '${serviceName}-appservice-keyvault-access'
  params: {
    principalId: appService.identity.principalId
    environmentName: environmentName
    location: location
  }
}
```

This closes the loop and allows the Azure Function app to access the Azure Key Vault via the managed identity. And this is also the end of the infrastructure restructuring journey, as we have everything in place now.  

## Summary and conclusion

The progress and improvements of the Azure Developer CLI are coming fast. One of the major improvements of the 0.2.0-beta2 release was a complete overhaul of the infrastructure provisioning setup. I followed this refactoring in my sample project to get an idea what it means. In general I want to state that this new setup makes perfect sense and pushes the maturity of the Azure Developer CLI one step further and makes it even more appealing for platform and development teams in companies. The modularization of the bicep files with a central reuse "repository" is a good move and will support the maintainability on the long term. However, there is no free lunch and there is a price you have to pay:

- To make use of the reuseable `bicep` files a more decent understanding of the `bicep` concepts is needed. This is something to keep in mind if you have members in your team that are not familiar with `bicep`.
- In general I think reusable bits and pieces are hard to define up front. I think the Azure Developer CLI team did a good job, guided by the sample code. However, do not fall into the trap to expect everything to be in place in the `core` folder. Embrace the structure and fill in the gaps accordingly as I did for some missing parts in my project.
- Take your time and go down the rabbit hole of the chain of `bicep` files to get an understand what happens where like how are the configurations merged, how are default values set etc. You get an idea of what I mean when looking at the section [Step 6 - Mind the access](#step-6---mind-the-access).

I think the provided infrastructure setup should be seen and used as a pattern for the setup in your company not necessarily as a library carved in stone. There are also some open questions like where and how to keep the central repository of the `bicep` files and how to propagate changes. But let us see how things evolve.

*Long story short*: I like the new infrastructure setup and I am looking forward to the upcoming improvements of the Azure Developer CLI. What about you?

## Useful references

Useful references if you want to try things out on your own:

- [azd documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview?tabs=nodejs)
- [azd on GitHub](https://github.com/Azure/azure-dev)
- [bicep documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [bicep playground](https://bicepdemo.z22.web.core.windows.net/)
- [Azure Developer CLI (azd) – September 2022 Release](https://devblogs.microsoft.com/azure-sdk/azure-developer-cli-azd-september-2022-release/) - information and links for Terraform
- [QuickGlance - Azure Developer CLI](https://youtube.com/playlist?list=PLmZLSvJAm8FbFq2XhqaPZgIzl6kewz1HD)
- [The Azure Developer CLI - Compatibility journey for an Azure Functions Project](https://dev.to/lechnerc77/the-azure-developer-cli-compatibility-journey-for-an-azure-functions-project-3mc1)
- [Azure Developer CLI - How does it know that?](https://dev.to/lechnerc77/azure-developer-cli-how-does-it-know-that-1ngl)

# Sample compatibility journey for the Azure Developer CLI - Updates with azd 0.2.0-beta.2

> ⚠ **The steps and the code presented in this branch are described and built in accordance to the new infrastructure setup Azure Developer CLI version [0.2.0-beta.2 (2022-09-21)](https://github.com/Azure/azure-dev/releases/tag/azure-dev-cli_0.2.0-beta.2)**

## Introduction

With the update of the Azure Developer CLI to version [0.2.0-beta.2 (2022-09-21)](https://github.com/Azure/azure-dev/releases/tag/azure-dev-cli_0.2.0-beta.2) a change was introduced that affects the structuring of the bicep templates i.e. structuring them via modules (see also pull request [Rearrange Bicep Modules #548](https://github.com/Azure/azure-dev/pull/548)). 

> Remark: The setup presented here is also valid with the CLI version [0.3.0-beta.1](https://github.com/Azure/azure-dev/releases/tag/azure-dev-cli_0.3.0-beta.1).

## What has changed

Up to the version 0.2.0-beta.1 the `infra` folder contained the bicep files in a structured but "flat" manner. It was well defined, but all files have been gathered in one directory:

![azd infra directory structure beta1](./assets/infrafolder-020-beta1.png)

Although this setup is easy to understand and might be a good fit for small projects, it will face some limitations:

- The more complex the setup the bigger the `resources-bicep` file will become. This will decrease the maintainability and the code will be hard to understand. The mitigation would be to split the files. This can again become messy and governance needs to be put in place to assure a uniform structuring across projects.
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

### Step 1 - cleaning up the folders

First I renamed the existing `infra` folder to `infra020beta1` to have my existing and working setup still available and to cross check in case of issues. We can even use this folder in the project by pointing the `azure.yaml` file to the folder:

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

For this blog post we leave the `infra` section out of the `azure.yaml` file, so that `azd` will use the default which is the `infra` folder. Consequently we create a new folder and call it `infra`. We copy the following files from `infra020beta1` to `infra`:

- `abbreviations.json`
- `main.bicep`
- `main.parameters.bicep`
- `resources.bicep`

In order to have the new `core` folder I created an `azd` project from a template and copied the `core` folder as is into the `infra` folder of my Azure Functions project. The content of the `core` folder is independent of the template you used, it always contains *all* reusable `.bicep` files.

In addition i created a new folder called `app` which will become the home of my app-specific `.bicep` files. I put two empty files into this folder namely:

- `function.bicep`: this file will contain the modules that need to be called to create the Azure Function
- `storage-output.bicep`: this folder will contain the modules that need to be called in order create the dedicated storage for the output binding of the Azure Function

With that the basic folder structure is in place and we can move on to change the content.

### Step 2 - the `main*.bicep` files

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

This files gets a completely new setup based on the modules provided in the `core` folder. As we already saw the parameters changed:

```bicep
param environmentName string
param location string = resourceGroup().location
param principalId string = ''
```

In addition we define the secret name for the Blob Storage access here:

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

You already see the advantage of the new setup: no more spaghetti code for your resources and in case of changes they can be managed in one central place. The downside is that you need to take a dive into the files as they might be stacked (one module calling another one) with some defaulting and merging going on along the way.

### Step 4 - our special storage setup

For the output binding we need an additional Azure Storage Account. Taking a closer look at the file `storage-account.bicep` in the `core/storage` folder we see that we have no option to influence the name of the storage account e.g., via a postfix.

In addition we need to create a container inside of the storage account. 

### Step 5 - storing the secret

To access the storage account we want to store the access data as a secret in Azure Key Vault. By default the provided modules do not foresee this, so we must create a module.

### Step 6 - mind the access

To configure the access to the Key Vault and to the Blob Storage, we must store the reference to the key vault secret in the app settings

For the access we need to make sure that a system assigned identity is created in our Azure Functions App and that the access policy in Azure Key Vault is set accordingly.

> Digging deeper into the hierarchy of the Azure Function i.e.  Appservice app is needed as some "magic" is happening there. 

## My 2 cent

- Decent understanding of bicep is necessary as more features are used
- reuse is hard to define up front, but good structure imho
- You must go down the rabbit hole:
api.bicep -> functions-node.bicep -> functions.biscep -> appservice.bicep -> 

- Only first step, I think the procedure itself should be used as a pattern
- Overhead of files ... or not?

## Useful references

Useful references if you want to try things out on your own:

- [azd documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview?tabs=nodejs)
- [bicep documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [bicep playground](https://bicepdemo.z22.web.core.windows.net/)
- [Azure Developer CLI (azd) – September 2022 Release](https://devblogs.microsoft.com/azure-sdk/azure-developer-cli-azd-september-2022-release/) - information and links for Terraform

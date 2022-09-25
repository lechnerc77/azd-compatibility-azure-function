# Sample compatibility journey for the Azure Developer CLI

> ⚠ **The steps and the code presented in this branch are described and built in accordiance to the Azure Developer CLI version [0.2.0-beta.1 (2022-09-14)](https://github.com/Azure/azure-dev/releases/tag/azure-dev-cli_0.2.0-beta.1)**

## Introduction

A few weeks ago the Azure Developer CLI (azd) was released in public beta (you find the announcement [here](https://devblogs.microsoft.com/azure-sdk/introducing-the-azure-developer-cli-a-faster-way-to-build-apps-for-the-cloud/)). As I think that this is a very valuable tool for developers, I already made a short dive into the CLI which resulted in several [videos](https://youtube.com/playlist?list=PLmZLSvJAm8FbFq2XhqaPZgIzl6kewz1HD) and a [blog post](https://dev.to/lechnerc77/the-azure-developer-cli-a-walk-through-22fm) summarizing these videos.

The CLI brings some great kickstart when starting the development of a project from scratch aka a greenfield project. As mentioned in the blog post and the videos I think that the CLI s of incredible values especially for companies and enterprises to streamline their development process. Having said that this opens up another question in the context of the azd, namely how much effort is needed to make an existing project compatible with the azd i. e., the structure that needs to be in place to achieve this.

In this post I want to walk you through this journey taking a sample project and explore what needs to be done and what I might stumble across. Let's see how things went.

## The starting point - An Azure Functions Project

As a basis project I took an Azure Functions project that I created for the [Azure Functions University](https://github.com/marcduiker/azure-functions-university). It is a very basic setup consisting of an HTTP triggered Azure Function with an output binding to a Blob Storage. Not really fancy but still enough moving parts to get a feeling for the journey.

The Azure Function is written in TypeScript and the structure of the Function is as "usual".

In order to align with the best practices showcased in the samples that are referenced by the azd, the infrastructure setup should look like this:

- One Function app that contains the Azure Functions.
- One Azure Storage Account for the Azure Function *per se*.
- One dedicated Storage Account for the Blob Storage used by the output binding.
- The connection string for the Blob Storage is stored in an Azure Key Vault and referenced in the Function App's Application Settings.
- In accordance to the samples Application Insights component should be deployed.

As a blueprint for the project layout, I took the azd sample ToDo sample application using [Static Web Apps](https://github.com/Azure-Samples/todo-nodejs-mongo-swa-func) as this is the one that is closest to our setup. So throughout the journey I either compared or copied snippets from this sample and adjusted them accordingly.

This is the way - let us see what we have to do in oder to make create an azd compatible project.

## Step 1 - Move the sources

As we already have the sources of the Azure Function in our root folder in our root folder and I like the structure with a `src` folder, the first thing I did was:

- Creating a `src` folder in the root folder.
- Moving the source files into this folder, so everything except for the `.vscode` folder that stays in the root folder.

I also moved the `.gitignore` file into the `src` folder, as it is the case in the template.

Step 1 is done.

> 📝 Remark - There is an `azd init` command with an empty template that is probably intended for a basic project setup. But at the time when writing this blog post, this is not really helping a lot as basically nothing is created.

## Step 2 - Create basic file structure and content

Next I created the basic file structure and content for the project. This is the structure that I created:

- A folder `.github/workflows` to define the GitHub Actions workflows.
  - I create the file `azure-dev.yaml` in the folder and copied the content from the sample app into it.
  - I remove the `master` statements as I think that this should not be needed anymore - `main` is the way.
  - I also added some comments in the file with respect to the provisioning section as I think a simple deploy instead of a provision makes more sense.
- A folder `infra`that will be the home of our `.bicep` files.
- A `.gitignore`file in the root folder. Here I added the `.azure` plus a big remark where the other `.gitignore` is located. I was confused when looking into the `.gitignore` in the sample, so maybe others are too.
- A `LICENSE`and a `Notice.txt` file that I copied from the sample.
- A `.gitattributes` file that I copied from the sample.

With this the basic structure and parts of the contents are in place - step 2 is done.

> 📝 Remark - I did not create a `.azdo` folder for Azure DevOps related configurations, as I wanted to focus on GitHub Actions.

## Step 3 - Adoption of .vscode

As the journey started from the Azure Functions project, two adoptions needed to be made when it comes to the `.vscode` file. The changes I made were:

- Adding `"ms-azuretools.azure-dev"` to `extension.json` as this is needed for the azd extension.
- Adjusting the location of the source files in `launch.json` to `"cwd": "${workspaceFolder}/src"` as we moved the file in our first step.

Not too much effort, so step 3 is done.

## Step 4 - Development container setup

As the azd samples support development containers (which makes perfect sense), I added this to the new project. I basically copied the `.devcontainer` folder from the Static Web App sample. As the project relies on Azure Functions only, I adjusted the `devcontainer.json` with respect to the forwarded ports i.e., I removed the existing ports and added port `7071` as standard port for Azure Functions.

As I started on Windows, I also adjusted the `.gitattributes` file with the following content:

```bash
* text=auto eol=lf
*.{cmd,[cC][mM][dD]} text eol=crlf
*.{bat,[bB][aA][tT]} text eol=crlf
```

The reasoning behind this is the difference in the end of line setting between Windows and Linux which can result in many modified files in the development container (see also [here](https://code.visualstudio.com/docs/remote/troubleshooting#_resolving-git-line-ending-issues-in-containers-resulting-in-many-modified-files)).

> 📝 Remark - When you start the development container for the very first time, some larger packages need to be downloaded like the Azure CLI.The startup time can therefore be a bit longer than usual.

With that all is set for the development container setup, so step 4 is also done.

## Step 5 - azure.yaml

No we can finally start with the specifics of the Azure Developer CLI projects. The main main (metadata) file is the `azure.yaml` file. For my TypeScript based Azure Functions project I added the following content:

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

```

The support due to the referenced language server is great, so you get excellent support when entering data.

> 📝 Remark - The file used as bassi for the language server is definitely worth closer look as it contains more options than shown above and also give some helpful insights on the default values and hoe optional parameters are derived if not provided explicitly.

There is not more to do, so the basis for the deployment of the source code is in place. Step 5 is done. Let us head over to the last puzzle piece we need to get in place, the infrastructure.

## Step 6 - Infrastructure

One central component of an azz project is the `infra` folder that contains the infrastructure as code via `.bicep` files (and since release 0.2.0 also supports Terraform see [Azure Developer CLI (azd) – September 2022 Release](https://devblogs.microsoft.com/azure-sdk/azure-developer-cli-azd-september-2022-release/)).

As I am be no means an expert in `bicep` this step took some time to get things in place. However, thanks to the sample I already head a decent starting point and mainly needed to fill in the delta between the sample and my project. So what did I do? First of all some copy and paste (as every good senior developer does ;-)) from the sample project and my `infra` folder namely the following files:

- `abbreviations`
- `main.parameters.json`
- `applicationinsights.bicep`
- `resources.bicep`

After that the main work was to adjust the `resources.bicep` files and consequently the connected output parameters in the `main.bicep` file. First I got rid of all the resources and parameters related to Cosmos DB and the Static Web App i. e. the frontend of the sample app.

The main change was to add the code for an additional Blob storage used for the output binding of the Azure Function including a container:

```bicep
resource blobstorageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: '${abbrs.storageStorageAccounts}${resourceToken}${blobStorageName}'
  location: location
  tags: tags
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${blobstorageAccount.name}/default/${blobContainerName}'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}
```

My goal was to store the connection string of the Blob storage in Azure Key Vault and reference it in the Azure Function App configuration. In contrast to the Cosmos DB resource the Azure storage in bicep does not come with a `getConnectionString` method, I needed to construct the connection string manually. The secret resource looks like this:

```bicep
  resource blobConnectionString 'secrets@2022-07-01' = {
    name: '${blobStorageSecretName}'
    properties: {
      value: 'DefaultEndpointsProtocol=https;AccountName=${blobstorageAccount.name};AccountKey=${blobstorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
    }
  }
```

> 📝 Remark - The resource is contained within the KeyVault resource definition so no referencing of the parent resource is needed.

To bring the things together I added the reference to the  Function App configuration:

```bicep
  resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsResources.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING
      AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storage.listKeys().keys[0].value}'
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'node'
      SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
      BLOB_STORAGE_CONNECTION_STRING: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/${blobStorageSecretName})'
      AZURE_KEY_VAULT_ENDPOINT: keyVault.properties.vaultUri
    }
  }
```  

I also updated some resource versions to latest and greatest.

With this everything is in place to start the provisioning of the infrastructure and deploy the Azure Functions app ... at least so I thought.

## Connecting the dots

In order to identify issues in the different phases of `azd up` I executed the phases manually via the dedicated commands of `azd` and appending the `--debug`lag to get a more verbose output.

The command sequence was:

- `azd init` - all good (what should go wrong here)
- `azd provision` - all good (not on the first run, but that was just stupid me struggling with bicep)
- `azd deploy` - all ... not good

The deployment failed with an interesting error message:

```bash
{"error":{"code":"ResourceNotFound","message":"The Resource 'Microsoft.Web/sites/test-app-migrationapi' under resource group 'rg-test-app-migration' was not found. For more details please go to https://aka.ms/ARMResourceNotFoundFix"}}
DEBUG: cli.azure.cli.core.util: azure.cli.core.util.handle_exception is called with an exception:
```

> 📝 Remark - I changed the naming throughout the journey, so don't be confused if you do not find the names in the resources in the GitHub repository

Hmmm .. what does that mean? I did not explicitly specify the resource where the app should be deployed to (and of course was assuming some hidden magic would find it out). My first stop to sort things out was the `yaml` file serving the `azure.yaml` structure. Here I got the first hint when looking at the property `resourceName`:

```json
"properties": {
                    "resourceName": {
                        "type": "string",
                        "title": "Name of the Azure resource that implements the service",
                        "description": "Optional. If not specified, the resource name will be constructed from current environment name concatenated with service name (<environment-name><resource-name>, for example 'prodapi')."
```

Okay, that explains the error message. Setting the `resourceName` explicitly with the value available via the Azure Portal allowed a successful deployment, but that could not be the solution, as the value is determined dynamically vs. my hard coding in the file.

Not finding information in the documentation I created an issue in the GitHub repo of the CLI ([Deployment of Function - Targeting Function App](https://github.com/Azure/azure-dev/issues/635)) and I got a very fast response explaining the setup. The connection between the infrastructure and the resource that will host the deployed app is determined "*by looking at all the resource groups for your application and then for a resource tagged with azd-service-name with a value that matches the key for the service in azure.yaml*".

So the glue between the service name in the `azure.yaml` and the corresponding resource is the tag in the `resource.bicep` file. I like that approach, but did not think about that although in the hindsight it makes perfect sense.

In my case I adjusted the tagging to:

```bicep
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: '${abbrs.webSitesFunctions}api-${resourceToken}'
  location: location
  tags: union(tags, { 'azd-service-name': 'blob-output-binding' })
  kind: 'functionapp,linux'
```

With that everything works as expected, so full success!

## Summary and remarks

Overall the conversion of an existing project into an `azd`-compatible setup gave me a good experience and the effort was low (being aware that this was not a battle-hardened project running in production), so I think th effort is worth the benefit. I cannot state the exact time I needed to get things going (at least with my level of bicep knowledge it would not be fair to take that as a fair measure), but I am quite sure the adjustment can be done in well below an hour. In case you have the Infrastructure as Code already in place, it is probably straight forward to get the setup and we are in a range of minutes. However, if something goes wrong, the feedback loop takes some time when you have to fix e.g., the `bicep files` (it is always the last resource to be deployed that throws an error .. always). This feedback loop would maybe be reduced by improving the preflight checks of bicep (like naming of storage accounts that seems not to be checked).

In case of an error the azd CLI returns the correlation ID of the provisioning, so one can find the details of the error via:

```bash
az monitor activity-log list --correlation-id <your ID>
```

The CLI and features like the different language servers for `bicep` and the `azure.yaml` as well as the VSCode extension already give good support. However I think some files (basically the ones that I copied without changing them at all) might be worth to be included in the empty template offered by the azd CLI.

What might be a good improvement in the CLI would be a health check e. g. can all the values that need to be derived be fetched in the setup or not which would probably prevent the issue I stumbled across with the missing or wrong tagging of the resources. But it is version 0.2.0 and taking this into account the functionality is already really good I would say.

I will closely follow the future evolutions and improvements with regards to the Azure Developer CLI, looking forward to what the teams will come up with!

## Useful references

Useful references if you want to try things out on your own:

- [azd documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview?tabs=nodejs)
- [bicep documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [bicep playground](https://bicepdemo.z22.web.core.windows.net/)
- [Azure Developer CLI (azd) – September 2022 Release](https://devblogs.microsoft.com/azure-sdk/azure-developer-cli-azd-september-2022-release/) - information and links for Terraform

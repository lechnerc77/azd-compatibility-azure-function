# Sample compatibility journey for the Azure Developer CLI 

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

The following minor adoptions need to be made:

- Add `"ms-azuretools.azure-dev"` to `extension.json`
- Add `"cwd": "${workspaceFolder}/src"` to `launch.json` as we moved the file.

## Step 4 - Devcontainer Setup

The following minor adoptions need to be made:

- Copy & Paste the files from the SWA sample app
- Change the port forward in `devcontainer.json` to `7071`

## Step 5 - azure.yaml

Adjust the main file to:

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

Look at the yaml file to see what is possible to configure.

You get excellent support from the yaml language server referencing the schema.

## Step 6 - Infrastructure

- Copy `abbreviations`
- Copy `main.parameters.json`
- Copy `applicationinsights.bicep`
- Copy and adjust `resources.bicep`
  - remove COSMOS DB related stuff
  - add Blob Storage
  - remove static web app frontend
  - adjust `api` to `function`

- Updated resources version to latest and greatest

## Remarks

- like the yaml language server for azure.yaml
- Intentionally left out Azur DevOps component
- No test folder available

If something goes wrong: just print the command instead of just correlation id:

az monitor activity-log list --correlation-id 2c409da4-a6c0-4359-9d35-a79124e580d6
2c409da4-a6c0-4359-9d35-a79124e580d6

(of course I put a "-" into the name of the storage)

There is no getConnectionString for Storage Accounts, you must construct it on you own

Best way to structure (sequence)

Interesting: <https://raw.githubusercontent.com/Azure/azure-dev/main/schemas/v1.0/azure.yaml.json>:

Error due to not understanding/thinking about how the CLI links together the resource with the deployment:

```bash

```json
"properties": {
                    "resourceName": {
                        "type": "string",
                        "title": "Name of the Azure resource that implements the service",
                        "description": "Optional. If not specified, the resource name will be constructed from current environment name concatenated with service name (<environment-name><resource-name>, for example 'prodapi')."
```

The error is:

```json
{"error":{"code":"ResourceNotFound","message":"The Resource 'Microsoft.Web/sites/test-app-migrationapi' under resource group 'rg-test-app-migration' was not found. For more details please go to https://aka.ms/ARMResourceNotFoundFix"}}
DEBUG: cli.azure.cli.core.util: azure.cli.core.util.handle_exception is called with an exception:
```

See issue [Deployment of Function - Targeting Function App](https://github.com/Azure/azure-dev/issues/635) for more background information on how the CLI determines/glues the Function App to the source/deployment of the app:

> It does this by looking at all the resource groups for your application and then for a resource tagged with azd-service-name with a value that matches the key for the service in azure.yaml (in your sample app, this is api).

So the tags and the matching information in the `azure.yaml` file are important; makes sense, but not documented.

Off Topic: Upgrade of CLI works, just reinstall it as documented on GitHub.

Change gitingore to see  <https://code.visualstudio.com/docs/remote/troubleshooting#_resolving-git-line-ending-issues-in-containers-resulting-in-many-modified-files>:

```bash
* text=auto eol=lf
*.{cmd,[cC][mM][dD]} text eol=crlf
*.{bat,[bB][aA][tT]} text eol=crlf
```

When coming from Windows

## References

[bicep playgorund](https://bicepdemo.z22.web.core.windows.net/)

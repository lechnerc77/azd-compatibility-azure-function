# Sample Migration Project for AZD

This is a sample migration project for making one exercise of the AZure Functions University compatible with azd.

## Step 0 - Getting the Azure Functions Project to run

As basis we use a simple HTTP triggered Azure Function that has a output binding to a Blob storage.

## Step 1 - Move the sources

Create a folder for sources (`src`) in the root directory and move the relevant data there.
Basically everything except for `.vscode`.

## Step 2 - Create Basic file structure and content

Created files/directories:

- .github/workflows
  - create the file `azure-dev.yaml` and copy content from another azd sample
  - Remove `master` statements
  - Add comment to provisioning section
- infra
- .gitignore
  - added .azure plus big remark where the other `.gitignore` is located
- LICENSE
- Notice.txt
- .gitattributes

## Step 3 - Adoption of .vscode

The following minor adoptions need to be made:

- Add `"ms-azuretools.azure-dev"` to `extension.json`
- Add ` "cwd": "${workspaceFolder}/src"` to `launch.json` as we moved the file.

## Step 4 - Devcontainer Setup

The following minor adoptions need to be made:

- Copy & Paste the files from the SWA sample app
- Change the port forward in `devcontainer.json` to `7071`

## Step 5 - azure.yaml

Adjust the main file to 

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/Azure/azure-dev/main/schemas/v1.0/azure.yaml.json

name: azure-functions-blob
metadata:
  template: azure-functions-blob@0.0.1-beta
services:
  api:
    project: src
    language: ts
    host: function

```

## Step 6 - Infrastructure

- Copy `abbreviations`
- Copy `main.parameters.json`
- Copy `applicationinsights.bicep` 


## Remarks

- azd init with the emoty template is really ... not too much information in there
- like the yaml language server for azure.yaml
- Intentionally left out Azur DevOps component
- No test folder available
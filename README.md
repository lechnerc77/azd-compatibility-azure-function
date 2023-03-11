# Sample azd project - Azure Function with Blob Output Binding

## Introduction

The **main** branch of this repository contains the sample code for an *Azure Functions* project with an *output binding* to a Blob Storage. It follows the setup of the *Azure Developer CLI* as of version 0.6.0-beta2.

## Branches

To go from a sample Azure Functions project to a setup compatible with the Azure Developer CLI comprises some steps. You find these steps including a description in the branches:

- [azd-020-beta1](https://github.com/lechnerc77/azd-compatibility-azure-function/tree/azd-020-beta1): This branch contains the code and the description to make a plain Azure Functions project compatible with the Azure Developer CLI. The related blog post is available on dev.to as [The Azure Developer CLI - Compatibility journey for an Azure Functions Project](https://dev.to/lechnerc77/the-azure-developer-cli-compatibility-journey-for-an-azure-functions-project-3mc1)
- [azd-020-beta2](https://github.com/lechnerc77/azd-compatibility-azure-function/tree/azd-020-beta2): This branch contains the code and the description to adopt the changes in the infrastructure description that have been introduced with version 0.2.0-beta2. The related blog post is available on dev.to as [Azure Developer CLI - The new infrastructure setup](https://dev.to/lechnerc77/azure-developer-cli-the-new-infrastructure-setup-4caj).
- [azd-040-beta1](https://github.com/lechnerc77/azd-compatibility-azure-function/tree/azd-040-beta1): This branch contains the code and the description to adopt the changes in the infrastructure description that have been introduced with version 0.4.0-beta1. The related blog post is available on dev.to as [Azure Developer CLI episode 0.4.0 - the compatibility journey continues](https://dev.to/lechnerc77/azure-developer-cli-episode-040-the-compatibility-journey-continues-400g).
- [azd-050-beta3](https://github.com/lechnerc77/azd-compatibility-azure-function/tree/azd-050-beta3): This branch contains the code and the description to adopt the changes in the infrastructure description that have been introduced with version 0.5.0-beta1 to 0.5.0-beta3.  The related blog post is available on dev.to as [Azure Developer CLI episode 0.5.0 - refactoring ahead](https://dev.to/lechnerc77/azure-developer-cli-episode-050-refactoring-ahead-11k6).
- [azd-060-beta2](https://github.com/lechnerc77/azd-compatibility-azure-function/tree/azd-060-beta2): This branch contains the code and the description of changes that are made to use the new options available with version 0.6.0-beta2. The related blog post is available on dev.to as [Azure Developer CLI Azure Developer CLI episode 0.6.0 - I am hooked](https://dev.to/lechnerc77/azure-developer-cli-azure-developer-cli-episode-060-i-am-hooked-4on0).
  > **Note** - All updates in the `azd` version 0.7.0 (see [release notes](https://github.com/Azure/azure-dev/releases/tag/azure-dev-cli_0.7.0-beta.1)) do not imply any changes in the project setup. So the branch [azd-060-beta2](https://github.com/lechnerc77/azd-compatibility-azure-function/tree/azd-060-beta2) can also be used with version 0.7.0-beta1 without any changes.

## Useful references

Useful references if you want to try things out on your own:

- [azd documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview?tabs=nodejs)
- [azd on GitHub](https://github.com/Azure/azure-dev)
- [bicep documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [bicep playground](https://bicepdemo.z22.web.core.windows.net/)
- [Azure Developer CLI (azd) – September 2022 Release](https://devblogs.microsoft.com/azure-sdk/azure-developer-cli-azd-september-2022-release/) - information and links for Terraform
- [Azure Developer CLI (azd) – October 2022 Release](https://devblogs.microsoft.com/azure-sdk/azure-developer-cli-azd-october-2022-release/)
- [Azure Developer CLI (azd) – November 2022 Release](https://devblogs.microsoft.com/azure-sdk/azure-developer-cli-azd-november-2022-release/)
- [Azure Developer CLI (azd) – January 2023 Release](https://devblogs.microsoft.com/azure-sdk/azure-developer-cli-azd-january-2023-release/)
- [Azure Developer CLI (azd) – February 2023 Release](https://devblogs.microsoft.com/azure-sdk/azure-developer-cli-azd-february-2023-release/)
- [Azure Developer CLI (azd) – March 2023 Release](https://devblogs.microsoft.com/azure-sdk/azure-developer-cli-azd-march-2023-release/)
- [QuickGlance - Azure Developer CLI](https://youtube.com/playlist?list=PLmZLSvJAm8FbFq2XhqaPZgIzl6kewz1HD)
- [The Azure Developer CLI - Compatibility journey for an Azure Functions Project](https://dev.to/lechnerc77/the-azure-developer-cli-compatibility-journey-for-an-azure-functions-project-3mc1)
- [Azure Developer CLI - How does it know that?](https://dev.to/lechnerc77/azure-developer-cli-how-does-it-know-that-1ngl)

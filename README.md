# Sample compatibility journey for the Azure Developer CLI - Updates with azd 0.4.0-beta.1

> ⚠ **The steps and the code presented in this branch are described and built in accordance to the new infrastructure setup Azure Developer CLI version [0.4.0-beta.1 (2022-11-02)](https://github.com/Azure/azure-dev/releases/tag/azure-dev-cli_0.4.0-beta.1) and later**

## Introduction

With the updates of the Azure Developer CLI to version [0.3.0-beta3](https://github.com/Azure/azure-dev/releases/tag/azure-dev-cli_0.3.0-beta.3) and finally [0.4.0-beta.1 (2022-11-02)](https://github.com/Azure/azure-dev/releases/tag/azure-dev-cli_0.2.0-beta.2) simplifications were introduced that affect the structuring of the `bicep` templates. The overall layout was simplified and the bicep templates from the core library have been re-structured and improved..

> 📝 Remark: The setup presented here is also valid with the CLI version [0.4.0-beta.1](https://github.com/Azure/azure-dev/releases/tag/azure-dev-cli_0.4.0-beta.1).

## What has changed

We start with the setup that was state-of-the-art with version 0.2.0-beta.2 and take it from there: 

Change in the setup of the `devcontainer.json`. The deprecated syntax of the feature description is updated and references the features  via [https://github.com/devcontainers](https://github.com/devcontainers)

This brings us from here:

```json
"features": {
        "github-cli": "2",
        "azure-cli": "2.40",
        "docker-from-docker": "20.10",
        "node": {
            "version": "16",
            "nodeGypDependencies": false
        }
    }
```

to the new setup:

```json
"features": {
        "ghcr.io/devcontainers/features/azure-cli:1": {
            "version": "2.40"
        },
        "ghcr.io/devcontainers/features/docker-from-docker:1": {
            "version": "20.10"
        },
        "ghcr.io/devcontainers/features/github-cli:1": {
            "version": "2"
        },
        "ghcr.io/devcontainers/features/node:1": {
            "version": "16",
            "nodeGypDependencies": false
        }
    }
```

Nice, but the main new hot stuff for me is the restructuring of the `.bicep` infrastructure. Yes they did it again, and I like what that did, as it makes my setup easier and improves the transparency what happens without too many hops due to layers of abstraction. The restructuring has some impact: compared to the prior version there are now:

- different templates with new/different parameters
- a new structure to find the files
- new `.bicep` files due to new templates (like the C# one).



Everything is in main now, so copy& paste to main.bicep and enjoy the red lines as the refrenced resources doe not work (of course)

Renaming of some output parameters (like keyvault)

Adjust based on the SWA sample for the usual suspects like monitiring an d application insights

Key valut access from function, explicit resource (was there ebfore, but not used in sample)

Storagr container. Get rid of all custom built modules as I can now tranfer a name + I can add containers

Adjustment of my privatwe resource for storage secret to new "parameter convention"

## Where to find the code

You find the code and the description of the project here (mind the branch):

<https://github.com/lechnerc77/azd-compatibility-azure-function/tree/azd-040-beta1>

The latest and greatest project code is in the [main branch](https://github.com/lechnerc77/azd-compatibility-azure-function) which might deviate from the code described in this blog post.

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

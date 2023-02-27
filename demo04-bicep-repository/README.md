# Instructions for Demo 4 - Bicep Registry

## What will be deployed

Nothing.

This example show how a bicep repository can be used to store bicep modules for re-use in different projects.

The sample module is a preconfigured network security group module in file [repository/nsg-web.bicep](repository/nsg-web.bicep)

## Prerequisites

- Install [Azure CLI](https://learn.microsoft.com/de-de/cli/azure/install-azure-cli)

## Step 1 - Create Container Registry

- Create a container registry or use an existing one
  - Create

    ```bash
    RG=rg-azday-deps
    LOCATION=northeurope
    ACR_NAME=acrazdaysdep$RANDOM

    az group create --name $RG --location $LOCATION
    az acr create --name $ACR_NAME --resource-group $RG --sku Basic
    ```

  - Use existing one

    ```bash
    RG=<resource group containing acr>
    ACR_NAME=<name of the acr>
    ```

- Store login server in variable

  ```bash
  ACR_LOGIN_SEVER=$(az acr show --name $ACR_NAME --resource-group $RG --query loginServer -o tsv)
  ```

## Step 2 - Push Bicep module to

- Push `repository/nsg-web.bicep` module to ACR

  ```bash
  az bicep publish --file repository/nsg-web.bicep --target br:$ACR_LOGIN_SEVER/bicep/modules/nsg-web:1.0.0
  ```

## Step 3 - Call the module via repository reference

- Add reference to bicep file

  ```bash
  module nsgWeb 'br:acrazdaysdep13834.azurecr.io/bicep/modules/nsg-web:1.0.0' = {
    name: 'module-nsgWeb'
    params: {
      name: 'azday-demo04'
      location: location

      usePort443: true
      usePort80: true
    }
  }
  ```

- See the reference starts with `br:`
- It contains the whole path to the module in the container registry including the registry fqdn
- It contains the tag for the specific version to use

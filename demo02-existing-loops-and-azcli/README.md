# Instructions for Demo 2 - Existing, Loops and Azure CLI

## What will be deployed

This example deploys to 2 additional resources of type storage account to the infrastructure. On storage account is used for internal app resources, the other is used for external resources. They are named that way.

The storage accounts are of kind `StorageV2`, which allows a general purpose usage of storage accounts. The redundency configuration will be set to `LRS` (local redundant storage)

Also the existing key vault gets retrieved to add the connection strings of the storage accounts as secrets.

The purpose of this demo is to show how bicep works.

## Prerequisites

- Install Extension: [Bicep](ttps://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) / [ms-azuretools.vscode-bicep](ttps://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)
- Do [demo01](../demo02-existing-loops-and-azcli/)
- Install [Azure CLI](https://learn.microsoft.com/de-de/cli/azure/install-azure-cli)

## Step 1 - Create an array with storage account info

- Create an array variable with `internal` and `external` as values

  ```bicep
  var accountUsages = [
    'internal'
    'external'
  ]
  ```

## Step 2 - Create resources via loop

- Create a storage account with the following configuration
  - Set `kind` to `StorageV2`
  - Set `sku.name` to `Standard_LRS`
  - Set `properties.accessTier` to `Hot`
- Use the `for` keyword to create a storage account for every `accountUsage`
  - `[for accountUsages in accountUsages: {}]`

    ```bicep
    resource storageAccounts 'Microsoft.Storage/storageAccounts@2022-09-01' = [for accountUsages in accountUsages: {
      name: 'stazday${accountUsages}${suffix}'
      location: location
      kind: 'StorageV2'
      sku: {
        name: 'Standard_LRS'
      }
      properties: {
        accessTier: 'Hot'
      }
    }]
    ```

## Step 3 - Retrieve existing key vault

- Retrieve existing keyvault create in *demo01*
  - Create a parameter for the keyvaultName
    - Name `keyvaultName`
    - Type `string`
- Use `existing` keyword to retrieve the keyvault
  - Create `resource`
  - Name it `keyVault`
  - Set type to `'Microsoft.KeyVault/vaults@...'`
  - append `existing` to the declaration
  - add the parameter `keyvaultName` to the `name` property

    ```bicep
    resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
      name: keyvaultName
    }
    ```

## Step 4 - Create keyvault secrets

- Add a loop to create secrets for all created storage accounts
  - Create secret resource
  - Loop over the range of the `accountUsages` variable

    ```bicep
    resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [for i in range(0, length(accountUsages)): {
    }]
    ```

- Reference the storage account information by using the `storageAccounts` identifier and use the index of the array to select specific information
  - Set `name` of the secret to `connection-string-` and suffix it with the storage account name

    ```bicep
    name: 'connection-string-${storageAccounts[i].name}'
    ```

  - Build the connection string and set it as `properties.value` value

    ```bicep
    properties: {
      value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccounts[i].name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccounts[i].listKeys().keys[0].value}'
    }
    ```

## Deploy

### Deployment via VS Code

- Deploy via file
  - Right-click Bicep file and select `Deploy Bicep File...`
  - Go through the wizard

### Deployment via Azure CLI

- Ensure [Azure CLI](https://learn.microsoft.com/de-de/cli/azure/install-azure-cli) is installed
- Login to Azure with `az login`
- Check bicep is available with `az bicep -h`; Install it if not with `az bicep install`

#### Prerequisites

- Set variable for resource group for better reference in the terminal

  ```bash
  RG=theresourcegroup
  ```

- Get keyvault name from deployment

  ```bash
  KEYVAULT_NAME=$(az deployment group list --resource-group rg-test-azday-1234 --query "[0].properties.outputs.keyVaultName.value" -o tsv)
  ```

#### Check Deployment

- `az deployment group validate --resource-group $RG --template-file storageAccount.bicep`
- No error should occure

#### Check what will be created with What-If

- `az deployment group what-if --resource-group $RG --template-file storageAccount.bicep`
- Check what will be created

### Deploy with confirmation

- `az deployment group create --resource-group $RG --template-file storageAccount.bicep --confirm-with-what-if`

## Parameters

### Single parameters

- With plain text variable
  - `az deployment group create --resource-group $RG --template-file storageAccount.bicep --parameters keyvaultName=kv-demo01-azday-fsiqvs`

- With variable
  - Ensure you have the variable `KEYVAULT_NAME` set
  - `az deployment group create --resource-group $RG --template-file storageAccount.bicep --parameters keyvaultName=$KEYVAULT_NAME`

### Parameter files

- Create parameters file
  - Right-click Bicep file and select `Generate Parameters File`
  - Set required parameters
- Pass the parameters file with a `@` using the `--parameters` parameter
  - `az deployment group create --resource-group $RG --template-file storageAccount.bicep --parameters @storageAccount.parameters.json`

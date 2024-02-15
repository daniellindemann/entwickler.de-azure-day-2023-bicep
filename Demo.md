# Demo

## Instructions for Demo 1 - Starting with Bicep

### What will be deployed

This sample shows how to deploy an azure app service and an azure key vault using bicep.

The app service will be deployed with an app service plan with the `Basic` tier. It uses `Linux` as operating system.

Along the key vault a secret gets created that will be referenced as application setting in the app service.

The purpose of this demo is to show how bicep works.

### Prerequisites

- Install Extension: [Bicep](ttps://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) / [ms-azuretools.vscode-bicep](ttps://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)

### Step 1 - Write down main resources

- Create a file called `azuredeploy.bicep`

- Create app service plan
  - Type `res` to show all possible resources with intelli sense
  - Select `res-plan` to create an app service plan
  - Set a `name`
  - Set `location` to `resourceGroup().location`
  - Update `sku.name` to `B1`, remove everything elese

    ```bicep
    sku: {
      name: 'B1'
    }
    ```

  - Set `kind` to `linux`

  - Add properties

    ```bicep
    properties: {
      reserved: true
    }
    ```

  - Update API Version to `2022-03-01`

- Create app service
  - Type `res` select `resource-defaults`
  - Tab through parameters
  - Set identifier to `appService`
  - Set resource type to `Microsoft.Web/sites`
  - Set a `name`
  - Set `location` to `resourceGroup().location`
  - Set `properties`

    ```bicep
    properties: {
      serverFarmId: appServicePlan.id
      httpsOnly: true
      siteConfig: {
          linuxFxVersion: 'DOTNETCORE|8.0'
      }
    }
    ```

  - Add system assigned identity

    ```bicep
    identity: {
      type: 'SystemAssigned'
    }
    ```


- Create key vault
  - Type `res` select `resource`
  - Tab through parameters
  - Set identifier to `keyVault`
  - Set resource type to `Microsoft.KeyVault/vaults`
  - Set a `name`
  - Set `location` to `resourceGroup().location`
  - Set type `properties` and select `required-properties`
    - Set `sku.family` to `'A'`
    - Set `sku.name` to `'standard'`
    - Set `tenantId` to `tenant().tenantId`
    - Add access policies

      > Have a look at the object id and set permissions to list and get secrets

      ```bicep
      accessPolicies: [
        {
          tenantId: tenant().tenantId
          objectId: appService.identity.principalId
          permissions: {
            secrets: [
              'get'
              'list'
            ]
          }
        }
      ]
      ```

- Create Key Vault Secret
  - Type `res` and select `res-keyvault-secret`
  - Set the `name` with keyvault reference; alternative set the `name` without keyvault reference and use `parent` property
  - Set a `value`

### Step 2 - add parameters, variables and outputs

- Add key vault reference to webapp
  - Add `appsettings` to `appService.properties.siteConfig`
  - Add the created secret as key vault reference

    ```bicep
    appSettings: [
      {
        name: 'appSecret'
        value: '@Microsoft.KeyVault(SecretUri=${keyVaultSecret.properties.secretUri})'
      }
    ]
    ```
  - See it doesn't work because of a circular reference
  - Create variable for `keyVaultName` and `keyVaultSecretName`

    > allows to build up the reference by ourself

    ```bicep
    var keyVaultName = 'kv-demo01-azday'
    var keyVaultSecretName = 'mysecret'
    ```

  - Update `name` property of `keyVault` and `keyVaultSecret` to use the variables
  - Update key vault reference to use the variables with string interpolation

    ```bicep
    appSettings: [
      {
        name: 'appSecret'
        value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}${environment().suffixes.keyvaultDns}/secrets/${keyVaultSecretName}/)'
      }
    ]
    ```

- Add parameters for resource group
  - Type `param` and tab through the settings
  - Set identifier to `location` and `type` to string
  - Set default value to `resourceGroup().location`
  - Update location on resources `appServicePlan`, `appService` and `keyVault` to use the `location` parameter

- Add suffix so resources are unique
  - Create variable `suffix`
  - Use build in function `uniqueString` to generate a unique string based on the resource group id

    ```bicep
    var suffix = uniqueString(resourceGroup().id)
    ```

  - 13 chars is really long for a suffix, reduce it to 6 by using the function `substring`

    ```bicep
    var suffix = substring(uniqueString(resourceGroup().id), 0, 6)
    ```

  - Add the suffix to the `name` of the resources

- Add an output for the website url
  - Type `output` and tab through
  - Set identifier to `siteUrl`
  - Set type to `string`
  - Set value to `'https://${appService.properties.defaultHostName}'`

    ```bicep
    output siteUrl string = 'https://${appService.properties.defaultHostName}'
    ```

- Add an output for the keyvault name

  - Type `output` and tab through

  - Set identifier to `keyVaultName`

  - Set type to `string`

  - Set value to `keyVault.name`

    ```bicep
    output keyVaultName string = keyVault.name
    ```

### Deployment

- Deploy via file
  - Right-click Bicep file and select `Deploy Bicep File...`
  - Go through the wizard

---

## Instructions for Demo 2 - Existing, Loops and Azure CLI

### What will be deployed

This example deploys to 2 additional resources of type storage account to the infrastructure. One storage account is used for internal app resources, the other is used for external resources. They are named that way.

The storage accounts are of kind `StorageV2`, which allows a general purpose usage of storage accounts. The redundency configuration will be set to `LRS` (local redundant storage)

Also the existing key vault gets retrieved to add the connection strings of the storage accounts as secrets.

The purpose of this demo is to show how bicep works.

### Prerequisites

- Install Extension: [Bicep](ttps://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) / [ms-azuretools.vscode-bicep](ttps://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)
- Do [demo01](../demo02-existing-loops-and-azcli/)
- Install [Azure CLI](https://learn.microsoft.com/de-de/cli/azure/install-azure-cli)

### Step 1 - Create an array with storage account info

- create a file called `storageAccounts.bicep`

- Create an array variable with `internal` and `external` as values

  ```bicep
  var accountUsages = [
    'internal'
    'external'
  ]
  ```

### Step 2 - Create resources via loop

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

### Step 3 - Retrieve existing key vault

- Retrieve existing key vault create in *demo01*
  - Create a parameter for the key vault name
    - Name `keyVaultName`
    - Type `string`
- Use `existing` keyword to retrieve the key vault
  - Create `resource`
  - Name it `keyVault`
  - Set type to `'Microsoft.KeyVault/vaults@...'`
  - append `existing` to the declaration
  - add the parameter `keyVaultName` to the `name` property

    ```bicep
    resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
      name: keyVaultName
    }
    ```

### Step 4 - Create key vault secrets

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

### Deploy

#### Deployment via VS Code

- Deploy via file
  - Right-click Bicep file and select `Deploy Bicep File...`
  - Go through the wizard

#### Deployment via Azure CLI

- Ensure [Azure CLI](https://learn.microsoft.com/de-de/cli/azure/install-azure-cli) is installed
- Login to Azure with `az login`
- Check bicep is available with `az bicep -h`; Install it if not with `az bicep install`

##### Prerequisites

- Set variable for resource group for better reference in the terminal

  ```bash
  RG=theresourcegroup
  ```

##### Check Deployment

- `az deployment group validate --resource-group $RG --template-file storageAccount.bicep`
- No error should occure

##### Check what will be created with What-If

- `az deployment group what-if --resource-group $RG --template-file storageAccount.bicep`
- Check what will be created

#### Deploy with confirmation

- `az deployment group create --resource-group $RG --template-file storageAccount.bicep --confirm-with-what-if`

### Parameters

#### Prerequisites - Get key vault variable

- Get key vault name from previous deployment

  ```bash
  KEYVAULT_NAME=$(az deployment group list --resource-group $RG --query "[0].properties.outputs.keyVaultName.value" -o tsv)
  ```

#### Single parameters

- With plain text variable
  - `az deployment group create --resource-group $RG --template-file storageAccount.bicep --parameters keyVaultName=kv-demo01-azday-fsiqvs`

- With variable
  - Ensure you have the variable `KEYVAULT_NAME` set
  - `az deployment group create --resource-group $RG --template-file storageAccount.bicep --parameters keyVaultName=$KEYVAULT_NAME`

#### Parameter files

- Create parameters file
  - Right-click Bicep file and select `Generate Parameters File`
  - Set required parameters
- Pass the parameters file with a `@` using the `--parameters` parameter
  - `az deployment group create --resource-group $RG --template-file storageAccount.bicep --parameters @storageAccount.parameters.json`

---

## Instructions for Demo 3 - Individual modules for resources

### What will be deployed

This example deploys 2 virtual networks with subnets and a network security group which allows traffic for web applications via *http* and *https*.

The first network deploys a specific ip range and creates only one subnet that took the whole ip address range. It also add the network security group to the subnet.

The second network deploys a specific ip range but doesn't automatically create a subnet. The subnets are created individually with custom network security group configurations.

### Prerequisites

- Install Extension: [Bicep](ttps://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) / [ms-azuretools.vscode-bicep](ttps://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)

### Step 1 - Inspect VNET

- Open [modules/vnet.bicep](modules/vnet.bicep)
- See it calls a module to create a network security group with file [modules/nsg-web.bicep](modules/nsg-web.bicep)
- Inspect the *nsg-web.bicep* module
  - See resources
  - See outputs
- Back in *vnet.bicep* module
  - Check vnet configuration
  - Check subnet configuration with condition
  - See outputs
- Inspect `firstVnet` in [azuredeploy.bicep](azuredeploy.bicep)

### Step 2 - Inspect VNET

- Inspect `secondVnet` in [azuredeploy.bicep](azuredeploy.bicep)
- Check VNET configuration
- Inspect different subnet configurations
  - Take a look to used output of vnet module that re-used the created network security group

---

## Instructions for Demo 4 - Bicep Registry

### What will be deployed

Nothing.

This example show how a bicep repository can be used to store bicep modules for re-use in different projects.

The sample module is a preconfigured network security group module in file [repository/nsg-web.bicep](repository/nsg-web.bicep)

### Prerequisites

- Install [Azure CLI](https://learn.microsoft.com/de-de/cli/azure/install-azure-cli)

### Step 1 - Create Container Registry

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

### Step 2 - Push Bicep module to

- Push `repository/nsg-web.bicep` module to ACR

  ```bash
  az bicep publish --file repository/nsg-web.bicep --target br:$ACR_LOGIN_SEVER/bicep/modules/nsg-web:1.0.0
  ```

### Step 3 - Call the module via repository reference

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


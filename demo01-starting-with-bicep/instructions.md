# Instructions for Demo 1 - Starting with Bicep

## What will be deployed

This sample shows how to deploy an azure app service and an azure key vault.

The app service will be deployed with an app service plan with the `Basic` tier. It uses `Linux` as operating system.

Along the key vault a secret gets created that will be referenced as application setting in the app service.

## Prerequisites

- Install Extension: [Bicep](ttps://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) / [ms-azuretools.vscode-bicep](ttps://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)

## Step 1 - Write down main resources

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
          linuxFxVersion: 'DOTNETCORE|7.0'
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

## Step 2 - add parameters, variables and outputs

- Add key vault reference to webapp
  - Add `appsettings` to `appService.properties.siteConfig`
  - Add the created secret as key vault reference

    ```bicep
    appSettings: [
      {
        name: 'appSecret'
        value: '@Microsoft.KeyVault(${keyVaultSecret.properties.secretUri})'
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
  - Set default value to `'https://${appService.properties.defaultHostName}'`

    ```bicep
    output siteUrl string = 'https://${appService.properties.defaultHostName}'
    ```

## Deployment

- Deploy via file
  - Right-click Bicep file and select `Deploy Bicep File...`
  - Go through the wizard

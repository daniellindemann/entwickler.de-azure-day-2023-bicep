# Instructions for Demo 3 - Individual modules for resources

## What will be deployed

This example deploys 2 virtual networks with subnets and a network security group which allows traffic for web applications via *http* and *https*.

The first network deploys a specific ip range and creates only one subnet that took the whole ip address range. It also add the network security group to the subnet.

The second network deploys a specific ip range but doesn't automatically create a subnet. The subnets are created individually with custom network security group configurations.

## Prerequisites

- Install Extension: [Bicep](ttps://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) / [ms-azuretools.vscode-bicep](ttps://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)

## Step 1 - Inspect VNET

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

## Step 2 - Inspect VNET

- Inspect `secondVnet` in [azuredeploy.bicep](azuredeploy.bicep)
- Check VNET configuration
- Inspect different subnet configurations
  - Take a look to used output of vnet module that re-used the created network security group

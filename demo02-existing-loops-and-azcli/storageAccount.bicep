@description('Location for resource deployment')
param location string = resourceGroup().location

@description('Name of the key vault')
param keyvaultName string

var suffix = substring(uniqueString(resourceGroup().id), 0, 6)

// these are unchangable settings for this deployment
var accountUsages = [
  'internal'
  'external'
]

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

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyvaultName
}

resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [for i in range(0, length(accountUsages)): {
  name: 'connection-string-${storageAccounts[i].name}'
  parent: keyVault
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccounts[i].name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccounts[i].listKeys().keys[0].value}'
  }
}]

output storageAccounts array = [for i in range(0, length(accountUsages)): {
  id: storageAccounts[i].id
  blobEndpoint: storageAccounts[i].properties.primaryEndpoints.blob
}]

@description('Location for resource deployment')
param location string = resourceGroup().location

@description('Deploys the second VNET, if `true`')
param enableSecondVnet bool = false

// ---

module firstVnet 'modules/vnet.bicep' = {
  name: 'module-firstVnet'
  params: {
    location: location
    name: 'azday-demo03-first'

    addressPrefix: '192.168.10.0/24'
    useSingleSubnet: true
  }
}

// ---

module secondVnet 'modules/vnet.bicep' = if(enableSecondVnet) {
  name: 'module-secondVnet'
  params: {
    location: location
    name: 'azday-demo03-second'

    addressPrefix: '192.168.11.0/24'
    useSingleSubnet: false
  }
}

module subnetOne 'modules/subnet.bicep' = {
  name: 'module-subnetOne'
  params: {
    addressPrefix: '192.168.11.0/28'
    name: 'one'

    vnetName: secondVnet.outputs.name
    nsgId: secondVnet.outputs.nsgId
  }
}

module subnetTwo 'modules/subnet.bicep' = {
  name: 'module-subnetTwo'
  params: {
    addressPrefix: '192.168.11.16/28'
    name: 'two'

    vnetName: secondVnet.outputs.name
    nsgId: ''
  }
}

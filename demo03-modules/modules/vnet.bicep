param location string = resourceGroup().location

@description('VNET name')
param name string

@description('''
IPv4 address space in cidr notation
e.g. `10.0.0.0/16`
''')
param addressPrefix string

@description('''
If `true` the whole vnet address space will be used for the subnet, otherwise `false`.
''')
param useSingleSubnet bool = false

module webNsg 'nsg-web.bicep' = {
  name: 'module-webNsg-${name}'
  params: {
    name: 'azday-demo03-web-for-${name}'
    location: location

    usePort80: false
    usePort443: true
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-${name}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
  }
}

module singleSubnet 'subnet.bicep' = if(useSingleSubnet) {
  name: 'module-subnet-singleSubnet'
  params: {
    name: 'main'
    addressPrefix: addressPrefix
    vnetName: virtualNetwork.name
    nsgId: webNsg.outputs.id
  }
}

output id string = virtualNetwork.id
output name string = virtualNetwork.name
output nsgId string = webNsg.outputs.id

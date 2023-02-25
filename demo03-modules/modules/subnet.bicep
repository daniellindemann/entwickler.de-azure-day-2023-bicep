@description('Id of the VNET')
param vnetName string

@description('Name of the subnet')
param name string

@description('''
IPv4 address space in cidr notation
e.g. `10.0.0.0/16`
''')
param addressPrefix string

@description('Name of the NSG, empty if you don\'t want to use a NSG')
param nsgId string = ''

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: '${vnetName}/snet-${name}'
  properties: {
    addressPrefix: addressPrefix
    networkSecurityGroup: empty(nsgId) ? null : {
      id: nsgId
    }
  }
}

output subnetId string = subnet.id

param location string = resourceGroup().location

// change name of acr accordingly to your acr
module nsgWeb 'br:acrazdaysdep13834.azurecr.io/bicep/modules/nsg-web:1.0.0' = {
  name: 'module-nsgWeb'
  params: {
    name: 'azday-demo04'
    location: location

    usePort443: true
    usePort80: true
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-azday-demo04'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.12.0/24'
      ]
    }
    subnets: [
      {
        name: 'snet-azday-demo04-one'
        properties: {
          addressPrefix: '192.168.12.0/28'
          networkSecurityGroup: {
            id: nsgWeb.outputs.id
          }
        }
      }
      {
        name: 'snet-azday-demo04-two'
        properties: {
          addressPrefix: '192.168.12.16/28'
          networkSecurityGroup: {
            id: nsgWeb.outputs.id
          }
        }
      }
    ]
  }
}

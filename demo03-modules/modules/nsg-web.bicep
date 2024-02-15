param location string = resourceGroup().location
param name string
param usePort80 bool = true
param usePort443 bool = true

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-${name}'
  location: location
  properties: {
  }
}

resource nsgRuleHttp 'Microsoft.Network/networkSecurityGroups/securityRules@2023-09-01' = if(usePort80) {
  parent: nsg
  name: 'Allow80Inbound'
  properties: {
    description: 'Allow ALL web traffic into 80. (If you wanted to allow-list specific IPs, this is where you\'d list them.)'
    protocol: 'Tcp'
    sourcePortRange: '*'
    sourceAddressPrefix: '*'
    destinationPortRange: '80'
    destinationAddressPrefix: '*'
    direction: 'Inbound'
    access: 'Allow'
    priority: 600
  }
}

resource nsgRuleHttps 'Microsoft.Network/networkSecurityGroups/securityRules@2023-09-01' = if(usePort443) {
  parent: nsg
  name: 'Allow443Inbound'
  properties: {
    description: 'Allow ALL web traffic into 443. (If you wanted to allow-list specific IPs, this is where you\'d list them.)'
    protocol: 'Tcp'
    sourcePortRange: '*'
    sourceAddressPrefix: '*'
    destinationPortRange: '443'
    destinationAddressPrefix: '*'
    direction: 'Inbound'
    access: 'Allow'
    priority: 610
  }
}

output id string = nsg.id

/// network parameters ///
param region string
param nsgName string
param vnetName string
param vnetAddressSpace string
param subnetName string
param subnetAddressSpace string
param dnsServer1 string
param dnsServer2 string

/// network resources ///
resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  location: region
  name: nsgName
}

resource net 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  location: region
  name: vnetName
  properties: {
    addressSpace:{
      addressPrefixes:[
        vnetAddressSpace
      ]
    }
    subnets:[
      {
        name: subnetName
        properties:{
          addressPrefix: subnetAddressSpace
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
    dhcpOptions: {
      dnsServers: [
        dnsServer1
        dnsServer2
      ]
    }
  }
}

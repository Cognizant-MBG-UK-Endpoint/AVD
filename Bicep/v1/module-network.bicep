/// network parameters ///
param region string
param nsgNameWvdHp1 string
param nsgNameWvdHp2 string
param vnetName string
param vnetAddressSpace string
param subnetNameWvdHp1 string
param subnetAddressSpaceWvdHp1 string
param subnetNameWvdHp2 string
param subnetAddressSpaceWvdHp2 string
param dnsServer1 string
param dnsServer2 string

/// network resources ///
resource nsghp1 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  location: region
  name: nsgNameWvdHp1
}

resource nsghp2 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  location: region
  name: nsgNameWvdHp2
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
        name: subnetNameWvdHp1
        properties:{
          addressPrefix: subnetAddressSpaceWvdHp1
          networkSecurityGroup: {
            id: nsghp1.id
          }
        }
      }
      {
        name: subnetNameWvdHp2
        properties:{
          addressPrefix: subnetAddressSpaceWvdHp2
          networkSecurityGroup: {
            id: nsghp2.id
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

/// Location ///
param location string

/// Parameters: Virtual Network ///
param vnetName string
param vnetAddressSpace string
param dnsServer1 string
param dnsServer2 string

/// Parameters: Subnet 1 ///
param subnet1Name string
param subnet1AddressSpace string

/// Parameters: Subnet 2 ///
param subnet2Name string
param subnet2AddressSpace string

/// Parameters: Network Security Group 1 ///
param nsg1Name string

/// Parameters: Network Security Group 2 //
param nsg2Name string

/// Resource: Network Security Group 1 ///
resource nsg1 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  location: location
  name: nsg1Name
}

/// Resource: Network Security Group 2 ///
resource nsg2 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  location: location
  name: nsg2Name
}

/// Resource: Virtual Network ///
resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  location: location
  name: vnetName
  properties: {
    addressSpace:{
      addressPrefixes:[
        vnetAddressSpace
      ]
    }
    subnets:[
      {
        name: subnet1Name
        properties:{
          addressPrefix: subnet1AddressSpace
          privateEndpointNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: nsg1.id
          }
        }
      }
      {
        name: subnet2Name
        properties:{
          addressPrefix: subnet2AddressSpace
          privateEndpointNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: nsg2.id
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

/// Output: Virtual Network ///
output subnet1Id string = vnet.properties.subnets[0].id
output subnet2Id string = vnet.properties.subnets[1].id

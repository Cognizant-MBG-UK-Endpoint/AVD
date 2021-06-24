/// network security group parameters ///
param region string
param nsgName string

/// network security group resources ///
resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  location: region
  name: nsgName
  properties:{
    securityRules:[
      {
        name: 'Allow-Out-WindowsVirtualDesktop-TCP-443'
        properties:{
          description: 'Allow outbound access on port TCP 443 to the Windows Virtual Desktop service required URL list.'
          priority: 100
          access: 'Allow'
          direction:'Outbound'
          protocol:'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '443'
          destinationAddressPrefix: 'WindowsVirtualDesktop'
        }
      }
      {
        name: 'Allow-Out-AzureCloud-TCP-443'
        properties:{
          description: 'Allow outbound access on port TCP 443 to the Windows Virtual Desktop service required URL list.'
          priority: 200
          access: 'Allow'
          direction:'Outbound'
          protocol:'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
        }
      }
      {
        name: 'Allow-Out-WVD-TCP-1688'
        properties: {
          description: 'Allow outbound access on port TCP 1688 to the Windows Virtual Desktop service required URL list.'
          priority: 300
          access: 'Allow'
          direction:'Outbound'
          protocol:'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '1688'
          destinationAddressPrefix: 'Internet'
        }
      }
      {
        name: 'Allow-Out-WVD-TCP-80'
        properties:{
         description:  'Allow outbound access on port TCP 80 to the Windows Virtual Desktop service required URL list.'
         priority: 400
         access:'Allow'
         direction:'Outbound'
         protocol: 'Tcp'
         sourcePortRange: '*'
         sourceAddressPrefix: 'VirtualNetwork'
         destinationPortRange: '80'
         destinationAddressPrefixes:[
           '169.254.169.254'
           '168.63.129.16'
         ]
        }
      }
      {
        name: 'Allow-Out-AzureActiveDirectory-TCP-80-443'
        properties:{
          description: 'Allow outbound access on port TCP 80 and 443 to the Azure Active Directory URL list.'
          priority: 500
          access: 'Allow'
          direction:'Outbound'
          protocol:'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '80'
            '443'
          ]
          destinationAddressPrefix: 'AzureActiveDirectory'
        }
      }
    ]
  }
}

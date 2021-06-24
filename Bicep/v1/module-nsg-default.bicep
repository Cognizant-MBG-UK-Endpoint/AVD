/// network security group parameters ///
param region string
param nsgName string

/// network security group resources ///
resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  location: region
  name: nsgName
}

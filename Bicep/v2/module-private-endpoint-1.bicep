/// Location ///
param location string

/// Parameters: Private Endpoint 1 ///
param privatendpoint1Name string
param subnet1Id string
param privatelink1Name string
param sa1Id string

/// Resource: Private Endpoint 1 ///
resource pvtend1 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  location: location
  name: privatendpoint1Name
  properties: {
    subnet: {
      id: subnet1Id
    }
    privateLinkServiceConnections: [
      {
        name: privatelink1Name
        properties: {
          privateLinkServiceId: sa1Id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

/// Location ///
param location string

/// Parameters: Workspace Test ///
param wstestName string
param wstestFriendlyName string
param wstestDescription string
param wstestApplicationGroupReference1 string

/// Resource: Workspace Test ///
resource wvdwstest 'Microsoft.DesktopVirtualization/workspaces@2021-01-14-preview' = {
  location: location
  name: wstestName
  properties:{
    friendlyName: wstestFriendlyName
    description: wstestDescription
    applicationGroupReferences:[
      wstestApplicationGroupReference1
    ]
  }
}

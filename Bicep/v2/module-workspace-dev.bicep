/// Location ///
param location string

/// Parameters: Workspace Dev ///
param wsdevName string
param wsdevFriendlyName string
param wsdevDescription string
param wsdevApplicationGroupReference1 string

/// Resource: Workspace Dev ///
resource wsdev 'Microsoft.DesktopVirtualization/workspaces@2021-01-14-preview' = {
  location: location
  name: wsdevName
  properties:{
    friendlyName: wsdevFriendlyName
    description: wsdevDescription
    applicationGroupReferences:[
      wsdevApplicationGroupReference1
    ]
  }
}

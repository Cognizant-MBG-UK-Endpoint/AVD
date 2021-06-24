/// Location ///
param location string

/// Parameters: Workspace Prod ///
param wsprodName string
param wsprodFriendlyName string
param wsprodDescription string
param wsprodApplicationGroupReference1 string

/// Resource: Workspace Prod ///
resource wsprod 'Microsoft.DesktopVirtualization/workspaces@2021-01-14-preview' = {
  location: location
  name: wsprodName
  properties:{
    friendlyName: wsprodFriendlyName
    description: wsprodDescription
    applicationGroupReferences:[
      wsprodApplicationGroupReference1
    ]
  }
}

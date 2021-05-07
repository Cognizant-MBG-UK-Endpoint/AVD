/// wvd dev workspace parameters ///
param wvdHp1MetadataRegion string
param wvdDevWorkspaceName string
param wvdDevWorkspaceFriendlyName string
param wvdDevWorkspaceDescription string
param wvdDevWorkspaceAppGroupRef string

/// wvd dev workspace resources ///
resource wvdwsdev 'Microsoft.DesktopVirtualization/workspaces@2021-01-14-preview' = {
  location: wvdHp1MetadataRegion
  name: wvdDevWorkspaceName
  properties:{
    friendlyName: wvdDevWorkspaceFriendlyName
    description: wvdDevWorkspaceDescription
    applicationGroupReferences:[
      wvdDevWorkspaceAppGroupRef
    ]
  }
}

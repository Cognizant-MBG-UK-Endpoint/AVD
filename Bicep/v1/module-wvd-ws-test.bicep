/// wvd test workspace parameters ///
param wvdHp1MetadataRegion string
param wvdTestWorkspaceName string
param wvdTestWorkspaceFriendlyName string
param wvdTestWorkspaceDescription string
param wvdTestWorkspaceAppGroupRef string

/// wvd test workspace resources ///
resource wvdwstest 'Microsoft.DesktopVirtualization/workspaces@2021-01-14-preview' = {
  location: wvdHp1MetadataRegion
  name: wvdTestWorkspaceName
  properties:{
    friendlyName: wvdTestWorkspaceFriendlyName
    description: wvdTestWorkspaceDescription
    applicationGroupReferences:[
      wvdTestWorkspaceAppGroupRef
    ]
  }
}

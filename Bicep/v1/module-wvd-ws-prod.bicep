/// wvd prod workspace parameters ///
param wvdHp1MetadataRegion string
param wvdProdWorkspaceName string
param wvdProdWorkspaceFriendlyName string
param wvdProdWorkspaceDescription string
param wvdProdWorkspaceAppGroupRef string

/// wvd prod workspace resources ///
resource wvdwsprod 'Microsoft.DesktopVirtualization/workspaces@2021-01-14-preview' = {
  location: wvdHp1MetadataRegion
  name: wvdProdWorkspaceName
  properties:{
    friendlyName: wvdProdWorkspaceFriendlyName
    description: wvdProdWorkspaceDescription
    applicationGroupReferences:[
      wvdProdWorkspaceAppGroupRef
    ]
  }
}

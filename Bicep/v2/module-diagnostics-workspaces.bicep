/// Parameters: Diagnostics ///
param workspaceId string
param wsprodName string
param wstestName string
param wsdevName string

/// Resource: Existing ///
resource wsprod 'Microsoft.DesktopVirtualization/workspaces@2021-03-09-preview' existing = {
  name: wsprodName
}

resource wstest 'Microsoft.DesktopVirtualization/workspaces@2021-03-09-preview' existing = {
  name: wstestName
}

resource wsdev 'Microsoft.DesktopVirtualization/workspaces@2021-03-09-preview' existing = {
  name: wsdevName
}

/// Resource: Diagnostics Workspace Prod ///
resource diagwsprod 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diagwsprod'
  scope: wsprod
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
      {
        category: 'Feed'
        enabled: true
      }
    ]
  }
}

/// Resource: Diagnostics Workspace Test ///
resource diagwstest 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diagwstest'
  scope: wstest
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
      {
        category: 'Feed'
        enabled: true
      }
    ]
  }
}

/// Resource: Diagnostics Workspace Dev ///
resource diagwsdev 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diagwsdev'
  scope: wsdev
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
      {
        category: 'Feed'
        enabled: true
      }
    ]
  }
}

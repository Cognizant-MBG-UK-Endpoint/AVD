/// Parameters: Diagnostics ///
param workspaceId string
param hp1prodName string

/// Resource: Existing ///
resource hp1prod 'Microsoft.DesktopVirtualization/hostPools@2021-03-09-preview' existing = {
  name: hp1prodName
}

/// Resource: Diagnostics Host Pool 1 Prod ///
resource diaghp1prod 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diaghp1prod'
  scope: hp1prod
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
        category: 'Connection'
        enabled: true
      }
      {
        category: 'HostRegistration'
        enabled: true
      }
      {
        category: 'AgentHealthStatus'
        enabled: true
      }
    ]
  }
}

/// Parameters: Diagnostics ///
param workspaceId string
param hp1devName string

/// Resource: Existing ///
resource hp1dev 'Microsoft.DesktopVirtualization/hostPools@2021-03-09-preview' existing = {
  name: hp1devName
}

/// Resource: Diagnostics Host Pool 1 Prod ///
resource diaghp1dev 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diaghp1dev'
  scope: hp1dev
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

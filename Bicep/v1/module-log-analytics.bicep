/// log analytics parameters ///
param region string
param logAnalyticsWorkspaceName string 
param logAnalyticsWorkspaceRetention int

/// log analytics resources ///
resource log 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  location: region
  name: logAnalyticsWorkspaceName
  properties:{
    sku:{
      name: 'PerGB2018'
    }
    retentionInDays: logAnalyticsWorkspaceRetention
  }
}

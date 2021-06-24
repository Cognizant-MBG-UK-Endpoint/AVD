/// Location ///
param location string

/// Parameters: Log Analytics ///
param logName string 
param retentionInDays int

/// Resource: Log Analytics ///
resource log 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  location: location
  name: logName
  properties:{
    sku:{
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
  }
}

/// Output: Log Analytics ///
output logid string = log.id

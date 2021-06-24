/// Location ///
param location string

/// Parameters: Storage Account 1 ///
param sa1Name string
param sa1Kind string
param sa1Sku string
param sa1SupportsHttpsTrafficOnly bool
param sa1AllowBlobPublicAccess bool
param sa1MinimumTlsVersion string
param fs1sa1Name string
param fs1sa1Quota int

/// Variables: Storage Account 1 ///
var fileshare1sa1Name = '${sa1.name}/default/${fs1sa1Name}'

/// Resource: Storage Account 1 ///
resource sa1 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  location: location
  name: sa1Name
  kind: sa1Kind
  sku: {
    name: sa1Sku
  }
  properties:{
    supportsHttpsTrafficOnly: sa1SupportsHttpsTrafficOnly
    allowBlobPublicAccess: sa1AllowBlobPublicAccess
    minimumTlsVersion: sa1MinimumTlsVersion
  }
}

/// Resource: File Share 1 ///
resource sa1fs1 'Microsoft.Storage/storageAccounts/fileServices/shares@2020-08-01-preview' = {
  name: fileshare1sa1Name
  properties:{
    shareQuota: fs1sa1Quota
  }
}

/// Output: Storage Account 1 ///
output sa1Id string = sa1.id

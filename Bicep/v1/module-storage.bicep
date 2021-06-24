/// storage account parameters ///
param region string
param storageAccountName string
param storageAccountKind string
param storageAccountSku string
param storageSecureTransfer bool
param storagePublicAccess bool
param storageTlsVersion string
param fileShare string
param fileShareQuota int

/// storage account variables ///
var fileShareName = '${sa.name}/default/${fileShare}'

/// storage account resources ///
resource sa 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  location: region
  name: storageAccountName
  kind: storageAccountKind
  sku: {
    name: storageAccountSku
  }
  properties:{
    supportsHttpsTrafficOnly: storageSecureTransfer
    allowBlobPublicAccess: storagePublicAccess
    minimumTlsVersion: storageTlsVersion
  }
}

resource fs 'Microsoft.Storage/storageAccounts/fileServices/shares@2020-08-01-preview' = {
  name: fileShareName
  properties:{
    shareQuota: fileShareQuota
  }
}

/// scope ///
targetScope = 'subscription'

/// region parameters ///
param region string = 'UK South'

/// resource group parameters ///
param resourceGroupNetwork string = ''
param resourceGroupWvdCore string = ''
param resourceGroupWvdHp1Prod string = ''
param resourceGroupWvdHp1Test string = ''
param resourceGroupWvdHp1Dev string = ''

/// network parameters ///
param vnetName string = ''
param vnetAddressSpace string = ''
param dnsServer1 string = ''
param dnsServer2 string = ''
param subnetNameWvdHp1 string = ''
param subnetAddressSpaceWvdHp1 string = ''
param nsgNameWvdHp1 string = ''
param subnetNameWvdHp2 string = ''
param subnetAddressSpaceWvdHp2 string = ''
param nsgNameWvdHp2 string = ''

/// storage parameters ///
param storageAccountName string = '' // Name must be lower case, only contain alphanumerical charaters and be globally unique
param storageAccountKind string = 'FileStorage'
param storageAccountSku string = 'Premium_LRS' // Premium_LRS or Premium_ZRS
param storageSecureTransfer bool = true // true or false
param storagePublicAccess bool = false // true or false
param storageTlsVersion string = 'TLS1_2' // 'TLS1_0', 'TLS1_1', 'TLS1_2'
param fileShare string = 'fslogix' // Name must be lower case
param fileShareQuota int = 100

/// wvd host pool 1 parameters ///
param wvdHp1MetadataRegion string = '' // Central US, East US, East US 2, North Central US, North Europe, South Central US, West Central US, West Europe, West US, West US 2
param wvdHp1HostPoolType string = '' // Pooled or Personal
param wvdHp1MaxSessions int = 8
param wvdHp1LoadBalancerType string = '' // BreadthFirst, DepthFirst or Persistent
param wvdHp1PreferredAppGroupType string = '' // Desktop or RailApplications
param wvdHp1BaseTime string = utcNow('u')
param wvdHp1TokenExpirationTime string = 'P30D'
param wvdHp1AppGroupType string = '' // Desktop or RemoteApp

param wvdHp1ProdHostPoolName string = ''
param wvdHp1ProdHostPoolFriendlyName string = ''
param wvdHp1ProdHostPoolDescription string = ''
param wvdHp1ProdAppGroupName string = ''
param wvdHp1ProdAppGroupFriendlyName string = ''
param wvdHp1ProdAppGroupDescription string = ''

param wvdHp1TestHostPoolName string = ''
param wvdHp1TestHostPoolFriendlyName string = ''
param wvdHp1TestHostPoolDescription string = ''
param wvdHp1TestAppGroupName string = ''
param wvdHp1TestAppGroupFriendlyName string = ''
param wvdHp1TestAppGroupDescription string = ''

param wvdHp1DevHostPoolName string = ''
param wvdHp1DevHostPoolFriendlyName string = ''
param wvdHp1DevHostPoolDescription string = ''
param wvdHp1DevAppGroupName string = ''
param wvdHp1DevAppGroupFriendlyName string = ''
param wvdHp1DevAppGroupDescription string = ''

/// wvd workspace parameters ///
param wvdProdWorkspaceName string = ''
param wvdProdWorkspaceFriendlyName string = ''
param wvdProdWorkspaceDescription string = ''

param wvdTestWorkspaceName string = ''
param wvdTestWorkspaceFriendlyName string = ''
param wvdTestWorkspaceDescription string = ''

param wvdDevWorkspaceName string = ''
param wvdDevWorkspaceFriendlyName string = ''
param wvdDevWorkspaceDescription string = ''

/// wvd monitoring parameters ///
param logAnalyticsWorkspaceName string = ''
param logAnalyticsWorkspaceRetention int = 30

/// shared image gallery parameters ///
param sigName string = '' // Name can only contain alphanumerical and underscores
param imgName string = ''
param hypvGen string = '' // V1 or V2
param imgPub string = 'Custom'
param imgOff string = 'Windows'
param imgSku string = '20H2-ms' // 2004, 2004-ms, 20H2 or 20H2-ms

/// resource group resources ///
resource rgnet 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourceGroupNetwork
  location: region
}

resource rgwvdprd 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourceGroupWvdHp1Prod
  location: region
}

resource rgwvdval 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourceGroupWvdHp1Test
  location: region
}

resource rgwvddev 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourceGroupWvdHp1Dev
  location: region
}

resource rgwvdcore 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourceGroupWvdCore
  location: region
}

/// network resources ///
module net './module-network.bicep' = {
  scope: resourceGroup(rgnet.name)
  name: 'net'
  params:{
    region : region
    vnetName : vnetName
    vnetAddressSpace : vnetAddressSpace
    dnsServer1 : dnsServer1
    dnsServer2 : dnsServer2
    subnetNameWvdHp1 : subnetNameWvdHp1
    subnetAddressSpaceWvdHp1 : subnetAddressSpaceWvdHp1
    nsgNameWvdHp1 : nsgNameWvdHp1
    subnetNameWvdHp2 : subnetNameWvdHp2
    subnetAddressSpaceWvdHp2 : subnetAddressSpaceWvdHp2
    nsgNameWvdHp2 : nsgNameWvdHp2
  }
}

/// storage account resources ///
module stg './module-storage.bicep' = {
  scope: resourceGroup(rgwvdcore.name)
  name: 'stg'
  params:{
    region : region
    storageAccountName : storageAccountName
    storageAccountKind : storageAccountKind
    storageAccountSku : storageAccountSku
    storageSecureTransfer : storageSecureTransfer
    storagePublicAccess : storagePublicAccess
    storageTlsVersion : storageTlsVersion
    fileShare : fileShare
    fileShareQuota : fileShareQuota
  }
}

/// wvd host pool 1 prod resources ///
module wvdhp1prod './module-wvd-hp1-prod.bicep' = {
  scope: resourceGroup(rgwvdprd.name)
  name: 'wvdhp1prod'
  params: {
    wvdHp1MetadataRegion: wvdHp1MetadataRegion
    wvdHp1ProdHostPoolName : wvdHp1ProdHostPoolName
    wvdHp1ProdHostPoolFriendlyName : wvdHp1ProdHostPoolFriendlyName
    wvdHp1ProdHostPoolDescription : wvdHp1ProdHostPoolDescription
    wvdHp1HostPoolType : wvdHp1HostPoolType
    wvdHp1MaxSessions : wvdHp1MaxSessions
    wvdHp1LoadBalancerType: wvdHp1LoadBalancerType
    wvdHp1PreferredAppGroupType : wvdHp1PreferredAppGroupType
    wvdHp1BaseTime : wvdHp1BaseTime
    wvdHp1TokenExpirationTime : wvdHp1TokenExpirationTime
    wvdHp1AppGroupType : wvdHp1AppGroupType
    wvdHp1ProdAppGroupName : wvdHp1ProdAppGroupName
    wvdHp1ProdAppGroupFriendlyName : wvdHp1ProdAppGroupFriendlyName
    wvdHp1ProdAppGroupDescription : wvdHp1ProdAppGroupDescription
  }
}

/// wvd host pool 1 test resources ///
module wvdhp1test './module-wvd-hp1-test.bicep' = {
  scope: resourceGroup(rgwvdval.name)
  name: 'wvdhp1test'
  params: {
    wvdHp1MetadataRegion: wvdHp1MetadataRegion
    wvdHp1TestHostPoolName : wvdHp1TestHostPoolName
    wvdHp1TestHostPoolFriendlyName : wvdHp1TestHostPoolFriendlyName
    wvdHp1TestHostPoolDescription : wvdHp1TestHostPoolDescription
    wvdHp1HostPoolType : wvdHp1HostPoolType
    wvdHp1MaxSessions : wvdHp1MaxSessions
    wvdHp1LoadBalancerType: wvdHp1LoadBalancerType
    wvdHp1PreferredAppGroupType : wvdHp1PreferredAppGroupType
    wvdHp1BaseTime : wvdHp1BaseTime
    wvdHp1TokenExpirationTime : wvdHp1TokenExpirationTime
    wvdHp1AppGroupType : wvdHp1AppGroupType
    wvdHp1TestAppGroupName : wvdHp1TestAppGroupName
    wvdHp1TestAppGroupFriendlyName : wvdHp1TestAppGroupFriendlyName
    wvdHp1TestAppGroupDescription : wvdHp1TestAppGroupDescription
  }
}

/// wvd host pool 1 dev resources ///
module wvdhp1dev './module-wvd-hp1-dev.bicep' = {
  scope: resourceGroup(rgwvddev.name)
  name: 'wvdhp1dev'
  params: {
    wvdHp1MetadataRegion: wvdHp1MetadataRegion
    wvdHp1DevHostPoolName : wvdHp1DevHostPoolName 
    wvdHp1DevHostPoolFriendlyName : wvdHp1DevHostPoolFriendlyName
    wvdHp1DevHostPoolDescription : wvdHp1DevHostPoolDescription
    wvdHp1HostPoolType : wvdHp1HostPoolType
    wvdHp1MaxSessions : wvdHp1MaxSessions
    wvdHp1LoadBalancerType: wvdHp1LoadBalancerType
    wvdHp1PreferredAppGroupType : wvdHp1PreferredAppGroupType
    wvdHp1BaseTime : wvdHp1BaseTime
    wvdHp1TokenExpirationTime : wvdHp1TokenExpirationTime
    wvdHp1AppGroupType : wvdHp1AppGroupType
    wvdHp1DevAppGroupName : wvdHp1DevAppGroupName
    wvdHp1DevAppGroupFriendlyName : wvdHp1DevAppGroupFriendlyName 
    wvdHp1DevAppGroupDescription : wvdHp1DevAppGroupDescription
  }
}

/// wvd prod workspace resources ///
module wvdwsprod 'module-wvd-ws-prod.bicep' = {
  scope: resourceGroup(rgwvdcore.name)
  name: 'wvdwsprod'
  params: {
    wvdHp1MetadataRegion : wvdHp1MetadataRegion
    wvdProdWorkspaceName : wvdProdWorkspaceName
    wvdProdWorkspaceFriendlyName : wvdProdWorkspaceFriendlyName
    wvdProdWorkspaceDescription : wvdProdWorkspaceDescription
    wvdProdWorkspaceAppGroupRef : wvdhp1prod.outputs.wvdagprod
  }
}

/// wvd test workspace resources ///
module wvdwstest 'module-wvd-ws-test.bicep' = {
  scope: resourceGroup(rgwvdcore.name)
  name: 'wvdwstest'
  params: {
    wvdHp1MetadataRegion : wvdHp1MetadataRegion
    wvdTestWorkspaceName : wvdTestWorkspaceName
    wvdTestWorkspaceFriendlyName : wvdTestWorkspaceFriendlyName
    wvdTestWorkspaceDescription : wvdTestWorkspaceDescription
    wvdTestWorkspaceAppGroupRef : wvdhp1test.outputs.wvdagtest
  }
}

/// wvd dev workspace resources ///
module wvdwsdev 'module-wvd-ws-dev.bicep' = {
  scope: resourceGroup(rgwvdcore.name)
  name: 'wvdwsdev'
  params: {
    wvdHp1MetadataRegion : wvdHp1MetadataRegion
    wvdDevWorkspaceName : wvdDevWorkspaceName
    wvdDevWorkspaceFriendlyName : wvdDevWorkspaceFriendlyName
    wvdDevWorkspaceDescription : wvdDevWorkspaceDescription
    wvdDevWorkspaceAppGroupRef : wvdhp1dev.outputs.wvdagdev
  }
}

/// log analytics resources ///
module logs './module-log-analytics.bicep' = {
  scope: resourceGroup(rgwvdcore.name)
  name: 'logs'
  params:{
    region : region
    logAnalyticsWorkspaceName : logAnalyticsWorkspaceName
    logAnalyticsWorkspaceRetention : logAnalyticsWorkspaceRetention
  }
}

/// shared image gallery resources ///
module sig './module-sig.bicep' = {
  scope: resourceGroup(rgwvdcore.name)
  name: 'sig'
  params:{
    region : region
    sigName : sigName
    hypvGen : hypvGen
    imgName : imgName
    imgPub : imgPub
    imgOff : imgOff
    imgSku : imgSku
  }
}


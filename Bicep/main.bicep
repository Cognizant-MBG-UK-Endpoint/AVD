/// scope ///
targetScope = 'subscription'

/// region parameters ///
param region string = 'UK South'

/// resource group parameters ///
param resourceGroupNetwork string = 'rg-vnet-wvd-uks'
param resourceGroupWvdCore string = 'rg-wvd-core-uks'
param resourceGroupWvdHp1Prod string = 'rg-wvd-hp1-prod-uks'
param resourceGroupWvdHp1Test string = 'rg-wvd-hp1-test-uks'
param resourceGroupWvdHp1Dev string = 'rg-wvd-hp1-dev-uks'

/// network parameters ///
param nsgName string = 'nsg-wvd-uks'
param vnetName string = 'vnet-wvd-uks'
param vnetAddressSpace string = '10.1.0.0/16'
param subnetName string = 'subnet-wvd-prod'
param subnetAddressSpace string = '10.1.0.0/24'
param dnsServer1 string = '10.0.0.4'
param dnsServer2 string = '10.0.0.5'

/// storage parameters ///
param storageAccountName string = 'storageukswvd001' // Name must be lower case, only contain alphanumerical charaters and be globally unique
param storageAccountKind string = 'FileStorage'
param storageAccountSku string = 'Premium_LRS' // Premium_LRS or Premium_ZRS
param storageSecureTransfer bool = true // true or false
param storagePublicAccess bool = false // true or false
param storageTlsVersion string = 'TLS1_2' // 'TLS1_0', 'TLS1_1', 'TLS1_2'
param fileShare string = 'fslogix' // Name must be lower case
param fileShareQuota int = 100

/// wvd host pool 1 parameters ///
param wvdHp1MetadataRegion string = 'North Europe' // Central US, East US, East US 2, North Central US, North Europe, South Central US, West Central US, West Europe, West US, West US 2
param wvdHp1HostPoolType string = 'Pooled' // Pooled or Personal
param wvdHp1MaxSessions int = 8
param wvdHp1LoadBalancerType string = 'DepthFirst' // BreadthFirst, DepthFirst or Persistent
param wvdHp1PreferredAppGroupType string = 'Desktop' // Desktop or RailApplications
param wvdHp1BaseTime string = utcNow('u')
param wvdHp1TokenExpirationTime string = 'P30D'
param wvdHp1AppGroupType string = 'Desktop' // Desktop or RemoteApp

param wvdHp1ProdHostPoolName string = 'wvd-hp1-prod'
param wvdHp1ProdHostPoolFriendlyName string = 'Host pool 1 prod'
param wvdHp1ProdHostPoolDescription string = 'Host pool 1 production environment'
param wvdHp1ProdAppGroupName string = 'wvd-hp1-prod-dag'
param wvdHp1ProdAppGroupFriendlyName string = 'Host pool 1 prod desktop app group'
param wvdHp1ProdAppGroupDescription string = 'Host pool 1 production environment desktop application group'

param wvdHp1TestHostPoolName string = 'wvd-hp1-test'
param wvdHp1TestHostPoolFriendlyName string = 'Host pool 1 test'
param wvdHp1TestHostPoolDescription string = 'Host pool 1 test environment'
param wvdHp1TestAppGroupName string = 'wvd-hp1-test-dag'
param wvdHp1TestAppGroupFriendlyName string = 'Host pool 1 test desktop app group'
param wvdHp1TestAppGroupDescription string = 'Host pool 1 test environment desktop application group'

param wvdHp1DevHostPoolName string = 'wvd-hp1-dev'
param wvdHp1DevHostPoolFriendlyName string = 'Host pool 1 dev'
param wvdHp1DevHostPoolDescription string = 'Host pool 1 dev environment'
param wvdHp1DevAppGroupName string = 'wvd-hp1-dev-dag'
param wvdHp1DevAppGroupFriendlyName string = 'Host pool 1 dev desktop app group'
param wvdHp1DevAppGroupDescription string = 'Host pool 1 dev environment desktop application group'

/// wvd workspace parameters ///
param wvdProdWorkspaceName string = 'wvd-ws-prod'
param wvdProdWorkspaceFriendlyName string = 'Prod workspace'
param wvdProdWorkspaceDescription string = 'Production environment workspace'

param wvdTestWorkspaceName string = 'wvd-ws-test'
param wvdTestWorkspaceFriendlyName string = 'Test workspace'
param wvdTestWorkspaceDescription string = 'Test environment workspace'

param wvdDevWorkspaceName string = 'wvd-ws-dev'
param wvdDevWorkspaceFriendlyName string = 'Dev workspace'
param wvdDevWorkspaceDescription string = 'Development environment workspace'

/// wvd monitoring parameters ///
param logAnalyticsWorkspaceName string = 'log-wvd-uks'
param logAnalyticsWorkspaceRetention int = 30

/// shared image gallery parameters ///
param sigName string = 'WindowsVirtualDesktop' // Name can only contain alphanumerical and underscores
param imgName string = 'img-wvd-hp1'
param hypvGen string = 'V1' // V1 or V2
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
    nsgName : nsgName
    vnetName : vnetName
    vnetAddressSpace : vnetAddressSpace
    subnetName : subnetName
    subnetAddressSpace : subnetAddressSpace
    dnsServer1 : dnsServer1
    dnsServer2 : dnsServer2
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

/// Target Scope ///
targetScope = 'subscription'

/// Parameters: Location ///
param location string = '' // Canada Central, Canada East, Central US, East US, East US 2, North Central US, North Europe, South Central US, UK South, UK West, West Central US, West Europe, West US, West US 2

/// Parameters: Resource Groups ///
param rgNetwork string = ''
param rgCore string = ''
param rgHp1Prod string = ''
param rgHp1Test string = ''
param rgHp1Dev string = ''

/// Parameters: Virtual Network ///
param vnetName string = ''
param vnetAddressSpace string = ''
param dnsServer1 string = ''
param dnsServer2 string = ''

/// Parameters: Subnet 1 ///
param subnet1Name string = ''
param subnet1AddressSpace string = ''

/// Parameters: Subnet 2 ///
param subnet2Name string = ''
param subnet2AddressSpace string = ''

/// Parameters: Network Security Group 1 ///
param nsg1Name string = ''

/// Parameters: Network Security Group 2 ///
param nsg2Name string = ''

/// Parameters: Storage Account 1 ///
param sa1Name string = '${''}${uniqueString(rgCore)}' // Name must be lower case, only contain alphanumerical charaters, and be globally unique
param sa1Kind string = 'FileStorage' // FileStorage
param sa1Sku string = '' // Premium_LRS or Premium_ZRS
param sa1SupportsHttpsTrafficOnly bool = true // true or false
param sa1AllowBlobPublicAccess bool = false // true or false
param sa1MinimumTlsVersion string = 'TLS1_2' // 'TLS1_0', 'TLS1_1', 'TLS1_2'

/// Parameters: Private Endpoint 1 ///
param privatendpoint1Name string = ''
param privatelink1Name string = ''

/// Parameters: Storage Account 1, File Share 1 ///
param fs1sa1Name string = 'fslogix' // Name must be lower case
param fs1sa1Quota int = 100

/// Parameters: Host Pool 1 Prod ///
param hp1prodName string = ''
param hp1prodFriendlyName string = ''
param hp1prodDescription string = 'Host pool 1 Production environment'
param hp1prodHostPoolType string = 'Pooled' // Pooled or Personal
param hp1prodMaxSessionLimit int = 8
param hp1prodLoadBalancerType string = 'DepthFirst' // BreadthFirst, DepthFirst or Persistent
param hp1prodPreferredAppGroupType string = 'Desktop' // Desktop or RailApplications
param hp1prodBaseTime string = utcNow('u')
param hp1prodTokenExpirationTime string = 'P1D'

/// Parameters: Host Pool 1 Prod; App Group 1 ///
param ag1hp1prodName string = ''
param ag1hp1prodFriendlyName string = ''
param ag1hp1prodDescription string = 'Host pool 1 Production environment; application group 1'
param ag1hp1prodApplicationGroupType string = 'Desktop' // Desktop or RemoteApp

/// Parameters: Host Pool 1 Test ///
param hp1testName string = ''
param hp1testFriendlyName string = ''
param hp1testDescription string = 'Host pool 1 Test environment'
param hp1testHostPoolType string = 'Pooled' // Pooled or Personal
param hp1testMaxSessionLimit int = 8
param hp1testLoadBalancerType string = 'DepthFirst' // BreadthFirst, DepthFirst or Persistent
param hp1testPreferredAppGroupType string = 'Desktop' // Desktop or RailApplications
param hp1testBaseTime string = utcNow('u')
param hp1testTokenExpirationTime string = 'P1D'

/// Parameters: Host Pool 1 Test; App Group 1 ///
param ag1hp1testName string = ''
param ag1hp1testFriendlyName string = ''
param ag1hp1testDescription string = 'Host pool 1 Test environment; application group 1'
param ag1hp1testApplicationGroupType string = 'Desktop' // Desktop or RemoteApp

/// Parameters: Host Pool 1 Dev ///
param hp1devName string = ''
param hp1devFriendlyName string = ''
param hp1devDescription string = 'Host pool 1 Development environment'
param hp1devValidationEnvironment bool = false
param hp1devHostPoolType string = 'Pooled' // Pooled or Personal
param hp1devMaxSessionLimit int = 8
param hp1devLoadBalancerType string = 'DepthFirst' // BreadthFirst, DepthFirst or Persistent
param hp1devPreferredAppGroupType string = 'Desktop' // Desktop or RailApplications
param hp1devBaseTime string = utcNow('u')
param hp1devTokenExpirationTime string = 'P1D'

/// Parameters: Host Pool 1 Dev; App Group 1 ///
param ag1hp1devName string = ''
param ag1hp1devFriendlyName string = ''
param ag1hp1devDescription string = 'Host pool 1 Development environment; application group 1'
param ag1hp1devApplicationGroupType string = 'Desktop' // Desktop or RemoteApp

/// Parameters: Workspace Prod ///
param wsprodName string = ''
param wsprodFriendlyName string = ''
param wsprodDescription string = 'Production environment workspace'

/// Parameters: Workspace Test ///
param wstestName string = ''
param wstestFriendlyName string = ''
param wstestDescription string = 'Test environment workspace'

/// Parameters: Workspace Dev ///
param wsdevName string = ''
param wsdevFriendlyName string = ''
param wsdevDescription string = 'Development environment workspace'

/// Parameters: Log Analytics ///
param logName string = ''
param retentionInDays int = 30

/// Parameters: Shared Image Gallery ///
param sigName string = 'AzureVirtualDesktop' // Must only contain alphanumerical and underscores

/// Parameters: Image Definition 1 ///
param img1Name string = ''
param img1hyperVGeneration string = '' // V1 or V2
param img1Publisher string = 'Custom'
param img1Offer string = 'Windows'
param img1Sku string = '20H2-ms' // 2004, 2004-ms, 20H2 or 20H2-ms

/// Parameters: User Assigned Managed Identity ///
param uamiName string = ''

/// Parameters: Role Definition ///
param roleName string = '${'AIB'}${utcNow()}'
param roleDescription string = 'Azure Image Builder for AVD Custom Role Definition'

/// Parameters: Image Template ///
param imgtempName string = ''
param vmSize string = 'Standard_D2s_v3'
param osDiskSizeGB int = 127
param imagePublisher string = 'MicrosoftWindowsDesktop'
param imageOffer string = 'Windows-10'
param imageSKU string = '20h2-evd'
param runOutputName string = 'Win10ms'

/// Module: Resource groups ///
resource rgnet 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgNetwork
  location: location
}

resource rgcore 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgCore
  location: location
}

resource rghp1prod 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgHp1Prod
  location: location
}

resource rghp1test 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgHp1Test
  location: location
}

resource rghp1dev 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgHp1Dev
  location: location
}

/// Module: Virtual Network ///
module vnet './module-virtual-network.bicep' = {
  scope: resourceGroup(rgnet.name)
  name: 'vnet'
  params:{
    location: location
    vnetName: vnetName
    vnetAddressSpace: vnetAddressSpace
    dnsServer1: dnsServer1
    dnsServer2: dnsServer2
    subnet1Name: subnet1Name
    subnet1AddressSpace: subnet1AddressSpace
    nsg1Name: nsg1Name
    subnet2Name: subnet2Name
    subnet2AddressSpace: subnet2AddressSpace
    nsg2Name: nsg2Name
  }
}

/// Module: Storage Account 1 ///
module sa1 './module-storage-account-1.bicep' = {
  scope: resourceGroup(rgcore.name)
  name: 'sa1'
  params:{
    location: location
    sa1Name: sa1Name
    sa1Kind: sa1Kind
    sa1Sku: sa1Sku
    sa1SupportsHttpsTrafficOnly: sa1SupportsHttpsTrafficOnly
    sa1AllowBlobPublicAccess: sa1AllowBlobPublicAccess
    sa1MinimumTlsVersion: sa1MinimumTlsVersion
    fs1sa1Name: fs1sa1Name
    fs1sa1Quota: fs1sa1Quota
  }
}

/// Module: Private Endpoint 1 ///
module pvtend1 'module-private-endpoint-1.bicep' = {
  scope: resourceGroup(rgnet.name)
  name: 'pvtend1'
  params: {
    location: location
    privatelink1Name: privatelink1Name
    privatendpoint1Name: privatendpoint1Name
    sa1Id: sa1.outputs.sa1Id
    subnet1Id: vnet.outputs.subnet1Id
  }
}

/// Module: Host Pool 1 Prod ///
module hp1prod './module-host-pool-1-prod.bicep' = {
  scope: resourceGroup(rghp1prod.name)
  name: 'hp1prod'
  params: {
    location: location
    hp1prodName: hp1prodName
    hp1prodFriendlyName: hp1prodFriendlyName
    hp1prodDescription: hp1prodDescription
    hp1prodHostPoolType: hp1prodHostPoolType
    hp1prodMaxSessionLimit: hp1prodMaxSessionLimit
    hp1prodLoadBalancerType: hp1prodLoadBalancerType
    hp1prodPreferredAppGroupType: hp1prodPreferredAppGroupType
    hp1prodBaseTime: hp1prodBaseTime
    hp1prodTokenExpirationTime: hp1prodTokenExpirationTime
    ag1hp1prodName: ag1hp1prodName
    ag1hp1prodFriendlyName: ag1hp1prodFriendlyName
    ag1hp1prodDescription: ag1hp1prodDescription
    ag1hp1prodApplicationGroupType: ag1hp1prodApplicationGroupType
  }
}

/// Module: Host Pool 1 Test ///
module hp1test './module-host-pool-1-test.bicep' = {
  scope: resourceGroup(rghp1test.name)
  name: 'hp1test'
  params: {
    location: location
    hp1testName: hp1testName
    hp1testFriendlyName: hp1testFriendlyName
    hp1testDescription: hp1testDescription
    hp1testHostPoolType: hp1testHostPoolType
    hp1testMaxSessionLimit: hp1testMaxSessionLimit
    hp1testLoadBalancerType: hp1testLoadBalancerType
    hp1testPreferredAppGroupType: hp1testPreferredAppGroupType
    hp1testBaseTime: hp1testBaseTime
    hp1testTokenExpirationTime: hp1testTokenExpirationTime
    ag1hp1testName: ag1hp1testName
    ag1hp1testFriendlyName: ag1hp1testFriendlyName
    ag1hp1testDescription: ag1hp1testDescription
    ag1hp1testApplicationGroupType: ag1hp1testApplicationGroupType
  }
}

/// Module: Host Pool 1 Dev ///
module hp1dev './module-host-pool-1-dev.bicep' = {
  scope: resourceGroup(rghp1dev.name)
  name: 'hp1dev'
  params: {
    location: location
    hp1devName: hp1devName 
    hp1devFriendlyName: hp1devFriendlyName
    hp1devDescription: hp1devDescription
    hp1devValidationEnvironment: hp1devValidationEnvironment
    hp1devHostPoolType: hp1devHostPoolType
    hp1devMaxSessionLimit: hp1devMaxSessionLimit
    hp1devLoadBalancerType: hp1devLoadBalancerType
    hp1devPreferredAppGroupType: hp1devPreferredAppGroupType
    hp1devBaseTime: hp1devBaseTime
    hp1devTokenExpirationTime: hp1devTokenExpirationTime
    ag1hp1devName: ag1hp1devName
    ag1hp1devFriendlyName: ag1hp1devFriendlyName 
    ag1hp1devDescription: ag1hp1devDescription
    ag1hp1devApplicationGroupType: ag1hp1devApplicationGroupType
  }
}

/// Module: Workspace Prod ///
module wsprod 'module-workspace-prod.bicep' = {
  scope: resourceGroup(rgcore.name)
  name: 'wsprod'
  params: {
    location: location
    wsprodName: wsprodName
    wsprodFriendlyName: wsprodFriendlyName
    wsprodDescription: wsprodDescription
    wsprodApplicationGroupReference1: hp1prod.outputs.ag1hp1prod
  }
}

/// Module: Workspace Test ///
module wstest 'module-workspace-test.bicep' = {
  scope: resourceGroup(rgcore.name)
  name: 'wstest'
  params: {
    location: location
    wstestName: wstestName
    wstestFriendlyName: wstestFriendlyName
    wstestDescription: wstestDescription
    wstestApplicationGroupReference1: hp1test.outputs.ag1hp1test
  }
}

/// Module: Workspace Dev ///
module wsdev 'module-workspace-dev.bicep' = {
  scope: resourceGroup(rgcore.name)
  name: 'wsdev'
  params: {
    location: location
    wsdevName: wsdevName
    wsdevFriendlyName: wsdevFriendlyName
    wsdevDescription: wsdevDescription
    wsdevApplicationGroupReference1: hp1dev.outputs.ag1hp1dev
  }
}

/// Module: Log Analytics ///
module log './module-log-analytics.bicep' = {
  scope: resourceGroup(rgcore.name)
  name: 'logs'
  params:{
    location: location
    logName: logName
    retentionInDays: retentionInDays
  }
}

/// Module: Diagnostics Host Pool 1 Prod ///
module diagshp1prod 'module-diagnostics-host-pool-1-prod.bicep' = {
  scope: resourceGroup(rghp1prod.name)
  name: 'diags-hp1prod'
  params: {
    workspaceId: log.outputs.logid
    hp1prodName: hp1prodName
  }
}

/// Module: Diagnostics Host Pool 1 Test ///
module diagshp1test 'module-diagnostics-host-pool-1-test.bicep' = {
  scope: resourceGroup(rghp1test.name)
  name: 'diags-hp1test'
  params: {
    workspaceId: log.outputs.logid
    hp1testName: hp1testName
  }
}

/// Module: Diagnostics Host Pool 1 Test ///
module diagshp1dev 'module-diagnostics-host-pool-1-dev.bicep' = {
  scope: resourceGroup(rghp1dev.name)
  name: 'diags-hp1dev'
  params: {
    workspaceId: log.outputs.logid
    hp1devName: hp1devName
  }
}

/// Module: Diagnostics Workspaces ///
module diagsws 'module-diagnostics-workspaces.bicep' = {
  scope: resourceGroup(rgcore.name)
  name: 'diags-ws'
  params: {
    workspaceId: log.outputs.logid
    wsprodName: wsprodName
    wstestName: wstestName
    wsdevName: wsdevName
  }
}

/// Module: Shared Image Gallery ///
module sig './module-shared-image-gallery.bicep' = {
  scope: resourceGroup(rgcore.name)
  name: 'sig'
  params:{
    location: location
    sigName: sigName
    img1Name: img1Name
    img1hyperVGeneration: img1hyperVGeneration
    img1Publisher: img1Publisher
    img1Offer: img1Offer
    img1Sku: img1Sku
  }
}

/// Module: Azure Image Builder ///
module aib 'module-azure-image-builder.bicep' = {
  name: 'aib'
  scope: resourceGroup(rgcore.name)
  params: {
    location: location
    uamiName: uamiName
    roleName: roleName
    roleDescription: roleDescription
    imgtempName: imgtempName
    vmSize: vmSize
    osDiskSizeGB: osDiskSizeGB
    imagePublisher: imagePublisher
    imageOffer: imageOffer
    imageSKU: imageSKU
    galleryImageId: sig.outputs.img1defid
    runOutputName: runOutputName
  }
}


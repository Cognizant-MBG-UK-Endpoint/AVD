/// wvd host pool 1 prod parameters ///
param wvdHp1MetadataRegion string
param wvdHp1ProdHostPoolName string
param wvdHp1ProdHostPoolFriendlyName string
param wvdHp1ProdHostPoolDescription string
param wvdHp1HostPoolType string
param wvdHp1MaxSessions int
param wvdHp1LoadBalancerType string
param wvdHp1PreferredAppGroupType string
param wvdHp1BaseTime string
param wvdHp1TokenExpirationTime string

/// wvd host pool 1 prod app group parameters ///
param wvdHp1AppGroupType string
param wvdHp1ProdAppGroupName string
param wvdHp1ProdAppGroupFriendlyName string
param wvdHp1ProdAppGroupDescription string

/// wvd host pool 1 prod resources ///
resource wvdhpprod 'Microsoft.DesktopVirtualization/hostPools@2021-01-14-preview' = {
  location: wvdHp1MetadataRegion
  name: wvdHp1ProdHostPoolName
  properties: {
    friendlyName: wvdHp1ProdHostPoolFriendlyName
    description: wvdHp1ProdHostPoolDescription
    validationEnvironment: false
    hostPoolType: wvdHp1HostPoolType
    maxSessionLimit: wvdHp1MaxSessions
    loadBalancerType: wvdHp1LoadBalancerType
    preferredAppGroupType: wvdHp1PreferredAppGroupType
    registrationInfo: {
      registrationTokenOperation: 'Update'
      expirationTime: dateTimeAdd(wvdHp1BaseTime, wvdHp1TokenExpirationTime)
    }
  }
}

/// wvd host pool 1 prod app group resources ///
resource wvdagprod 'Microsoft.DesktopVirtualization/applicationGroups@2021-01-14-preview' = {
  location: wvdHp1MetadataRegion
  name: wvdHp1ProdAppGroupName
  properties:{
    friendlyName: wvdHp1ProdAppGroupFriendlyName 
    description: wvdHp1ProdAppGroupDescription
    applicationGroupType: wvdHp1AppGroupType
    hostPoolArmPath: wvdhpprod.id
  }
}

output wvdagprod string = wvdagprod.id

/// wvd host pool 1 dev parameters ///
param wvdHp1MetadataRegion string
param wvdHp1DevHostPoolName string
param wvdHp1DevHostPoolFriendlyName string
param wvdHp1DevHostPoolDescription string
param wvdHp1HostPoolType string
param wvdHp1MaxSessions int
param wvdHp1LoadBalancerType string
param wvdHp1PreferredAppGroupType string
param wvdHp1BaseTime string
param wvdHp1TokenExpirationTime string

/// wvd host pool 1 dev app group parameters ///
param wvdHp1AppGroupType string
param wvdHp1DevAppGroupName string
param wvdHp1DevAppGroupFriendlyName string
param wvdHp1DevAppGroupDescription string

/// wvd host pool 1 dev resources ///
resource wvdhpdev 'Microsoft.DesktopVirtualization/hostPools@2021-01-14-preview' = {
  location: wvdHp1MetadataRegion
  name: wvdHp1DevHostPoolName
  properties: {
    friendlyName: wvdHp1DevHostPoolFriendlyName
    description: wvdHp1DevHostPoolDescription
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

/// wvd host pool 1 dev app group resources ///
resource wvdagdev 'Microsoft.DesktopVirtualization/applicationGroups@2021-01-14-preview' = {
  location: wvdHp1MetadataRegion
  name: wvdHp1DevAppGroupName
  properties:{
    friendlyName: wvdHp1DevAppGroupFriendlyName
    description: wvdHp1DevAppGroupDescription
    applicationGroupType: wvdHp1AppGroupType
    hostPoolArmPath: wvdhpdev.id
  }
}

output wvdagdev string = wvdagdev.id


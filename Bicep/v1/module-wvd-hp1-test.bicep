/// wvd host pool 1 test parameters ///
param wvdHp1MetadataRegion string
param wvdHp1TestHostPoolName string
param wvdHp1TestHostPoolFriendlyName string
param wvdHp1TestHostPoolDescription string
param wvdHp1HostPoolType string
param wvdHp1MaxSessions int
param wvdHp1LoadBalancerType string
param wvdHp1PreferredAppGroupType string
param wvdHp1BaseTime string
param wvdHp1TokenExpirationTime string

/// wvd host pool 1 test app group parameters ///
param wvdHp1AppGroupType string
param wvdHp1TestAppGroupName string
param wvdHp1TestAppGroupFriendlyName string
param wvdHp1TestAppGroupDescription string

/// wvd host pool 1 test resources ///
resource wvdhptest 'Microsoft.DesktopVirtualization/hostPools@2021-01-14-preview' = {
  location: wvdHp1MetadataRegion
  name: wvdHp1TestHostPoolName
  properties: {
    friendlyName: wvdHp1TestHostPoolFriendlyName
    description: wvdHp1TestHostPoolDescription
    validationEnvironment: true
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

/// wvd host pool 1 test app group resources ///
resource wvdagtest 'Microsoft.DesktopVirtualization/applicationGroups@2021-01-14-preview' = {
  location: wvdHp1MetadataRegion
  name: wvdHp1TestAppGroupName
  properties:{
    friendlyName: wvdHp1TestAppGroupFriendlyName
    description: wvdHp1TestAppGroupDescription
    applicationGroupType: wvdHp1AppGroupType
    hostPoolArmPath: wvdhptest.id
  }
}

output wvdagtest string = wvdagtest.id

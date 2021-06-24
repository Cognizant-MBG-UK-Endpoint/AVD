/// Location ///
param location string

/// Parameters: Host Pool 1 Prod ///
param hp1prodName string
param hp1prodFriendlyName string
param hp1prodDescription string
param hp1prodHostPoolType string
param hp1prodMaxSessionLimit int
param hp1prodLoadBalancerType string
param hp1prodPreferredAppGroupType string
param hp1prodBaseTime string
param hp1prodTokenExpirationTime string

/// Parameters: App Group 1 Prod ///
param ag1hp1prodName string
param ag1hp1prodFriendlyName string
param ag1hp1prodDescription string
param ag1hp1prodApplicationGroupType string

/// Resource: Host Pool 1 Prod ///
resource hp1prod 'Microsoft.DesktopVirtualization/hostPools@2021-03-09-preview' = {
  location: location
  name: hp1prodName
  properties: {
    friendlyName: hp1prodFriendlyName
    description: hp1prodDescription
    validationEnvironment: false
    hostPoolType: hp1prodHostPoolType
    maxSessionLimit: hp1prodMaxSessionLimit
    loadBalancerType: hp1prodLoadBalancerType
    preferredAppGroupType: hp1prodPreferredAppGroupType
    registrationInfo: {
      registrationTokenOperation: 'Update'
      expirationTime: dateTimeAdd(hp1prodBaseTime , hp1prodTokenExpirationTime)
    }
  }
}

/// Resource: App Group 1 Prod ///
resource ag1hp1prod 'Microsoft.DesktopVirtualization/applicationGroups@2021-03-09-preview' = {
  location: location
  name: ag1hp1prodName
  properties:{
    friendlyName: ag1hp1prodFriendlyName
    description: ag1hp1prodDescription
    applicationGroupType: ag1hp1prodApplicationGroupType
    hostPoolArmPath: hp1prod.id
  }
}

/// Output: App Group 1 Prod ///
output ag1hp1prod string = ag1hp1prod.id


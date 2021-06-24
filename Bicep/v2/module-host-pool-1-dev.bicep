/// Location ///
param location string

/// Parameters: Host Pool 1 Dev ///
param hp1devName string
param hp1devFriendlyName string
param hp1devDescription string
param hp1devValidationEnvironment bool
param hp1devHostPoolType string
param hp1devMaxSessionLimit int
param hp1devLoadBalancerType string
param hp1devPreferredAppGroupType string
param hp1devBaseTime string
param hp1devTokenExpirationTime string

/// Parameters: App Group 1 Dev ///
param ag1hp1devName string
param ag1hp1devFriendlyName string
param ag1hp1devDescription string
param ag1hp1devApplicationGroupType string

/// Resource: Host Pool 1 Dev ///
resource hp1dev 'Microsoft.DesktopVirtualization/hostPools@2021-03-09-preview' = {
  location: location
  name: hp1devName
  properties: {
    friendlyName: hp1devFriendlyName
    description: hp1devDescription
    validationEnvironment: hp1devValidationEnvironment
    hostPoolType: hp1devHostPoolType
    maxSessionLimit: hp1devMaxSessionLimit
    loadBalancerType: hp1devLoadBalancerType
    preferredAppGroupType: hp1devPreferredAppGroupType
    registrationInfo: {
      registrationTokenOperation: 'Update'
      expirationTime: dateTimeAdd(hp1devBaseTime , hp1devTokenExpirationTime)
    }
  }
}

/// Resource: App Group 1 Dev ///
resource ag1hp1dev 'Microsoft.DesktopVirtualization/applicationGroups@2021-03-09-preview' = {
  location: location
  name: ag1hp1devName
  properties:{
    friendlyName: ag1hp1devFriendlyName
    description: ag1hp1devDescription
    applicationGroupType: ag1hp1devApplicationGroupType
    hostPoolArmPath: hp1dev.id
  }
}

/// Output: App Group 1 Dev ///
output ag1hp1dev string = ag1hp1dev.id


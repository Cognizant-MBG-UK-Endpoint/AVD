/// Location ///
param location string

/// Parameters: Host Pool 1 Test ///
param hp1testName string
param hp1testFriendlyName string
param hp1testDescription string
param hp1testHostPoolType string
param hp1testMaxSessionLimit int
param hp1testLoadBalancerType string
param hp1testPreferredAppGroupType string
param hp1testBaseTime string
param hp1testTokenExpirationTime string

/// Parameters: App Group 1 Test ///
param ag1hp1testName string
param ag1hp1testFriendlyName string
param ag1hp1testDescription string
param ag1hp1testApplicationGroupType string

/// Resource: Host Pool 1 Test ///
resource hp1test 'Microsoft.DesktopVirtualization/hostPools@2021-03-09-preview' = {
  location: location
  name: hp1testName
  properties: {
    friendlyName: hp1testFriendlyName
    description: hp1testDescription
    validationEnvironment: false
    hostPoolType: hp1testHostPoolType
    maxSessionLimit: hp1testMaxSessionLimit
    loadBalancerType: hp1testLoadBalancerType
    preferredAppGroupType: hp1testPreferredAppGroupType
    registrationInfo: {
      registrationTokenOperation: 'Update'
      expirationTime: dateTimeAdd(hp1testBaseTime , hp1testTokenExpirationTime)
    }
  }
}

/// Resource: App Group 1 Test ///
resource ag1hp1test 'Microsoft.DesktopVirtualization/applicationGroups@2021-03-09-preview' = {
  location: location
  name: ag1hp1testName
  properties:{
    friendlyName: ag1hp1testFriendlyName
    description: ag1hp1testDescription
    applicationGroupType: ag1hp1testApplicationGroupType
    hostPoolArmPath: hp1test.id
  }
}

/// Output: App Group 1 Test ///
output ag1hp1test string = ag1hp1test.id


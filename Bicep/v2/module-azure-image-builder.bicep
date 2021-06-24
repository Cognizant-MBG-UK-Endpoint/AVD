/// Location ///
param location string

/// Resource Group ///
param rgName string = resourceGroup().name

/// Parameters: User Assigned Managed Identity ///
param uamiName string

/// Parameters: Role Definition ///
param roleName string
param roleDescription string

/// Parameters: Image Template ///
param imgtempName string
param vmSize string
param osDiskSizeGB int
param imagePublisher string
param imageOffer string
param imageSKU string
param galleryImageId string
param runOutputName string

/// Resource: User Assigned Managed Identity ///
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  location: location
  name: uamiName
}

/// Resource: Role Definition ///
resource roledef 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid(roleName)
  properties: {
    roleName: roleName
    description: roleDescription
    permissions: [
      {
        actions: [
          'Microsoft.Compute/galleries/read'
          'Microsoft.Compute/galleries/images/read'
          'Microsoft.Compute/galleries/images/versions/read'
          'Microsoft.Compute/galleries/images/versions/write'
          'Microsoft.Compute/images/write'
          'Microsoft.Compute/images/read'
          'Microsoft.Compute/images/delete'
          'Microsoft.ContainerInstance/containerGroups/*'
          'Microsoft.Resources/deployments/*'
          'Microsoft.Resources/deploymentScripts/*'
          'Microsoft.Storage/storageAccounts/*'
          'Microsoft.VirtualMachineImages/imageTemplates/Run/action'
        ]
        notActions: []
      }
    ]
    assignableScopes: [
      resourceGroup().id
    ]
  }
}

/// Resource: Role Assignment for Custom Role Definition ///
resource roleassign 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, roledef.id, uami.id)
  properties: {
    roleDefinitionId: roledef.id
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

/// Resource: Role Assignment for Managed Identity Operator Role ///
resource miorole 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, '/providers/Microsoft.Authorization/roleDefinitions/f1a07417-d97a-45cb-824c-7a7467783830', uami.id)
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/f1a07417-d97a-45cb-824c-7a7467783830'
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

/// Resource: Image Template ///
resource imgtemp 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14' = {
  location: location
  name: imgtempName
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    buildTimeoutInMinutes: 120
    vmProfile: {
      vmSize: vmSize
      osDiskSizeGB: osDiskSizeGB
    }
    source: {
      type: 'PlatformImage'
      publisher: imagePublisher
      offer: imageOffer
      sku: imageSKU
      version: 'latest'
    }
    customize: []
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: galleryImageId
        runOutputName: runOutputName
        replicationRegions: []
      }
    ]
  }
}

/// Resource: Deployment Script ///
resource imgbuild 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'imgbuild'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    forceUpdateTag: '1'
    azPowerShellVersion: '5.9'
    arguments: ''
    scriptContent: 'Invoke-AzResourceAction -ResourceName ${imgtempName} -ResourceGroupName ${rgName} -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2020-02-14" -Action Run -Force'
    timeout: 'PT5M'
    cleanupPreference: 'Always'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    imgtemp
  ]
}

/// Location ///
param location string

/// Parameters: Shared Image Gallery ///
param sigName string

/// Parameters: Image Definition 1 ///
param img1Name string
param img1hyperVGeneration string
param img1Publisher string
param img1Offer string
param img1Sku string

/// Variables: Shared Image Gallery ///
var img1DefName = '${sig.name}/${img1Name}'

/// Resource: Shared Image Gallery ///
resource sig 'Microsoft.Compute/galleries@2020-09-30' = {
  location: location
  name: sigName
}

/// Resource: Image Definition 1 ///
resource img1def 'Microsoft.Compute/galleries/images@2020-09-30' = {
  location: location
  name: img1DefName
  properties:{
    hyperVGeneration: img1hyperVGeneration
    osType: 'Windows'
    osState: 'Generalized'
    identifier:{
      publisher: img1Publisher
      offer: img1Offer
      sku: img1Sku
    }
  }
}

/// Output: Shared Image Gallery ///
output sigid string = sig.id
output img1defid string = img1def.id

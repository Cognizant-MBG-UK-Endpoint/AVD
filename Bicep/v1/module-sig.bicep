/// shared image gallery parameters ///
param region string
param sigName string
param imgName string
param hypvGen string
param imgPub string
param imgOff string
param imgSku string

/// shared image gallery variables ///
var imgDefName = '${sig.name}/${imgName}'

/// shared image gallery resources ///
resource sig 'Microsoft.Compute/galleries@2020-09-30' = {
  location: region
  name: sigName
}

resource imgdef 'Microsoft.Compute/galleries/images@2020-09-30' = {
  location: region
  name: imgDefName
  properties:{
    hyperVGeneration: hypvGen
    osType: 'Windows'
    osState: 'Generalized'
    identifier:{
      publisher: imgPub
      offer: imgOff
      sku: imgSku
    }
  }
}

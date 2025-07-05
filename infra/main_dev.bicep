// Parameters
// param prefix string
// param stamp string
// param envType string
// param region string
// param tenantId string
// param resourceId string = '' // optional, for enriched module only

param prefix string
param stamp string
param envType string
param region string

// Raw Storage Account
module raw 'StorageAccount/raw/template.bicep' = {
  name: 'Raw_StorageModule'
  params: {
    prefix: prefix
    stamp: stamp
    envType: envType
    region: region
  }
}

// Derived Storage Account
module derived 'StorageAccount/derived/template.bicep' = {
  name: 'Derived_StorageModule'
  params: {
    prefix: prefix
    stamp: stamp
    envType: envType
    region: region
  }
}


// // Landing Storage Account
// module landing 'StorageAccount/landing/template.bicep' = {
//   name: 'Landing_StorageModule'
//   params: {
//     prefix: prefix
//     stamp: stamp
//     envType: envType
//     region: region
//   }
// }

// // Raw Storage Account
// module raw 'StorageAccount/raw/template.bicep' = {
//   name: 'Raw_StorageModule'
//   params: {
//     prefix: prefix
//     stamp: stamp
//     envType: envType
//     region: region
//   }
// }



// // Enriched Storage Account
// module enriched 'StorageAccount/enriched/template.bicep' = {
//   name: 'Enriched_StorageModule'
//   params: {
//     prefix: prefix
//     stamp: stamp
//     envType: envType
//     region: region
//     tenantId: tenantId
//     resourceId: resourceId
//   }
// }

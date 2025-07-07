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

// // Derived Storage Account
// module derived 'StorageAccount/derived/template.bicep' = {
//   name: 'Derived_StorageModule'
//   params: {
//     prefix: prefix
//     stamp: stamp
//     envType: envType
//     region: region
    
//   }
// }

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

//databricks module
module databricks 'Databricks/template.bicep' = {
  name: 'DatabricksModule'
  params: {
    prefix:prefix
    stamp:stamp
    envType:envType
    region: region
  }
}

// // Enriched Storage Account
// module enriched 'StorageAccount/enriched/template.bicep' = {
//   name: 'Enriched_StorageModule'
//   params: {
//     prefix: prefix
//     stamp: stamp
//     envType: envType
//     region: region
//   }
// }

// //azure batch module
// module az_batch 'AzureBatch/BatchTemplate/template.bicep' = {
//   name:'az_batch_module'
//   params:{
//     prefix:prefix
//     stamp:stamp
//     envType:envType
//     region: region
//     //containerRegistry_password: kv.getSecret('acrpasskey')    //container registry password from access key
//   }
// }
// //datafactory module
// module datafactory 'ADF/ADFTemplate/template.bicep' = {
//   name: 'datafactoryModule'
//   params: {
//     prefix:prefix
//     stamp:stamp
//     envType:envType
//     region: region
//   }
// }


//linked service module
module ADLS_LinkedService 'LinkedService/ADLS-DB-LinkService/template.bicep' = {
  name: 'ADLS-DB_Module'
  params: {
    prefix:prefix
    stamp:stamp
    envType:envType
    // accessKey:kv.getSecret('databrickspasskey')         //access token after launching the databricks->settings->developer->manage access token->generate access token
  }
  dependsOn: [
    databricks
  ]
}

//batch linked service module
module Batch_LinkedService 'LinkedService/AzureBatchLinkService/template.bicep' = {
  name: 'Batch_LinkedServiceModule'
  params: {
    envType: envType
    prefix: prefix
    stamp: stamp
    region: region
    // accessKey: kv.getSecret('batchpasskey')     //Primary access key from Keys in batch account
  }
}


//dataset module
module datasets 'Dataset/template.bicep' = {
  name: 'DatasetsModule'
  params: {
    envType: envType
    prefix: prefix
    stamp: stamp
  }
  dependsOn: [
    ADLS_LinkedService
    Batch_LinkedService
  ]
}

param prefix string
param stamp string
param envType string
param region string

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: '${prefix}-dataops-adf-${envType}-${stamp}'
  location: region
  properties: {}
}


param location string = resourceGroup().location

// Existing Storage Accounts
resource derived 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: '${prefix}dataopssaderiv${envType}${stamp}'
}

resource enriched 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: '${prefix}dataopssaenric${envType}${stamp}'
}

resource landing 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: '${prefix}dataopssaland${envType}${stamp}'
}

// // Existing Data Factory
// resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
//   name: '${prefix}-dataops-adf-${envType}-${stamp}'
// }

// Existing Databricks Workspace
resource databricks 'Microsoft.Databricks/workspaces@2024-02-01-preview' existing = {
  name: '${prefix}-dataops-databricks-${envType}-${stamp}'
}

// Databricks Linked Service
resource databricksLinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: '${prefix}-dataops-databricks-${envType}-${stamp}-ingestion-cluster-link'
  parent: dataFactory
  properties: {
    type: 'AzureDatabricks'
    typeProperties: {
      domain: 'https://${databricks.properties.workspaceUrl}'
    }
  }
}

// Landing Linked Service
resource landinglinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: 'LS_Landing'
  parent: dataFactory
  properties: {
    type: 'AzureBlobFS'
    typeProperties: {
      url: 'https://${prefix}dataopssaland${envType}${stamp}.dfs.core.windows.net'
      fileSystem: 'landing'
      authenticateUsingManagedIdentity: true
    }
  }
}

// Extracted Linked Service
resource extractedlinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: 'LS_Extracted'
  parent: dataFactory
  properties: {
    type: 'AzureBlobFS'
    typeProperties: {
      url: 'https://${prefix}dataopssaderiv${envType}${stamp}.dfs.core.windows.net'
      fileSystem: 'extracted'
      authenticateUsingManagedIdentity: true
    }
  }
}

// Enriched Linked Service
resource enrichedlinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: 'LS_Enriched'
  parent: dataFactory
  properties: {
    type: 'AzureBlobFS'
    typeProperties: {
      url: 'https://${prefix}dataopssaenric${envType}${stamp}.dfs.core.windows.net'
      authenticateUsingManagedIdentity: true
    }
  }
}

// ADX Linked Service
resource ADXlinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: 'LS_ADX'
  parent: dataFactory
  properties: {
    type: 'AzureDataExplorer'
    typeProperties: {
      endpoint: 'https://${prefix}avtmdataopsadx1${envType}${stamp}.${location}.kusto.windows.net'
      database: 'avops'
      authenticateUsingManagedIdentity: true
    }
  }
}

// Azure Batch Linked Service for ADF
resource azBatchLinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: 'LS-batch-${envType}-${stamp}'
  parent: dataFactory
  properties: {
    type: 'AzureBatch'
    typeProperties: {
      accountName: '${prefix}dataopsbatch${envType}${stamp}'
      batchUri: 'https://${prefix}dataopsbatch${envType}${stamp}.${region}.batch.azure.com'
      authenticateUsingManagedIdentity: true
      poolName: '${prefix}dataops-orchestratorpool'
    }
  }
}

// Azure Blob Storage Linked Service for ADF (used by Azure Batch)
resource batchStorageLinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: 'LS_Batch_Storage'
  parent: dataFactory
  properties: {
    type: 'AzureBlobStorage'
    typeProperties: {
      accountName: '${prefix}dataopsbatch${envType}${stamp}'
      authenticateUsingManagedIdentity: true
    }
  }
}


// //Refering to an existing datafactory
// resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
//   name: '${prefix}-dataops-adf-${envType}-${stamp}'
// }

//Refering to an existing linked service
resource linkedService1 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' existing = {
  parent: dataFactory
  name: 'LS_Landing'
}

resource linkedService2 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' existing = {
  parent: dataFactory
  name: 'LS_Extracted'
}

resource ds_embeddedimages 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${prefix}dataops_embedimg${envType}${stamp}'
  parent: dataFactory
  properties: {
    linkedServiceName: {
      referenceName: linkedService1.name
      type: 'LinkedServiceReference'
    }
    parameters: {
      source_path: {
        type: 'String'
        defaultValue: '@substring(pipeline().parameters.source_path, 0, lastIndexOf(pipeline().parameters.source_path, "/"))'
      }
    }
    annotations: []
    type: 'Json'
    typeProperties: {
      location: {
        type: 'AzureBlobFSLocation'
        folderPath: {
          value: '@concat(dataset().source_path, \'/embedding_vector_generation_results\')'
          type: 'Expression'
        }
        fileSystem: 'annotated'
      }
    }
    schema: {}
  }
}

resource ds_ingestjobresult 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${prefix}dataops_ingestresult${envType}${stamp}'
  parent: dataFactory
  properties: {
    linkedServiceName: {
      referenceName: linkedService2.name
      type: 'LinkedServiceReference'
    }
    annotations: []
    type: 'AzureDataExplorerTable'
    schema: [
      {
        name: 'IngestionId'
        type: 'string'
      }
      {
        name: 'Sprint'
        type: 'string'
      }
      {
        name: 'Timestamp'
        type: 'string'
      }
      {
        name: 'Index'
        type: 'string'
      }
      {
        name: 'SourceImageFilePath'
        type: 'string'
      }
      {
        name: 'OverlayFilePath'
        type: 'string'
      }
      {
        name: 'Gpt4VUsagePromptTokens'
        type: 'int'
      }
      {
        name: 'Gpt4VUsageCompletionTokens'
        type: 'int'
      }
      {
        name: 'Gpt4VUsageTotalTokens'
        type: 'int'
      }
      {
        name: 'Gpt4VMessageText'
        type: 'string'
      }
      {
        name: 'Gpt4VMessageEmbedding'
        type: 'dynamic'
      }
      {
        name: 'Gpt4VGroundingText'
        type: 'string'
      }
      {
        name: 'Gpt4VGroundingEmbedding'
        type: 'dynamic'
      }
    ]
    typeProperties: {
      table: 'EmbeddedImages'
    }
  }
}

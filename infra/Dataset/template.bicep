param prefix string
param stamp string
param envType string

//Refering to an existing datafactory
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: '${prefix}-dataops-adf-${envType}-${stamp}'
}

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

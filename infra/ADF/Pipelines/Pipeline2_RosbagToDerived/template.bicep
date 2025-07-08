param prefix string
param stamp string
param envType string
var factoryName = '${prefix}-dataops-adf-${envType}-${stamp}'
var factoryId = 'Microsoft.DataFactory/factories/${factoryName}'


resource factoryName_pipeline2_RosbagToDerived 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: '${factoryName}/pipeline2_RosbagToDerived'
  properties: {
    activities: [
      {
        name: 'Get FileDataStream Json'
        type: 'Lookup'
        dependsOn: []
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          source: {
            type: 'JsonSource'
            storeSettings: {
              type: 'AzureBlobFSReadSettings'
              recursive: true
              enablePartitionDiscovery: false
            }
            formatSettings: {
              type: 'JsonReadSettings'
            }
          }
          dataset: {
            referenceName: 'DS_DatastreamRaw11'
            type: 'DatasetReference'
            parameters: {
              fileName: {
                value: 'datastream.json'
                type: 'Expression'
              }
              folderPath: {
                value: '@pipeline().parameters.dataStreamPath'
                type: 'Expression'
              }
            }
          }
          firstRowOnly: false
        }
      }
      {
        name: 'Format Batch application Version'
        type: 'SetVariable'
        dependsOn: []
        policy: {
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          variableName: 'batchApiVersion'
          value: {
            value: '@replace(pipeline().parameters.batchVersion,\'.\',\'_\')'
            type: 'Expression'
          }
        }
      }
      {
        name: 'Create Data stream api'
        type: 'WebActivity'
        dependsOn: [
          {
            activity: 'Get FileDataStream Json'
            dependencyConditions: [
              'Succeeded'
            ]
          }
          {
            activity: 'Format Batch application Version'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          method: 'POST'
          headers: {}
          url: {
            value: '@concat(pipeline().parameters.apiBaseUrl,pipeline().parameters.apiVersion,\'/measurements/\',activity(\'Get FileDataStream Json\').output.value[0].measurementId,\'/datastreams\')'
            type: 'Expression'
          }
          body: {
            value: '@json(concat(\'{"name":"extractedstream","type":"EXTRACTED","lineage": {"producerMetadata":{"name": "batchextractor","type": "system","version": "\',pipeline().parameters.batchVersion,\'","additionalProperties": {"pipeLineRunID": "\',pipeline().RunId,\'","apiVersion": "\',pipeline().parameters.apiVersion,\'"}},"sources": ["\',activity(\'Get FileDataStream Json\').output.value[0].id,\'"]},"tags": \',activity(\'Get FileDataStream Json\').output.value[0].tags,\'}\'))'
            type: 'Expression'
          }
        }
      }
      {
        name: 'CreateBatchParams'
        type: 'SetVariable'
        dependsOn: [
          {
            activity: 'Create Data stream api'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        policy: {
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          variableName: 'batchParams'
          value: {
            value: '@concat(\' --measurementId \',activity(\'Get FileDataStream Json\').output.value[0].measurementId,\' --rawDataStreamPath \',pipeline().parameters.dataStreamPath,\' --extractedDataStreamPath \',activity(\'Create Data stream api\').output.relativeUriPath,\' --extractedDataStreamId \',activity(\'Create Data stream api\').output.id)'
            type: 'Expression'
          }
        }
      }
      {
        name: 'Update Datastream to Processing'
        type: 'WebActivity'
        dependsOn: [
          {
            activity: 'CreateBatchParams'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          method: 'PATCH'
          headers: {}
          url: {
            value: '@concat(pipeline().parameters.apiBaseUrl,pipeline().parameters.apiVersion,\'/measurements/\',activity(\'Get FileDataStream Json\').output.value[0].measurementId,\'/datastreams/\',activity(\'Create Data stream api\').output.id)'
            type: 'Expression'
          }
          body: {
            status: 'PROCESSING'
          }
        }
      }
            {
        name: 'Batch Orchestrator'
        type: 'Custom'
        dependsOn: [
          {
            activity: 'Update Datastream to Processing'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
            
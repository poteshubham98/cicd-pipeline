// param factoryName string
// param LS_Landing string

param prefix string
param stamp string
param envType string
// param region string 

var factoryName = '${prefix}-dataops-adf-${envType}-${stamp}'
var factoryId = 'Microsoft.DataFactory/factories/${factoryName}'
 
resource factoryName_pipeline1_LandingToRoshbag 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: '${factoryName}/pipeline1_LandingToRoshbag'
  properties: {
    activities: [
      {
        name: 'LookupManifestJson'
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
            referenceName: 'DS_Manifest'
            type: 'DatasetReference'
            parameters: {
              folderName: {
                value: '@pipeline().parameters.measurementFolderPath'
                type: 'Expression'
              }
              fileName: {
                value: '@pipeline().parameters.fileManifestName'
                type: 'Expression'
              }
              containerName: {
                value: '@pipeline().parameters.landingZoneContainer'
                type: 'Expression'
              }
            }
          }
        }
      }
      {
        name: 'Get Measurement sub_Folders'
        type: 'GetMetadata'
        dependsOn: [
          {
            activity: 'Call CreateMeasurement -API'
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
          dataset: {
            referenceName: 'DS_Measurements'
            type: 'DatasetReference'
            parameters: {
              ContainerName: {
                value: '@pipeline().parameters.landingZoneContainer'
                type: 'Expression'
              }
              FolderPath: {
                value: '@pipeline().parameters.measurementFolderPath'
                type: 'Expression'
              }
            }
          }
          fieldList: [
            'childItems'
          ]
          storeSettings: {
            type: 'AzureBlobFSReadSettings'
            recursive: true
            enablePartitionDiscovery: false
          }
          formatSettings: {
            type: 'BinaryReadSettings'
          }
        }
      }
      {
        name: 'Call CreateMeasurement -API'
        type: 'WebActivity'
        dependsOn: [
          {
            activity: 'LookupManifestJson'
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
            value: '@concat(pipeline().parameters.apiBaseUrl,pipeline().parameters.apiVersion,\'/measurements\')'
            type: 'Expression'
          }
          // connectVia: {
          //   referenceName: 'AutoResolveIntegrationRuntime'
          //   type: 'IntegrationRuntimeReference'
          // }
          body: {
            value: '@activity(\'LookupManifestJson\').output.firstRow'
            type: 'Expression'
          }
        }
      }
      {
        name: 'FilterFolders'
        type: 'Filter'
        dependsOn: [
          {
            activity: 'Get Measurement sub_Folders'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        userProperties: []
        typeProperties: {
          items: {
            value: '@activity(\'Get Measurement sub_Folders\').output.childItems'
            type: 'Expression'
          }
          condition: {
            value: '@equals(item().type, \'Folder\')'
            type: 'Expression'
          }
        }
      }
      {
        name: 'Iterate Measurements'
        type: 'ForEach'
        dependsOn: [
          {
            activity: 'FilterFolders'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        userProperties: []
        typeProperties: {
          items: {
            value: '@activity(\'FilterFolders\').output.Value'
            type: 'Expression'
          }
          activities: [
            {
              name: 'GetBagFile'
              type: 'GetMetadata'
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
                dataset: {
                  referenceName: 'DS_Measurements'
                  type: 'DatasetReference'
                  parameters: {
                    ContainerName: {
                      value: '@pipeline().parameters.landingZoneContainer'
                      type: 'Expression'
                    }
                    FolderPath: {
                      value: '@concat(pipeline().parameters.measurementFolderPath, \'/\' , item().name)'
                      type: 'Expression'
                    }
                  }
                }
                fieldList: [
                  'childItems'
                ]
                storeSettings: {
                  type: 'AzureBlobFSReadSettings'
                  recursive: true
                  enablePartitionDiscovery: false
                }
                formatSettings: {
                  type: 'BinaryReadSettings'
                }
              }
            }
            {
              name: 'SetBagFileNme'
              type: 'SetVariable'
              dependsOn: [
                {
                  activity: 'GetBagFile'
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
                variableName: 'bagfile'
                value: {
                  value: '@activity(\'GetBagFile\').output.childItems[0].name'
                  type: 'Expression'
                }
              }
            }
            {
              name: 'Call CreateDatastream API'
              type: 'WebActivity'
              dependsOn: [
                {
                  activity: 'SetBagFileNme'
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
                  value: '@concat(pipeline().parameters.apiBaseUrl,pipeline().parameters.apiVersion,\'/measurements/\',activity(\'Call CreateMeasurement -API\').output.id,\'/datastreams\')'
                  type: 'Expression'
                }
                // connectVia: {
                //   referenceName: 'AutoResolveIntegrationRuntime'
                //   type: 'IntegrationRuntimeReference'
                // }
                body: {
                  value: '{\n  "name": "string",\n  "type": "ROSBAG",\n  "lineage": {\n    "producerMetadata": {\n      "name": "string",\n      "type": "measurement",\n      "version": "string",\n      "additionalProperties": {\n        "additionalProp1": "string",\n        "additionalProp2": "string",\n        "additionalProp3": "string"\n      }\n    },\n    "sources": []\n  },\n  "tags": [\n    {}\n  ]\n}'
                  type: 'Expression'
                }
              }
            }
            {
              name: 'Call UpdateDataStream To Processing'
              type: 'WebActivity'
              dependsOn: [
                {
                  activity: 'Call CreateDatastream API'
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
                  value: '@concat(pipeline().parameters.apiBaseUrl,pipeline().parameters.apiVersion,\'/measurements/\',activity(\'Call CreateMeasurement -API\').output.id,\'/datastreams/\',activity(\'Call CreateDatastream API\').output.id)'
                  type: 'Expression'
                }
                // connectVia: {
                //   referenceName: 'AutoResolveIntegrationRuntime'
                //   type: 'IntegrationRuntimeReference'
                // }
                body: {
                  value: '{"status": "PROCESSING"}'
                  type: 'Expression'
                }
              }
            }
            {
              name: 'Copy Data Landing_To_Rosbag'
              type: 'Copy'
              dependsOn: [
                {
                  activity: 'Call UpdateDataStream To Processing'
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
                source: {
                  type: 'BinarySource'
                  storeSettings: {
                    type: 'AzureBlobFSReadSettings'
                    recursive: true
                  }
                  formatSettings: {
                    type: 'BinaryReadSettings'
                  }
                }
                sink: {
                  type: 'BinarySink'
                  storeSettings: {
                    type: 'AzureBlobFSWriteSettings'
                  }
                }
                enableStaging: false
              }
              inputs: [
                {
                  referenceName: 'DS_SourceMeasurements'
                  type: 'DatasetReference'
                  parameters: {
                    container: {
                      value: '@pipeline().parameters.landingZoneContainer'
                      type: 'Expression'
                    }
                    directory: {
                      value: '@concat(pipeline().parameters.measurementFolderPath, \'/\' , item().name)'
                      type: 'Expression'
                    }
                    filename: {
                      value: '@variables(\'bagfile\')'
                      type: 'Expression'
                    }
                  }
                }
              ]
              outputs: [
                {
                  referenceName: 'DS_SourceMeasurements'
                  type: 'DatasetReference'
                  parameters: {
                    container: {
                      value: '@pipeline().parameters.rosbagZoneContainer'
                      type: 'Expression'
                    }
                    directory: {
                      value: '@concat(split(activity(\'Call CreateDatastream API\').output.relativeUriPath, \'rosbag/\')[1],\'/\',item().name)'
                      type: 'Expression'
                    }
                    filename: {
                      value: '@variables(\'bagfile\')'
                      type: 'Expression'
                    }
                  }
                }
              ]
            }
            {
              name: 'Call UpdateDataStream To copy complete'
              type: 'WebActivity'
              dependsOn: [
                {
                  activity: 'Copy Data Landing_To_Rosbag'
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
                  value: '@concat(pipeline().parameters.apiBaseUrl,pipeline().parameters.apiVersion,\'/measurements/\',activity(\'Call CreateMeasurement -API\').output.id,\'/datastreams/\',activity(\'Call CreateDatastream API\').output.id)'
                  type: 'Expression'
                }
                body: {
                  value: '{"status": "COMPLETED"}'
                  type: 'Expression'
                }
              }
            }
          ]
        }
      }
    ]
    policy: {
      elapsedTimeMetric: {}
    }
    parameters: {
      landingZoneContainer: {
        type: 'string'
        defaultValue: 'landing'
      }
      fileManifestName: {
        type: 'string'
        defaultValue: 'manifest.json'
      }
      apiBaseUrl: {
        type: 'string'
        defaultValue: 'https://wapp-${prefix}-dataops-azapp-metadata-${envType}-${stamp}.azurewebsites.net/'
      }
      apiVersion: {
        type: 'string'
        defaultValue: 'v1'
      }
      batchVersion: {
        type: 'string'
        defaultValue: '1.0'
      }
      archiveZoneContainer: {
        type: 'string'
        defaultValue: 'archive'
      }
      rosbagZoneContainer: {
        type: 'string'
        defaultValue: 'rosbag'
      }
      measurementFolderPath: {
        type: 'string'
      }
    }
    variables: {
      batchParams: {
        type: 'String'
      }
      bagfile: {
        type: 'String'
      }
    }
    folder: {
      name: 'MSFT_TMC/Development'
    }
    annotations: []
    lastPublishTime: '2024-07-10T06:06:37Z'
  }
  dependsOn: [
    factoryName_DS_Manifest
    factoryName_DS_Measurements
    factoryName_DS_SourceMeasurements
    // '${factoryId}/datasets/DS_Manifest'
    // '${factoryId}/datasets/DS_Measurements'
    // '${factoryId}/datasets/DS_SourceMeasurements'
  ]
}
 
resource factoryName_DS_Manifest 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${factoryName}/DS_Manifest'
  properties: {
    linkedServiceName: {
      referenceName: 'LS_Landing'
      type: 'LinkedServiceReference'
    }
    parameters: {
      folderName: {
        type: 'string'
      }
      fileName: {
        type: 'string'
      }
      containerName: {
        type: 'string'
      }
    }
    annotations: []
    type: 'Json'
    typeProperties: {
      location: {
        type: 'AzureBlobFSLocation'
        fileName: {
          value: '@dataset().fileName'
          type: 'Expression'
        }
        folderPath: {
          value: '@dataset().folderName'
          type: 'Expression'
        }
        fileSystem: {
          value: '@dataset().containerName'
          type: 'Expression'
        }
      }
    }
    schema: {}
  }
  dependsOn: []
}
 
resource factoryName_DS_Measurements 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${factoryName}/DS_Measurements'
  properties: {
    linkedServiceName: {
      referenceName: 'LS_Landing'
      type: 'LinkedServiceReference'
    }
    parameters: {
      ContainerName: {
        type: 'string'
      }
      FolderPath: {
        type: 'string'
      }
    }
    annotations: []
    type: 'Binary'
    typeProperties: {
      location: {
        type: 'AzureBlobFSLocation'
        folderPath: {
          value: '@dataset().FolderPath'
          type: 'Expression'
        }
        fileSystem: {
          value: '@dataset().ContainerName'
          type: 'Expression'
        }
      }
    }
  }
  dependsOn: []
}
 
resource factoryName_default 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = {
  name: '${factoryName}/default'
  properties: {}
  dependsOn: []
}
 
resource factoryName_DS_SourceMeasurements 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${factoryName}/DS_SourceMeasurements'
  properties: {
    linkedServiceName: {
      referenceName: 'LS_Landing'
      type: 'LinkedServiceReference'
    }
    parameters: {
      container: {
        type: 'string'
      }
      directory: {
        type: 'string'
      }
      filename: {
        type: 'string'
      }
    }
    annotations: []
    type: 'Binary'
    typeProperties: {
      location: {
        type: 'AzureBlobFSLocation'
        fileName: {
          value: '@dataset().filename'
          type: 'Expression'
        }
        folderPath: {
          value: '@dataset().directory'
          type: 'Expression'
        }
        fileSystem: {
          value: '@dataset().container'
          type: 'Expression'
        }
      }
    }
  }
  dependsOn: []
}

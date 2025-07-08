param prefix string
param stamp string
param envType string
param region string

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: '${prefix}-dataops-adf-${envType}-${stamp}'
  location: region
  properties: {}
}


// Trigger 1: New_Measurements
resource blobEventsTrigger1 'Microsoft.DataFactory/factories/triggers@2018-06-01' = {
  name: '${dataFactory.name}/New_Measuremets'
  properties: {
    description: 'Triggered when manifest.json is created in the measurement folder.'
    annotations: []
    pipelines: [
      {
        pipelineReference: {
          referenceName: 'pipeline1_LandingToRoshbag'
          type: 'PipelineReference'
        }
        parameters: {
          landingZoneContainer: 'landing'
          fileManifestName: 'manifest.json'
          apiBaseUrl: 'https://wapp-${prefix}-dataops-azapp-metadata-${envType}-${stamp}.azurewebsites.net/'
          apiVersion: 'v1'
          batchVersion: '1.0'
          archiveZoneContainer: 'archive'
          rosbagZoneContainer: 'rosbag'
          measurementFolderPath: '@{skip(triggerBody().folderPath , 7)}'
        }
      }
    ]
    type: 'BlobEventsTrigger'
    typeProperties: {
      blobPathBeginsWith: 'landing/measurement/' // ✅ Correct path
      blobPathEndsWith: 'manifest.json'
      ignoreEmptyBlobs: true
      scope: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Storage/storageAccounts/${prefix}dataopssaland${envType}${stamp}'
      events: [
        'Microsoft.Storage.BlobCreated'
      ]
    }
  }
  dependsOn: [dataFactory]
}

// Trigger 2: pipeline3_ImageAnnotation
resource blobEventsTrigger2 'Microsoft.DataFactory/factories/triggers@2018-06-01' = {
  name: '${dataFactory.name}/Pipeline3_trigger'
  properties: {
    annotations: []
    pipelines: [
      {
        pipelineReference: {
          referenceName: 'pipeline3_ImageAnnotation'
          type: 'PipelineReference'
        }
        parameters: {
          pl_p_ingestion_id: '1'
          pl_p_pipeline_step_id: '1'
          pl_p_source_type: 'csv'
          pl_p_source_path: 'avops/targetimagepath.csv'
          pl_p_prompt_path: 'avops/prompt.txt'
          pl_p_Extracted_images_source_path: '@triggerBody().folderPath'
        }
      }
    ]
    type: 'BlobEventsTrigger'
    typeProperties: {
      blobPathBeginsWith: 'extracted/images/'
      blobPathEndsWith: 'datastream.json'
      ignoreEmptyBlobs: true
      scope: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Storage/storageAccounts/${prefix}dataopssaderiv${envType}${stamp}'
      events: [
        'Microsoft.Storage.BlobCreated'
      ]
    }
  }
  dependsOn: [dataFactory]
}

// Trigger 3: Rosbag to Derived
resource blobEventsTrigger3 'Microsoft.DataFactory/factories/triggers@2018-06-01' = {
  name: '${dataFactory.name}/storagetrigger_rosbag'
  properties: {
    annotations: []
    pipelines: [
      {
        pipelineReference: {
          referenceName: 'pipeline2_RosbagToDerived'
          type: 'PipelineReference'
        }
        parameters: {
          dataStreamPath: '@triggerBody().folderPath'
          apiBaseUrl: 'https://wapp-${prefix}-dataops-azapp-metadata-${envType}-${stamp}.azurewebsites.net/'
          apiVersion: 'v1'
          batchVersion: '1.0'
          rawZoneContainer: 'rosbag'
        }
      }
    ]
    type: 'BlobEventsTrigger'
    typeProperties: {
      blobPathBeginsWith: 'rosbag/streams/'
      blobPathEndsWith: 'datastream.json'
      ignoreEmptyBlobs: true
      scope: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Storage/storageAccounts/${prefix}dataopssaland${envType}${stamp}'
      events: [
        'Microsoft.Storage.BlobCreated'
      ]
    }
  }
  dependsOn: [dataFactory]
}

output dataFactoryResourceId string = dataFactory.id

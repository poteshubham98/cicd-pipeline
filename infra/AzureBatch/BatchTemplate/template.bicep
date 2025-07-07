param prefix string
param stamp string
param envType string
param region string

// Deploy Storage Account for Batch autoStorage
resource batchStorage 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: '${prefix}dataopsbatch${envType}${stamp}'
  location: region
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

// Deploy Batch Account using the above storage
resource batch_account 'Microsoft.Batch/batchAccounts@2024-02-01' = {
  name: 'tcsdataopsbatch${envType}${stamp}'
  location: region
  properties: {
    autoStorage: {
      storageAccountId: batchStorage.id
      authenticationMode: 'StorageKeys'
    }
    poolAllocationMode: 'BatchService'
    publicNetworkAccess: 'Enabled'
    encryption: {
      keySource: 'Microsoft.Batch'
    }
    allowedAuthenticationModes: [
      'SharedKey'
      'AAD'
      'TaskAuthenticationToken'
    ]
  }
}

// Execution pool
resource executionpool 'Microsoft.Batch/batchAccounts/pools@2024-02-01' = {
  parent: batch_account
  name: 'tcsdataops-executionpool'
  properties: {
    vmSize: 'STANDARD_D8S_V3'
    interNodeCommunication: 'Disabled'
    taskSlotsPerNode: 32
    taskSchedulingPolicy: {
      nodeFillType: 'Pack'
    }
    deploymentConfiguration: {
      virtualMachineConfiguration: {
        imageReference: {
          publisher: 'microsoft-azure-batch'
          offer: 'ubuntu-server-container'
          sku: '20-04-lts'
          version: 'latest'
        }
        nodeAgentSkuId: 'batch.node.ubuntu 20.04'
        osDisk: {
          caching: 'None'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
        nodePlacementConfiguration: {
          policy: 'Regional'
        }
      }
    }
    scaleSettings: {
      fixedScale: {
        targetDedicatedNodes: 1
        targetLowPriorityNodes: 0
        resizeTimeout: 'PT15M'
      }
    }
    startTask: {
      commandLine: './blobfuse_startup_setup.sh'
      resourceFiles: [
        {
          autoStorageContainerName: 'blobfuse2'
        }
      ]
      userIdentity: {
        autoUser: {
          scope: 'Pool'
          elevationLevel: 'Admin'
        }
      }
      maxTaskRetryCount: 0
      waitForSuccess: true
    }
    targetNodeCommunicationMode: 'Default'
  }
}

// Orchestrator pool
resource orchestratorpool 'Microsoft.Batch/batchAccounts/pools@2024-02-01' = {
  parent: batch_account
  name: 'tcsdataops-orchestratorpool'
  properties: {
    vmSize: 'STANDARD_D8S_V3'
    interNodeCommunication: 'Disabled'
    taskSlotsPerNode: 16
    taskSchedulingPolicy: {
      nodeFillType: 'Pack'
    }
    deploymentConfiguration: {
      virtualMachineConfiguration: {
        imageReference: {
          publisher: 'canonical'
          offer: '0001-com-ubuntu-server-focal'
          sku: '20_04-lts'
          version: 'latest'
        }
        nodeAgentSkuId: 'batch.node.ubuntu 20.04'
        osDisk: {
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
        nodePlacementConfiguration: {
          policy: 'Regional'
        }
      }
    }
    scaleSettings: {
      fixedScale: {
        targetDedicatedNodes: 1
        targetLowPriorityNodes: 0
        resizeTimeout: 'PT15M'
      }
    }
    startTask: {
      commandLine: './blobfuse_startup_setup.sh'
      resourceFiles: [
        {
          autoStorageContainerName: 'blobfuse'
        }
      ]
      userIdentity: {
        autoUser: {
          scope: 'Pool'
          elevationLevel: 'Admin'
        }
      }
      maxTaskRetryCount: 1
      waitForSuccess: true
    }
    targetNodeCommunicationMode: 'Default'
  }
}

output batchAccountName string = batch_account.name

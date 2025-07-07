param prefix string
param stamp string
param envType string
param region string

resource batch_account 'Microsoft.Batch/batchAccounts@2024-02-01' = {
  name: 'tcsdataopsbatch${envType}${stamp}'
  location: region
  properties: {
    autoStorage: {
      storageAccountId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Storage/storageAccounts/${prefix}dataopsbatch${envType}${stamp}'
      authenticationMode: 'StorageKeys'
    }
    poolAllocationMode: 'BatchService'
    publicNetworkAccess: 'Enabled'
    networkProfile: {
      accountAccess: {
        defaultAction: 'Allow'
      }
      nodeManagementAccess: {
        defaultAction: 'Allow'
      }
    }
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

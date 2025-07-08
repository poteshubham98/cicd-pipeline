@description('Prefix for naming resources')
param prefix string

@description('Unique identifier stamp')
param stamp string

@description('Environment type (e.g., dev, prod)')
param envType string

@description('Azure region')
param region string

// Referencing an existing Azure Data Factory instance
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: '${prefix}-dataops-adf-${envType}-${stamp}'
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

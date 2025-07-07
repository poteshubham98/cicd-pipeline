param prefix string
param stamp string
param envType string
param region string 
param resourceId string
@secure()
param tenantId string

resource enriched 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: toLower('${prefix}dataopssaenric${envType}${stamp}')
  location: region
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
  properties: {
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    isNfsV3Enabled: true
    isSftpEnabled: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    isHnsEnabled: true
    networkAcls: {
      resourceAccessRules: [
        {
          tenantId: tenantId
          resourceId: resourceId
        }
      ]
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          keyType: 'Account'
          enabled: true
        }
        file: {
          keyType: 'Account'
          enabled: true
        }
      }
    }
    accessTier: 'Hot'
  }
}

resource enriched_blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
  parent: enriched
  name: 'default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
  }
}

resource annotated_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: enriched_blobServices
  name: 'annotated'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource labelled_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: enriched_blobServices
  name: 'labelled'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

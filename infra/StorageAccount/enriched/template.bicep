param prefix string
param stamp string
param envType string
param region string

resource enriched 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: '${prefix}dataopssaenric${envType}${stamp}'
  location: region
  sku: {
    name: 'Standard_LRS' // Using LRS for max compatibility
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    isNfsV3Enabled: false // ✅ NFS disabled to allow simple networking
    isSftpEnabled: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    isHnsEnabled: true // ✅ Still enabled for ADLS Gen2
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow' // ✅ Allowed now since NFS is disabled
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
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

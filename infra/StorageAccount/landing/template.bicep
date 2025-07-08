param prefix string
param stamp string
param envType string
param region string 

resource landing 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: '${prefix}dataopssaland${envType}${stamp}'
  location: region
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    isNfsV3Enabled: false
    isSftpEnabled: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    isHnsEnabled: true
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

resource landing_blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
  parent: landing
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


resource landing_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: landing_blobService
  name: 'landing'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
  dependsOn: [
    landing
  ]
}

resource rosbag_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: landing_blobService
  name: 'rosbag'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
  dependsOn: [
    landing
  ]
}

output landingaccountKey string = listKeys(landing.id, '2023-04-01').keys[0].value

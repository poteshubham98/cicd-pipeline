param prefix string
param stamp string
param envType string
param region string

resource derived 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: '${prefix}dataopssaderiv${envType}${stamp}'
  location: region
  sku: {
    name: 'Standard_ZRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    isNfsV3Enabled: true
    isSftpEnabled: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    isHnsEnabled: true
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

resource derived_blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
  parent: derived
  name: 'default'
  sku: {
    name: 'Standard_ZRS'

  }
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

resource curated_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: derived_blobServices
  name: 'curated'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource extracted_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: derived_blobServices
  name: 'extracted'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource synchronized_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: derived_blobServices
  name: 'synchronized'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

output derivedaccountKey string = listKeys(derived.id, '2023-04-01').keys[0].value

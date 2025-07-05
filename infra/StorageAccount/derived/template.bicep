param prefix string
param stamp string
param envType string
param region string

// VNet
resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: '${prefix}-shared-ntwk-${envType}-${stamp}'
  location: region
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

// Storage Account
resource derived 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: '${prefix}dataopssaderiv${envType}${stamp}'
  location: region
  sku: {
    name: 'Standard_ZRS'
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
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: '${vnet.id}/subnets/AzureBastionSubnet'
          action: 'Allow'
          state: 'Succeeded'
        }
        {
          id: '${vnet.id}/subnets/default'
          action: 'Allow'
          state: 'Succeeded'
        }
      ]
      ipRules: []
      resourceAccessRules: []
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

  dependsOn: [
    vnet
  ]
}

// Blob Service
resource derived_blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
  parent: derived
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

// Blob Containers
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

// Output storage key
output derivedaccountKey string = listKeys(derived.id, '2023-04-01').keys[0].value

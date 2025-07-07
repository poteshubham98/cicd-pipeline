param prefix string
param stamp string
param envType string
param region string
param userObjectId string // Azure AD object ID for RBAC

// Create Landing Storage Account
resource landing 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: toLower('${prefix}land${envType}${stamp}')  // ensure <=24 chars and lowercase
  location: region
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    isNfsV3Enabled: true  // Optional: enable only if supported
    isSftpEnabled: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    isHnsEnabled: true
    networkAcls: {
      bypass: 'AzureServices'
      ipRules: []
      resourceAccessRules: []
      virtualNetworkRules: []
      defaultAction: 'Allow' // Allow access since no VNet restriction
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      keySource: 'Microsoft.Storage'
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
    }
    accessTier: 'Hot'
  }
}

// Blob Service Configuration
resource landing_blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
  parent: landing
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
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

// Blob Containers

resource landing_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: landing_blobService
  name: 'landing'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource rosbag_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: landing_blobService
  name: 'rosbag'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

// RBAC Role Assignment to User
resource landingBlobRBAC 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(landing.id, 'StorageBlobDataContributor', userObjectId)
  scope: landing
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Blob Data Contributor
    principalId: userObjectId
    principalType: 'User'
  }
}

// Output storage account key (if you need shared key access for tools like Storage Explorer)
output landingaccountKey string = listKeys(landing.id, '2023-04-01').keys[0].value

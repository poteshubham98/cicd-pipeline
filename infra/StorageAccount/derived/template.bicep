param prefix string
param stamp string
param envType string
param region string
//param userObjectId string // your Azure AD object ID (for RBAC)

// Create Storage Account
resource derived 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: toLower('${prefix}deriv${envType}${stamp}')
  location: region
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
  properties: {
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    isNfsV3Enabled: true // Optional: only if supported
    isSftpEnabled: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    isHnsEnabled: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      resourceAccessRules: []
      virtualNetworkRules: []
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

// Blob Service Config
resource derived_blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
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
  parent: derived_blobService
  name: 'curated'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource extracted_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: derived_blobService
  name: 'extracted'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource synchronized_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: derived_blobService
  name: 'synchronized'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

// // RBAC Role Assignment to User
// resource derivedBlobRBAC 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
//   name: guid(derived.id, 'StorageBlobDataContributor', userObjectId)
//   scope: derived
//   properties: {
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Blob Data Contributor
//     principalId: userObjectId
//     principalType: 'User'
//   }
// }

// Output storage account key (for Shared Key access if needed)
output derivedaccountKey string = listKeys(derived.id, '2023-04-01').keys[0].value

// param prefix string
// param stamp string
// param envType string
// param region string

// // Create Derived Storage Account
// resource derived 'Microsoft.Storage/storageAccounts@2023-04-01' = {
//   name: toLower('${prefix}deriv${envType}${stamp}')
//   location: region
//   sku: {
//     name: 'Standard_ZRS'
//   }
//   kind: 'StorageV2'
//   properties: {
//     // Removed: dnsEndpointType (not valid here)
//     defaultToOAuthAuthentication: true
//     publicNetworkAccess: 'Enabled'
//     allowCrossTenantReplication: false
//     // Commented out to avoid unsupported errors depending on region/SKU
//     // isNfsV3Enabled: true
//     isSftpEnabled: false
//     minimumTlsVersion: 'TLS1_2'
//     allowBlobPublicAccess: false
//     allowSharedKeyAccess: true
//     largeFileSharesState: 'Enabled'
//     isHnsEnabled: true
//     networkAcls: {
//       bypass: 'AzureServices'
//       defaultAction: 'Allow' // Changed to 'Allow' since no VNet restrictions
//       ipRules: []
//       resourceAccessRules: []
//     }
//     supportsHttpsTrafficOnly: true
//     encryption: {
//       keySource: 'Microsoft.Storage'
//       requireInfrastructureEncryption: false
//       services: {
//         blob: {
//           keyType: 'Account'
//           enabled: true
//         }
//         file: {
//           keyType: 'Account'
//           enabled: true
//         }
//       }
//     }
//     accessTier: 'Hot'
//   }
// }

// // Create Blob Services
// resource derived_blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
//   parent: derived
//   name: 'default'
//   properties: {
//     containerDeleteRetentionPolicy: {
//       enabled: true
//       days: 7
//     }
//     cors: {
//       corsRules: []
//     }
//     deleteRetentionPolicy: {
//       allowPermanentDelete: false
//       enabled: true
//       days: 7
//     }
//   }
// }

// // Containers
// resource curated_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
//   parent: derived_blobServices
//   name: 'curated'
//   properties: {
//     defaultEncryptionScope: '$account-encryption-key'
//     denyEncryptionScopeOverride: false
//     publicAccess: 'None'
//   }
// }

// resource extracted_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
//   parent: derived_blobServices
//   name: 'extracted'
//   properties: {
//     defaultEncryptionScope: '$account-encryption-key'
//     denyEncryptionScopeOverride: false
//     publicAccess: 'None'
//   }
// }

// resource synchronized_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
//   parent: derived_blobServices
//   name: 'synchronized'
//   properties: {
//     defaultEncryptionScope: '$account-encryption-key'
//     denyEncryptionScopeOverride: false
//     publicAccess: 'None'
//   }
// }

// // Output storage account key
// output derivedaccountKey string = listKeys(derived.id, '2023-04-01').keys[0].value

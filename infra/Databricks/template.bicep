@description('Prefix for naming resources (e.g., "my")')
param prefix string

@description('Stamp or unique suffix (e.g., "001", "a1")')
param stamp string

@description('Deployment environment (e.g., "dev", "prod")')
param envType string

@description('Region to deploy the Databricks workspace')
param region string

resource databricksWorkspace 'Microsoft.Databricks/workspaces@2024-02-01-preview' = {
  name: '${prefix}-dataops-databricks-${envType}-${stamp}'
  location: region
  sku: {
    name: 'premium'
  }
  properties: {
    managedResourceGroupId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${prefix}-dataops-databricks-managed-${envType}-${stamp}'

    defaultCatalog: {
      initialType: 'UnityCatalog'
    }

    parameters: {
      enableNoPublicIp: {
        value: false
      }
    }
  }
}

output workspaceUrl string = databricksWorkspace.properties.workspaceUrl


// @description('Prefix for naming resources (e.g., "my")')
// param prefix string

// @description('Deployment environment (e.g., "dev", "prod")')
// param env string

// @description('Stamp or unique suffix (e.g., "001", "a1")')
// param stamp string

// @description('Region to deploy the Databricks workspace')
// param location string = resourceGroup().location

// resource databricksWorkspace 'Microsoft.Databricks/workspaces@2024-02-01-preview' = {
//   name: '${prefix}-dataops-databricks-${env}-${stamp}'
//   location: location
//   sku: {
//     name: 'premium'
//   }
//   properties: {
//     managedResourceGroupId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${prefix}-dataops-databricks-managed-${env}-${stamp}'

//     defaultCatalog: {
//       initialType: 'UnityCatalog'
//     }

//     parameters: {
//       enableNoPublicIp: {
//         value: false // ✅ Allows public IP access
//       }
//     }
//   }
// }

// output workspaceUrl string = databricksWorkspace.properties.workspaceUrl

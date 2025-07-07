param prefix string
param stamp string
param envType string
param region string 

var managedResourceGroupId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/DatabricksManagedRG'

resource databricks 'Microsoft.Databricks/workspaces@2024-02-01-preview' = {
  name: '${prefix}-dataops-databricks-${envType}-${stamp}'
  location: region
  sku: {
    name: 'premium'
  }
  properties: {
    defaultCatalog: {
      initialType: 'UnityCatalog'
    }
    managedResourceGroupId: managedResourceGroupId
    prepareEncryption: false
    requireInfrastructureEncryption: false
  }
}

output workspaceURL string = databricks.properties.workspaceUrl

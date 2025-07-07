param prefix string
param stamp string
param envType string
param region string

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
    parameters: {
      enableNoPublicIp: {
        value: false // ← Public IPs are OK
      }
    }
  }
}

output workspaceURL string = databricks.properties.workspaceUrl

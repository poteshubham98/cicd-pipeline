@description('Prefix for naming')
param prefix string

@description('Stamp for uniqueness')
param stamp string

@description('Environment type (e.g., dev, prod)')
param envType string

@description('Location of the resources')
param location string = resourceGroup().location

// Existing Storage Accounts
resource derived 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: '${prefix}dataopssaderiv${envType}${stamp}'
}

resource enriched 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: '${prefix}dataopssaenric${envType}${stamp}'
}

resource landing 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: '${prefix}dataopssaland${envType}${stamp}'
}

// Existing Data Factory
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: '${prefix}-dataops-adf-${envType}-${stamp}'
}

// Existing Databricks Workspace
resource databricks 'Microsoft.Databricks/workspaces@2024-02-01-preview' existing = {
  name: '${prefix}-dataops-databricks-${envType}-${stamp}'
}

// Linked Services
resource databricksLinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: '${prefix}-dataops-databricks-${envType}-${stamp}-ingestion-cluster-link'
  parent: dataFactory
  properties: {
    type: 'AzureDatabricks'
    typeProperties: {
      domain: 'https://${databricks.properties.workspaceUrl}'
    }
  }
}

resource landinglinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: 'LS_Landing'
  parent: dataFactory
  properties: {
    type: 'AzureBlobFS'
    typeProperties: {
      url: 'https://${prefix}dataopssaland${envType}${stamp}.dfs.core.windows.net'
      fileSystem: 'landing'
      authenticateUsingManagedIdentity: true
    }
  }
}

resource extractedlinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: 'LS_Extracted'
  parent: dataFactory
  properties: {
    type: 'AzureBlobFS'
    typeProperties: {
      url: 'https://${prefix}dataopssaderiv${envType}${stamp}.dfs.core.windows.net'
      fileSystem: 'extracted'
      authenticateUsingManagedIdentity: true
    }
  }
}

resource enrichedlinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: 'LS_Enriched'
  parent: dataFactory
  properties: {
    type: 'AzureBlobFS'
    typeProperties: {
      url: 'https://${prefix}dataopssaenric${envType}${stamp}.dfs.core.windows.net'
      authenticateUsingManagedIdentity: true
    }
  }
}

resource ADXlinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: 'LS_ADX'
  parent: dataFactory
  properties: {
    type: 'AzureDataExplorer'
    typeProperties: {
      endpoint: 'https://${prefix}avtmdataopsadx1${envType}${stamp}.${location}.kusto.windows.net'
      database: 'avops'
      authenticateUsingManagedIdentity: true
    }
  }
}

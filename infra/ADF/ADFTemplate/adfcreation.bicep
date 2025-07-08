@description('Prefix for naming')
param prefix string

@description('Stamp for uniqueness')
param stamp string

@description('Environment type (e.g., dev, prod)')
param envType string

@description('Azure region for deployment')
param region string

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: '${prefix}-dataops-adf-${envType}-${stamp}'
  location: region
  properties: {}
}

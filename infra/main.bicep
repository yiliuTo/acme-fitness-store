targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param cartBuildResultId string
param orderBuildResultId string
param shoppingBuildResultId string
param logAnalyticsName string = ''
param applicationInsightsName string = ''
param applicationInsightsDashboardName string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var asaInstanceName = '${abbrs.springApps}${resourceToken}'
var cartAppName = 'acme-cart'
var shoppingAppName = 'acme-shopping'
var orderAppName = 'acme-order'
var customBuilderName = 'acme-builder'
var tags = {
  'azd-env-name': environmentName
  'spring-cloud-azure': 'true'
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}-${resourceToken}'
  location: location
  tags: tags
}

module springApps 'modules/springapps/springapps.bicep' = {
  name: '${deployment().name}--asa'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    cartAppName: cartAppName
    orderAppName: orderAppName
    shoppingAppName: shoppingAppName
    tags: tags
    asaInstanceName: asaInstanceName
    cartBuildResultId: cartBuildResultId
    orderBuildResultId: orderBuildResultId
    shoppingBuildResultId: shoppingBuildResultId
    appInsightName: monitoring.outputs.applicationInsightsName
    laWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceId
    customBuilderName: customBuilderName
  }
}

// Monitor application with Azure Monitor
module monitoring './modules/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}


output ASA_INSTANCE_NAME string = '${asaInstanceName}'

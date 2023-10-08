param location string
param asaInstanceName string
param cartAppName string
param orderAppName string
param shoppingAppName string
param tags object = {}
param cartBuildResultId string
param orderBuildResultId string
param shoppingBuildResultId string
param appInsightName string
param laWorkspaceResourceId string
param customBuilderName string

resource asaInstance 'Microsoft.AppPlatform/Spring@2023-09-01-preview' = {
  name: asaInstanceName
  location: location
  tags: tags
  sku: {
    tier: 'Enterprise'
    name: 'E0'
  }
}

resource cartApp 'Microsoft.AppPlatform/Spring/apps@2023-09-01-preview' = {
  name: cartAppName
  location: location
  parent: asaInstance
  properties: {
    public: true
    activeDeploymentName: 'default'
  }
}


resource cartDeployment 'Microsoft.AppPlatform/Spring/apps/deployments@2023-09-01-preview' = {
  name: 'default'
  parent: cartApp
  properties: {
    source: {
      type: 'BuildResult'
      buildResultId: cartBuildResultId
    }
    deploymentSettings: {
      resourceRequests: {
        cpu: '2'
        memory: '4Gi'
      }
      environmentVariables: {
		CART_PORT: 8080
	  }
    }
  }
}

resource orderApp 'Microsoft.AppPlatform/Spring/apps@2023-09-01-preview' = {
  name: orderAppName
  location: location
  parent: asaInstance
  properties: {
    public: true
    activeDeploymentName: 'default'
  }
}


resource orderDeployment 'Microsoft.AppPlatform/Spring/apps/deployments@2023-09-01-preview' = {
  name: 'default'
  parent: orderApp
  properties: {
    source: {
      type: 'BuildResult'
      buildResultId: orderBuildResultId
    }
    deploymentSettings: {
      resourceRequests: {
        cpu: '2'
        memory: '4Gi'
      }
    }
  }
}

resource shoppingApp 'Microsoft.AppPlatform/Spring/apps@2023-09-01-preview' = {
  name: shoppingAppName
  location: location
  parent: asaInstance
  properties: {
    public: true
    activeDeploymentName: 'default'
  }
}


resource shoppingDeployment 'Microsoft.AppPlatform/Spring/apps/deployments@2023-09-01-preview' = {
  name: 'default'
  parent: shoppingApp
  properties: {
    source: {
      type: 'BuildResult'
      buildResultId: shoppingBuildResultId
    }
    deploymentSettings: {
      resourceRequests: {
        cpu: '2'
        memory: '4Gi'
      }
    }
  }
}

resource buildService 'Microsoft.AppPlatform/Spring/buildServices@2023-09-01-preview' = {
  name: '${asaInstance.name}/default'
  properties: {
    resourceRequests: {}
  }
  dependsOn: [
    asaInstance
  ]
}

resource builder 'Microsoft.AppPlatform/Spring/buildServices/builders@2023-03-01-preview' = {
  name: customBuilderName
  parent: buildService
  properties: {
    buildpackGroups: [
      {
        buildpacks: [
          {
			id: 'tanzu-buildpacks/java-azure'
		  }
		  {
			id: 'tanzu-buildpacks/dotnet-core'
		  }
		  {
		    id: 'tanzu-buildpacks/go'
		  }
	      {
			id: 'tanzu-buildpacks/web-servers'
		  }
		  {
			id: 'tanzu-buildpacks/nodejs'
		  }
		  {
		    id: 'tanzu-buildpacks/python'
		  }
        ]
        name: 'default'
      }
    ]
    stack: {
      id: 'io.buildpacks.stacks.bionic'
      version: 'base'
    }
  }
}

resource buildAgentPool 'Microsoft.AppPlatform/Spring/buildServices/agentPools@2023-09-01-preview' = {
  name: '${asaInstance.name}/default/default'
  properties: {
    poolSize: {
      name: 'S2'
    }
  }
  dependsOn: [
    buildService
  ]
}
resource springAppsDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'monitoring'
  scope: asaInstance
  properties: {
    workspaceId: laWorkspaceResourceId
    logs: [
      {
        category: 'ApplicationConsole'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
    ]
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!(empty(appInsightName))) {
  name: appInsightName
}



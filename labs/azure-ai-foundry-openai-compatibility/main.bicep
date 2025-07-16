// ------------------
//    PARAMETERS
// ------------------

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('The SKU for the APIM instance')
param apimSku string = 'Consumption'

@description('Configuration array for APIM subscriptions')
param apimSubscriptionsConfig array = [
  {
    name: 'cline-extension'
    displayName: 'Cline Extension Subscription'
    state: 'active'
    allowTracing: true
  }
  {
    name: 'dev-tools'
    displayName: 'Development Tools Subscription'
    state: 'active'
    allowTracing: true
  }
]

@description('Azure AI Foundry project configuration')
param aiFoundryConfig object = {
  projectName: ''
  resourceGroupName: ''
  subscriptionId: subscription().id
}

@description('The tags for the resources')
param tagValues object = {}

@description('Name of the APIM Logger')
param apimLoggerName string = 'apim-logger'

// ------------------
//    VARIABLES
// ------------------

var resourceSuffix = uniqueString(subscription().id, resourceGroup().id)
var apiManagementName = 'apim-${resourceSuffix}'
var azureAIFoundryAPIName = 'azure-ai-foundry-api'

var logSettings = {
  request: {
    headers: [ 'Content-type', 'User-agent', 'x-ms-region', 'x-ratelimit-remaining-tokens', 'x-ratelimit-remaining-requests' ]
    body: { bytes: 8192 }
  }
  response: {
    headers: [ 'Content-type', 'x-ms-region', 'x-ratelimit-remaining-tokens', 'x-ratelimit-remaining-requests' ]
    body: { bytes: 8192 }
  }
}

var policyXml = loadTextContent('policy.xml')

// ------------------
//    RESOURCES
// ------------------

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${resourceSuffix}'
  location: location
  tags: tagValues
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${resourceSuffix}'
  location: location
  tags: tagValues
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource apiManagement 'Microsoft.ApiManagement/service@2023-09-01-preview' = {
  name: apiManagementName
  location: location
  tags: tagValues
  sku: {
    capacity: apimSku == 'Consumption' ? 0 : 1
    name: apimSku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: 'admin@contoso.com'
    publisherName: 'Contoso'
  }
}

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2023-09-01-preview' = {
  name: apimLoggerName
  parent: apiManagement
  properties: {
    loggerType: 'applicationInsights'
    resourceId: applicationInsights.id
    credentials: {
      instrumentationKey: applicationInsights.properties.InstrumentationKey
    }
  }
}

// Azure AI Foundry backend
resource azureAIFoundryBackend 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: 'azure-ai-foundry-backend'
  parent: apiManagement
  properties: {
    description: 'Azure AI Foundry Backend for OpenAI Compatibility'
    url: !empty(aiFoundryConfig.projectName) ? 'https://${aiFoundryConfig.projectName}.${location}.models.ai.azure.com' : 'https://placeholder.eastus.models.ai.azure.com'
    protocol: 'http'
    credentials: {
      header: {
        'Content-Type': ['application/json']
      }
    }
  }
}

// Azure AI Foundry API
resource azureAIFoundryAPI 'Microsoft.ApiManagement/service/apis@2023-09-01-preview' = {
  name: azureAIFoundryAPIName
  parent: apiManagement
  properties: {
    displayName: 'Azure AI Foundry OpenAI Compatible API'
    path: 'azure-ai-foundry'
    protocols: ['https']
    description: 'Azure AI Foundry API with OpenAI compatibility for VS Code extensions'
    subscriptionRequired: true
    format: 'openapi+json'
    value: '''
{
  "openapi": "3.0.0",
  "info": {
    "title": "Azure AI Foundry OpenAI Compatible API",
    "version": "1.0.0",
    "description": "OpenAI-compatible API for Azure AI Foundry models"
  },
  "paths": {
    "/chat/completions": {
      "post": {
        "summary": "Create chat completion",
        "operationId": "createChatCompletion",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "required": ["messages"],
                "properties": {
                  "model": {"type": "string", "description": "Model deployment name"},
                  "messages": {"type": "array"},
                  "temperature": {"type": "number"},
                  "max_tokens": {"type": "integer"},
                  "stream": {"type": "boolean"}
                }
              }
            }
          }
        },
        "responses": {
          "200": {"description": "Successful response"}
        }
      }
    },
    "/deployments/{deployment_name}/chat/completions": {
      "post": {
        "summary": "Create chat completion with deployment",
        "operationId": "createChatCompletionWithDeployment",
        "parameters": [
          {
            "name": "deployment_name",
            "in": "path",
            "required": true,
            "schema": {"type": "string"}
          }
        ],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "required": ["messages"],
                "properties": {
                  "messages": {"type": "array"},
                  "temperature": {"type": "number"},
                  "max_tokens": {"type": "integer"},
                  "stream": {"type": "boolean"}
                }
              }
            }
          }
        },
        "responses": {
          "200": {"description": "Successful response"}
        }
      }
    }
  }
}'''
  }
}

// Apply policy to API
resource azureAIFoundryAPIPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-09-01-preview' = {
  name: 'policy'
  parent: azureAIFoundryAPI
  properties: {
    value: policyXml
    format: 'xml'
  }
}

// Diagnostic settings for the API
resource azureAIFoundryAPIDiagnostic 'Microsoft.ApiManagement/service/apis/diagnostics@2023-09-01-preview' = {
  name: 'applicationinsights'
  parent: azureAIFoundryAPI
  properties: {
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'W3C'
    logClientIp: true
    loggerId: apimLogger.id
    metrics: true
    verbosity: 'information'
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: logSettings
    backend: logSettings
  }
}

// APIM Subscriptions
resource apimSubscriptions 'Microsoft.ApiManagement/service/subscriptions@2023-09-01-preview' = [for subscription in apimSubscriptionsConfig: {
  name: subscription.name
  parent: apiManagement
  properties: {
    displayName: subscription.displayName
    state: subscription.state
    allowTracing: subscription.allowTracing
    scope: '/apis'
  }
}]

// ------------------
//    OUTPUTS
// ------------------

output apimServiceName string = apiManagement.name
output apimResourceGatewayURL string = apiManagement.properties.gatewayUrl
output apimSubscriptionKeys array = [for (subscription, i) in apimSubscriptionsConfig: {
  name: subscription.name
  primaryKey: apimSubscriptions[i].listSecrets().primaryKey
  secondaryKey: apimSubscriptions[i].listSecrets().secondaryKey
}]

// OpenAI-compatible endpoints for VS Code extensions
output openaiCompatibleEndpoints object = {
  baseUrl: '${apiManagement.properties.gatewayUrl}/${azureAIFoundryAPIName}'
  chatCompletionsUrl: '${apiManagement.properties.gatewayUrl}/${azureAIFoundryAPIName}/chat/completions'
  deploymentUrlTemplate: '${apiManagement.properties.gatewayUrl}/${azureAIFoundryAPIName}/deployments/{deployment-name}/chat/completions'
}

// Configuration examples for popular VS Code extensions
output vsCodeExtensionConfigs object = {
  clineExtension: {
    description: 'Configuration for Cline Extension'
    settings: {
      'claude-dev.apiBaseUrl': '${apiManagement.properties.gatewayUrl}/${azureAIFoundryAPIName}'
      'claude-dev.apiKey': apimSubscriptions[0].listSecrets().primaryKey
      'claude-dev.modelName': 'gpt-4o'
    }
  }
  copilotExtension: {
    description: 'Configuration for GitHub Copilot-like extensions'
    settings: {
      'openai.apiBase': '${apiManagement.properties.gatewayUrl}/${azureAIFoundryAPIName}'
      'openai.apiKey': apimSubscriptions[0].listSecrets().primaryKey
      'openai.model': 'gpt-4o'
    }
  }
  genericOpenAI: {
    description: 'Generic OpenAI-compatible configuration'
    endpoint: '${apiManagement.properties.gatewayUrl}/${azureAIFoundryAPIName}/deployments/gpt-4o'
    apiKey: apimSubscriptions[0].listSecrets().primaryKey
    model: 'gpt-4o'
  }
}
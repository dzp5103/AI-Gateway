# VS Code Extensions Configuration Guide

This guide explains how to configure various VS Code extensions to work with Azure AI Foundry through Azure API Management for OpenAI compatibility.

## 🎯 Quick Start

After deploying the lab infrastructure, you'll have:
- **Base URL**: `https://your-apim-gateway.azure-api.net/azure-ai-foundry`
- **API Key**: Your Azure API Management subscription key
- **Models**: Available through deployment-specific endpoints

## 🔧 Extension-Specific Configurations

### Cline Extension (claude-dev)

The Cline extension is a popular AI coding assistant for VS Code.

**Settings.json Configuration:**
```json
{
  "claude-dev.apiBaseUrl": "https://your-apim-gateway.azure-api.net/azure-ai-foundry",
  "claude-dev.apiKey": "your-apim-subscription-key",
  "claude-dev.modelName": "gpt-4o"
}
```

**Extension Settings UI:**
1. Open VS Code Settings (Ctrl+,)
2. Search for "claude-dev"
3. Set:
   - **API Base URL**: `https://your-apim-gateway.azure-api.net/azure-ai-foundry`
   - **API Key**: Your subscription key
   - **Model Name**: `gpt-4o` (or your preferred model)

### GitHub Copilot Chat

For GitHub Copilot Chat or similar extensions:

```json
{
  "github.copilot.advanced": {
    "debug.overrideEngine": "gpt-4o",
    "debug.overrideProxyUrl": "https://your-apim-gateway.azure-api.net/azure-ai-foundry"
  }
}
```

### Continue (VS Code Extension)

For the Continue extension:

```json
{
  "continue.serverUrl": "https://your-apim-gateway.azure-api.net/azure-ai-foundry",
  "continue.apiKey": "your-apim-subscription-key",
  "continue.model": "gpt-4o"
}
```

### Generic OpenAI-Compatible Extensions

For extensions that support custom OpenAI endpoints:

```json
{
  "openai.apiBase": "https://your-apim-gateway.azure-api.net/azure-ai-foundry",
  "openai.apiKey": "your-apim-subscription-key",
  "openai.model": "gpt-4o",
  "openai.apiVersion": "2024-02-01"
}
```

## 🔄 Model Switching Strategies

### Method 1: Deployment-Specific Endpoints

Use different endpoints for different models:

```json
{
  "gpt4-endpoint": "https://your-apim-gateway.azure-api.net/azure-ai-foundry/deployments/gpt-4o/chat/completions",
  "gpt35-endpoint": "https://your-apim-gateway.azure-api.net/azure-ai-foundry/deployments/gpt-35-turbo/chat/completions",
  "gpt4-mini-endpoint": "https://your-apim-gateway.azure-api.net/azure-ai-foundry/deployments/gpt-4o-mini/chat/completions"
}
```

### Method 2: Model Name in Request Body

Configure the extension to use the base URL and send model name in the request:

```json
{
  "apiBaseUrl": "https://your-apim-gateway.azure-api.net/azure-ai-foundry",
  "modelName": "gpt-4o"  // Change this to switch models
}
```

### Method 3: Multiple Profiles

Create multiple VS Code profiles or workspace settings for different models:

**Profile 1 (GPT-4o):**
```json
{
  "claude-dev.modelName": "gpt-4o"
}
```

**Profile 2 (GPT-3.5-turbo):**
```json
{
  "claude-dev.modelName": "gpt-35-turbo"
}
```

## 🛠️ Advanced Configuration

### Custom Headers

Some extensions allow custom headers. You can use either:

**Subscription Key Header:**
```json
{
  "customHeaders": {
    "Ocp-Apim-Subscription-Key": "your-subscription-key"
  }
}
```

**Authorization Header:**
```json
{
  "customHeaders": {
    "Authorization": "Bearer your-subscription-key"
  }
}
```

### Rate Limiting

Configure your extensions to respect rate limits:

```json
{
  "requestsPerMinute": 60,
  "tokensPerMinute": 10000,
  "retryOnRateLimit": true
}
```

### Streaming Support

Enable streaming for real-time responses:

```json
{
  "enableStreaming": true,
  "streamingTimeout": 30000
}
```

## 🔍 Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify your subscription key is correct
   - Check that the subscription is active in APIM
   - Ensure the key hasn't expired

2. **Model Not Found**
   - Verify the model deployment exists in your Azure AI Foundry project
   - Check the deployment name matches exactly
   - Ensure the model is available in your region

3. **Network Errors**
   - Check firewall/proxy settings
   - Verify the APIM gateway URL is accessible
   - Test with a simple HTTP client first

4. **Rate Limiting**
   - Check your token limits in APIM policies
   - Monitor usage in Application Insights
   - Consider upgrading your APIM tier

### Testing Your Configuration

Use this simple test to verify your setup:

```bash
curl -X POST "https://your-apim-gateway.azure-api.net/azure-ai-foundry/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Ocp-Apim-Subscription-Key: your-subscription-key" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {"role": "user", "content": "Hello, are you working?"}
    ],
    "max_tokens": 50
  }'
```

## 📊 Monitoring Extension Usage

### Application Insights Queries

Monitor your VS Code extension usage with these KQL queries:

**Requests by Extension:**
```kql
requests
| extend ClientType = case(
    customDimensions["User-Agent"] contains "vscode", "VS Code",
    customDimensions["User-Agent"] contains "claude-dev", "Cline Extension",
    "Unknown"
)
| summarize count() by ClientType
```

**Token Usage by Model:**
```kql
customMetrics
| where name == "llm.usage.total_tokens"
| summarize sum(value) by tostring(customDimensions.Model)
```

**Error Rate by Extension:**
```kql
requests
| where resultCode >= 400
| extend ClientType = case(
    customDimensions["User-Agent"] contains "vscode", "VS Code",
    customDimensions["User-Agent"] contains "claude-dev", "Cline Extension",
    "Unknown"
)
| summarize ErrorCount = count(), TotalRequests = countif(true) by ClientType
| extend ErrorRate = ErrorCount * 100.0 / TotalRequests
```

## 🚀 Best Practices

### Security
- Rotate subscription keys regularly
- Use different subscriptions for different environments
- Monitor for unusual usage patterns
- Implement IP restrictions if needed

### Performance
- Use appropriate models for different tasks
- Configure reasonable token limits
- Enable caching where possible
- Monitor response times

### Cost Management
- Set up alerts for high token usage
- Use smaller models for simple tasks
- Implement usage quotas per subscription
- Monitor costs in Azure Cost Management

### Development Workflow
- Use development subscriptions for testing
- Create separate APIM instances for prod/dev
- Version your configurations
- Document your model choices

## 📝 Example Configurations Repository

Create a configurations repository with examples:

```
vscode-configs/
├── cline-extension/
│   ├── settings.json
│   └── README.md
├── continue/
│   ├── config.json
│   └── README.md
├── generic-openai/
│   ├── settings.json
│   └── README.md
└── troubleshooting/
    ├── test-scripts/
    └── common-issues.md
```

This structure helps team members quickly find and apply the right configuration for their needs.

## 🔗 Additional Resources

- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-foundry/)
- [Azure API Management Documentation](https://learn.microsoft.com/azure/api-management/)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [VS Code Extension Development](https://code.visualstudio.com/api)
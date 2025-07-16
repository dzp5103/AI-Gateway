# VS Code Settings Examples

This directory contains example VS Code settings configurations for popular AI extensions that work with Azure AI Foundry through Azure API Management.

## 📁 Files

### [cline-extension-settings.json](./cline-extension-settings.json)
Configuration for the [Cline Extension](https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev) - a popular AI coding assistant.

### [continue-extension-settings.json](./continue-extension-settings.json)
Configuration for the [Continue Extension](https://marketplace.visualstudio.com/items?itemName=Continue.continue) - an open-source AI code assistant.

### [generic-openai-settings.json](./generic-openai-settings.json)
Generic configuration patterns that work with most OpenAI-compatible VS Code extensions.

## 🚀 How to Use

1. **Deploy the lab infrastructure** using the main Jupyter notebook
2. **Get your configuration values** from the deployment outputs:
   - APIM Gateway URL
   - Subscription Key
   - Available models
3. **Choose the appropriate settings file** for your extension
4. **Replace the placeholder values** with your actual configuration
5. **Add the settings** to your VS Code configuration

## 📍 Where to Add Settings

### User Settings (Global)
Add to your global VS Code settings:
- **Windows**: `%APPDATA%\Code\User\settings.json`
- **macOS**: `~/Library/Application Support/Code/User/settings.json`
- **Linux**: `~/.config/Code/User/settings.json`

### Workspace Settings (Project-specific)
Create `.vscode/settings.json` in your project root for project-specific configurations.

### VS Code Profiles
Use VS Code profiles to manage different configurations for different use cases.

## 🔄 Model Switching

### Method 1: Change Model Name
```json
{
  "claude-dev.modelName": "gpt-4o"  // Change to "gpt-35-turbo", "gpt-4o-mini", etc.
}
```

### Method 2: Use Deployment-Specific Endpoints
```json
{
  "claude-dev.apiBaseUrl": "https://your-apim-gateway.azure-api.net/azure-ai-foundry/deployments/gpt-4o"
}
```

### Method 3: Multiple Profiles
Create different VS Code profiles for different models and switch between them as needed.

## 🛠️ Troubleshooting

### Common Issues

1. **Extension not connecting**
   - Verify your APIM gateway URL is correct
   - Check that your subscription key is valid
   - Ensure the subscription is active in APIM

2. **Model not found errors**
   - Verify the model deployment exists in Azure AI Foundry
   - Check the model name matches exactly
   - Ensure the model is available in your region

3. **Rate limiting**
   - Check your token limits in APIM policies
   - Consider upgrading your APIM tier
   - Monitor usage in Application Insights

### Testing Your Configuration

Use the provided test script to verify your setup:
```bash
python test_compatibility.py https://your-apim-gateway.azure-api.net/azure-ai-foundry your-subscription-key gpt-4o
```

## 📚 Additional Resources

- [VS Code Extensions Configuration Guide](../VSCODE_EXTENSIONS_GUIDE.md)
- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-foundry/)
- [Azure API Management Documentation](https://learn.microsoft.com/azure/api-management/)
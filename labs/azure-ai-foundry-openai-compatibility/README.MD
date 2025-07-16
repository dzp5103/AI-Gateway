# APIM ❤️ Azure AI Foundry

## [Azure AI Foundry OpenAI Compatibility lab](azure-ai-foundry-openai-compatibility.ipynb)

![flow](../../images/azure-ai-foundry-openai-compatibility.gif)

Playground to configure [Azure AI Foundry](https://azure.microsoft.com/en-us/products/ai-foundry) with Azure API Management for optimal OpenAI API compatibility with VS Code extensions like [Cline](https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev), LangChain, and other OpenAI-compatible clients. This lab demonstrates how to set up endpoints, configure model switching through deployment names, and provide seamless integration for development tools.

### Key Features

- ✅ **OpenAI API Compatibility**: Full compatibility with OpenAI SDK and extensions
- 🔄 **Model Switching**: Switch models by changing deployment names in the endpoint
- 🔧 **VS Code Extension Ready**: Optimized for Cline and other AI coding assistants
- 🛡️ **Secure**: Uses managed identity and Azure API Management for security
- 📊 **Monitoring**: Built-in token tracking and usage analytics

### VS Code Extension Configuration Example

For Cline Extension:
```json
{
  "claude-dev.apiBaseUrl": "https://your-apim-gateway.azure-api.net/azure-ai-foundry",
  "claude-dev.apiKey": "your-apim-subscription-key",
  "claude-dev.modelName": "gpt-4o"
}
```

For other OpenAI-compatible extensions:
- **Endpoint**: `https://your-apim-gateway.azure-api.net/azure-ai-foundry/deployments/{deployment-name}`
- **API Key**: Your Azure API Management subscription key
- **Model**: Deployment name (e.g., `gpt-4o`, `gpt-35-turbo`)

### Prerequisites

- [Python 3.12 or later version](https://www.python.org/) installed
- [VS Code](https://code.visualstudio.com/) installed with the [Jupyter notebook extension](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter) enabled
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed
- [An Azure Subscription](https://azure.microsoft.com/free/) with Contributor permissions
- [Sign in to Azure with Azure CLI](https://learn.microsoft.com/cli/azure/authenticate-azure-cli-interactively)
- Azure AI Foundry project with deployed models

### 🚀 Get started

Proceed by opening the [Jupyter notebook](azure-ai-foundry-openai-compatibility.ipynb), and follow the steps provided.

### 🧪 Quick Test

After deployment, you can quickly test your setup using the provided test script:

```bash
python test_compatibility.py https://your-apim-gateway.azure-api.net/azure-ai-foundry your-subscription-key gpt-4o
```

### 🗑️ Clean up resources

When you're finished with the lab, you should remove all your deployed resources from Azure to avoid extra charges and keep your Azure subscription uncluttered.
Use the [clean-up-resources notebook](clean-up-resources.ipynb) for that.
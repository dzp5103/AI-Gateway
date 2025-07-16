# Troubleshooting Guide

This guide helps you diagnose and resolve common issues when using Azure AI Foundry with VS Code extensions through Azure API Management.

## 🔍 Quick Diagnostics

### Step 1: Test Basic Connectivity
```bash
# Test if APIM gateway is accessible
curl -I https://your-apim-gateway.azure-api.net/status-0123456789abcdef

# Expected: HTTP 200 or 404 (both indicate gateway is reachable)
```

### Step 2: Test Authentication
```bash
# Test with valid subscription key
curl -X POST "https://your-apim-gateway.azure-api.net/azure-ai-foundry/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Ocp-Apim-Subscription-Key: your-subscription-key" \
  -d '{"model":"gpt-4o","messages":[{"role":"user","content":"test"}],"max_tokens":10}'

# Expected: HTTP 200 with chat completion response
```

### Step 3: Validate Configuration
Use the provided test script:
```bash
python test_compatibility.py https://your-apim-gateway.azure-api.net/azure-ai-foundry your-subscription-key gpt-4o
```

## ❌ Common Error Messages

### "Connection timed out" or "Network error"

**Possible Causes:**
- APIM gateway is not accessible
- Firewall/proxy blocking connections
- Incorrect URL

**Solutions:**
1. Verify APIM gateway URL is correct
2. Check your network/firewall settings
3. Try from a different network
4. Ensure APIM instance is running

```bash
# Test basic connectivity
ping your-apim-gateway.azure-api.net
curl -I https://your-apim-gateway.azure-api.net
```

### "401 Unauthorized" or "Access denied"

**Possible Causes:**
- Invalid subscription key
- Subscription is suspended/deleted
- Incorrect header format

**Solutions:**
1. Verify subscription key in Azure portal
2. Check subscription status in APIM
3. Ensure key hasn't expired

```bash
# List APIM subscriptions
az apim subscription list --service-name your-apim-name --resource-group your-rg

# Check subscription details
az apim subscription show --service-name your-apim-name --resource-group your-rg --sid your-subscription-id
```

### "404 Not Found" or "API not found"

**Possible Causes:**
- Incorrect API path
- API not deployed
- Wrong APIM instance

**Solutions:**
1. Verify the API path is `/azure-ai-foundry`
2. Check API exists in APIM portal
3. Ensure using correct APIM gateway URL

```bash
# List APIs in APIM
az apim api list --service-name your-apim-name --resource-group your-rg --output table
```

### "Model 'xyz' not found" or "Deployment not found"

**Possible Causes:**
- Model not deployed in Azure AI Foundry
- Incorrect model name
- Model not available in region

**Solutions:**
1. Verify model deployment in Azure AI Foundry
2. Check model name spelling
3. Ensure model is available in your region

```bash
# List AI Foundry deployments
az ml model list --workspace-name your-workspace --resource-group your-rg
```

### "429 Too Many Requests" or "Rate limit exceeded"

**Possible Causes:**
- Hitting APIM rate limits
- Hitting Azure AI Foundry quotas
- Too many concurrent requests

**Solutions:**
1. Check APIM policies for rate limits
2. Reduce request frequency
3. Consider upgrading APIM tier
4. Monitor usage in Application Insights

```bash
# Check APIM policies
az apim api policy show --service-name your-apim-name --resource-group your-rg --api-id azure-ai-foundry-api
```

### "500 Internal Server Error" or "Backend service error"

**Possible Causes:**
- Azure AI Foundry service issues
- APIM policy errors
- Backend configuration problems

**Solutions:**
1. Check Azure service health
2. Review APIM logs in Application Insights
3. Verify backend configuration
4. Check APIM policy syntax

## 🔧 Extension-Specific Issues

### Cline Extension

**Issue**: Extension shows "API Error" or doesn't respond
```json
// Check these settings in VS Code settings.json
{
  "claude-dev.apiBaseUrl": "https://your-apim-gateway.azure-api.net/azure-ai-foundry",
  "claude-dev.apiKey": "your-subscription-key",
  "claude-dev.modelName": "gpt-4o"
}
```

**Issue**: "Invalid model" error
- Ensure model name matches your Azure AI Foundry deployment
- Try with different model: `gpt-35-turbo`, `gpt-4o-mini`

### Continue Extension

**Issue**: Extension not connecting
```json
// Verify these settings
{
  "continue.serverUrl": "https://your-apim-gateway.azure-api.net/azure-ai-foundry",
  "continue.apiKey": "your-subscription-key"
}
```

**Issue**: Slow responses
- Reduce `continue.maxTokens` value
- Increase `continue.timeout` setting

### Generic OpenAI Extensions

**Issue**: "Unsupported API version"
- Add API version header: `"openai.apiVersion": "2024-02-01"`
- Try different base URLs

## 📊 Monitoring and Debugging

### Application Insights Queries

**Check recent errors:**
```kql
requests
| where resultCode >= 400
| order by timestamp desc
| take 20
```

**Monitor token usage:**
```kql
customMetrics
| where name == "llm.usage.total_tokens"
| summarize sum(value) by bin(timestamp, 1h)
```

**Check response times:**
```kql
requests
| summarize avg(duration) by bin(timestamp, 5m)
| render timechart
```

### APIM Gateway Logs

Enable and check APIM gateway logs:
```bash
# Enable diagnostic settings
az monitor diagnostic-settings create \
  --resource your-apim-resource-id \
  --name "apim-diagnostics" \
  --logs '[{"category":"GatewayLogs","enabled":true}]' \
  --workspace your-log-analytics-workspace-id
```

### Testing Different Endpoints

**Test chat completions (model in body):**
```bash
curl -X POST "https://your-apim-gateway.azure-api.net/azure-ai-foundry/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Ocp-Apim-Subscription-Key: your-key" \
  -d '{"model":"gpt-4o","messages":[{"role":"user","content":"Hello"}],"max_tokens":50}'
```

**Test deployment-specific endpoint:**
```bash
curl -X POST "https://your-apim-gateway.azure-api.net/azure-ai-foundry/deployments/gpt-4o/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Ocp-Apim-Subscription-Key: your-key" \
  -d '{"messages":[{"role":"user","content":"Hello"}],"max_tokens":50}'
```

## 🛠️ Advanced Troubleshooting

### Enable APIM Tracing

For detailed request/response analysis:
```bash
# Enable tracing on subscription
az apim subscription update \
  --service-name your-apim-name \
  --resource-group your-rg \
  --sid your-subscription-id \
  --allow-tracing true
```

Then add header to requests:
```bash
curl -X POST "your-endpoint" \
  -H "Ocp-Apim-Trace: true" \
  -H "Ocp-Apim-Subscription-Key: your-key" \
  -d "your-payload"
```

### Policy Debugging

Add debug statements to APIM policies:
```xml
<set-variable name="debug-info" value="@($"Model: {context.Variables["deployment-name"]}")" />
<trace source="policy-debug">@((string)context.Variables["debug-info"])</trace>
```

### Network Diagnostics

**Check DNS resolution:**
```bash
nslookup your-apim-gateway.azure-api.net
```

**Test with different protocols:**
```bash
# Test HTTPS specifically
curl -v https://your-apim-gateway.azure-api.net/azure-ai-foundry/chat/completions
```

**Check certificates:**
```bash
openssl s_client -connect your-apim-gateway.azure-api.net:443 -servername your-apim-gateway.azure-api.net
```

## 📞 Getting Help

### Azure Support Resources

1. **Azure Service Health**: Check for known issues
2. **Azure Support**: Submit ticket for service-specific issues
3. **Azure Community**: Ask questions on forums

### Extension Support

1. **VS Code Extension Issues**: Report to extension maintainers
2. **GitHub Issues**: Check extension repositories
3. **Extension Documentation**: Review specific extension docs

### Self-Service Tools

1. **Azure Portal**: Check resource health and metrics
2. **Application Insights**: Monitor performance and errors
3. **APIM Portal**: Test APIs directly
4. **Test Script**: Use provided `test_compatibility.py`

## 📋 Diagnostic Checklist

Before reporting issues, gather this information:

- [ ] APIM gateway URL and subscription key (redacted)
- [ ] Model name and Azure AI Foundry project details
- [ ] Extension name and version
- [ ] Error message (full text)
- [ ] Request/response logs (if available)
- [ ] Application Insights correlation ID
- [ ] Steps to reproduce the issue
- [ ] Expected vs actual behavior

## 🔄 Recovery Procedures

### Reset Extension Configuration

1. Clear extension settings in VS Code
2. Restart VS Code
3. Reconfigure with fresh settings
4. Test with basic request

### Recreate APIM Resources

If APIM configuration is corrupted:
1. Export current configuration
2. Delete and recreate API
3. Reapply policies
4. Test functionality

### Failover Scenarios

For production environments:
1. Configure multiple APIM gateways
2. Use different Azure AI Foundry projects
3. Implement client-side retry logic
4. Monitor health endpoints
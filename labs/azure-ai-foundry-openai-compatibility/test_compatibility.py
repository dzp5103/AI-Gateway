#!/usr/bin/env python3
"""
Test script for Azure AI Foundry OpenAI Compatibility
This script validates the configuration and tests API connectivity
"""

import json
import sys
import os
import requests
from typing import Dict, Any

def test_openai_compatibility(base_url: str, api_key: str, model: str = "gpt-4o") -> Dict[str, Any]:
    """
    Test OpenAI API compatibility with Azure AI Foundry through APIM
    """
    results = {
        "tests": [],
        "summary": {"passed": 0, "failed": 0, "total": 0}
    }
    
    def add_test_result(name: str, success: bool, message: str, details: Any = None):
        results["tests"].append({
            "name": name,
            "success": success,
            "message": message,
            "details": details
        })
        if success:
            results["summary"]["passed"] += 1
        else:
            results["summary"]["failed"] += 1
        results["summary"]["total"] += 1
    
    # Test 1: Basic connectivity
    try:
        health_url = base_url.replace("/azure-ai-foundry", "") + "/status-0123456789abcdef"
        response = requests.get(health_url, timeout=10)
        add_test_result("Basic Connectivity", True, f"APIM gateway is accessible (status: {response.status_code})")
    except Exception as e:
        add_test_result("Basic Connectivity", False, f"Cannot reach APIM gateway: {str(e)}")
    
    # Test 2: Chat completions endpoint (model in body)
    try:
        chat_url = f"{base_url}/chat/completions"
        headers = {
            "Content-Type": "application/json",
            "Ocp-Apim-Subscription-Key": api_key
        }
        payload = {
            "model": model,
            "messages": [
                {"role": "user", "content": "Hello! This is a test. Please respond with 'Test successful'."}
            ],
            "max_tokens": 20,
            "temperature": 0.1
        }
        
        response = requests.post(chat_url, json=payload, headers=headers, timeout=30)
        
        if response.status_code == 200:
            data = response.json()
            content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
            add_test_result("Chat Completions (Model in Body)", True, 
                          f"Successfully completed chat with response: '{content[:50]}...'", data)
        else:
            add_test_result("Chat Completions (Model in Body)", False, 
                          f"HTTP {response.status_code}: {response.text}")
    except Exception as e:
        add_test_result("Chat Completions (Model in Body)", False, f"Request failed: {str(e)}")
    
    # Test 3: Deployment-specific endpoint
    try:
        deployment_url = f"{base_url}/deployments/{model}/chat/completions"
        payload = {
            "messages": [
                {"role": "user", "content": "Hello! This is a deployment-specific test."}
            ],
            "max_tokens": 20,
            "temperature": 0.1
        }
        
        response = requests.post(deployment_url, json=payload, headers=headers, timeout=30)
        
        if response.status_code == 200:
            data = response.json()
            content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
            add_test_result("Deployment-Specific Endpoint", True, 
                          f"Successfully completed chat with response: '{content[:50]}...'", data)
        else:
            add_test_result("Deployment-Specific Endpoint", False, 
                          f"HTTP {response.status_code}: {response.text}")
    except Exception as e:
        add_test_result("Deployment-Specific Endpoint", False, f"Request failed: {str(e)}")
    
    # Test 4: Error handling
    try:
        invalid_url = f"{base_url}/deployments/invalid-model/chat/completions"
        response = requests.post(invalid_url, json=payload, headers=headers, timeout=30)
        
        if response.status_code >= 400:
            add_test_result("Error Handling", True, 
                          f"Properly returned error for invalid model (HTTP {response.status_code})")
        else:
            add_test_result("Error Handling", False, 
                          f"Expected error for invalid model but got HTTP {response.status_code}")
    except Exception as e:
        add_test_result("Error Handling", True, f"Request properly failed as expected: {str(e)}")
    
    return results

def print_test_results(results: Dict[str, Any]):
    """Print test results in a readable format"""
    print("🧪 Azure AI Foundry OpenAI Compatibility Test Results")
    print("=" * 60)
    
    for test in results["tests"]:
        status = "✅" if test["success"] else "❌"
        print(f"{status} {test['name']}: {test['message']}")
    
    summary = results["summary"]
    print("\n📊 Summary")
    print("-" * 20)
    print(f"Total tests: {summary['total']}")
    print(f"Passed: {summary['passed']}")
    print(f"Failed: {summary['failed']}")
    
    if summary["failed"] == 0:
        print("\n🎉 All tests passed! Your configuration is working correctly.")
    else:
        print(f"\n⚠️  {summary['failed']} test(s) failed. Please check your configuration.")

def main():
    """Main function to run tests"""
    if len(sys.argv) < 3:
        print("Usage: python test_compatibility.py <base_url> <api_key> [model]")
        print("Example: python test_compatibility.py https://your-apim.azure-api.net/azure-ai-foundry your-subscription-key gpt-4o")
        sys.exit(1)
    
    base_url = sys.argv[1]
    api_key = sys.argv[2]
    model = sys.argv[3] if len(sys.argv) > 3 else "gpt-4o"
    
    print(f"🔍 Testing Azure AI Foundry OpenAI Compatibility")
    print(f"📍 Base URL: {base_url}")
    print(f"🎯 Model: {model}")
    print(f"🔑 API Key: {api_key[:8]}...")
    print()
    
    results = test_openai_compatibility(base_url, api_key, model)
    print_test_results(results)
    
    # Exit with error code if tests failed
    if results["summary"]["failed"] > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()
# Using BudgetFriendlyAzureAdvisor with GitHub Copilot

**Last Updated:** January 13, 2026  
**Integration Type:** MCP Server (Model Context Protocol)

## Overview

The BudgetFriendlyAzureAdvisor agent is now available as an **MCP server**, enabling seamless integration with GitHub Copilot Chat in VS Code. This provides a natural, conversational interface for Azure research while you code.

## Quick Setup

### 1. Start the Agent

```bash
cd src/BudgetFriendlyAzureAdvisor
dotnet run
```

The agent starts on `http://localhost:8087` with MCP endpoint at `/mcp`

### 2. Configure GitHub Copilot

Add the MCP server to your GitHub Copilot configuration:

**Location**: `.github/mcp-server-config.json` (already created)

```json
{
  "mcpServers": {
    "azure-advisor": {
      "url": "http://localhost:8087/mcp",
      "transport": "streamable-http",
      "name": "BudgetFriendlyAzureAdvisor",
      "description": "Azure research assistant focused on cost optimization and free tiers"
    }
  }
}
```

### 3. Use in Copilot Chat

Open GitHub Copilot Chat in VS Code and interact naturally:

```
@azure-advisor what's the free tier for Azure SQL Database?

@azure-advisor I need a cheap database for my POC - what are my options?

@azure-advisor calculate monthly cost for 3 SQL databases and 2 Function Apps

@azure-advisor research Azure Static Web Apps and create documentation

@azure-advisor list all documentation files

@azure-advisor read the azure-sql-free-tier.md file
```

## Example Conversations

### Research a New Service

```
You: @azure-advisor I'm building a POC with background workers. 
     What's the cheapest Azure service for this?

Agent: For background workers in a POC, here are your best FREE/LOW-COST options:
       
       1. Azure Functions (Consumption Plan) - FREE TIER
          - 1M executions/month free
          - 400,000 GB-s free
          - Perfect for POCs
          
       2. Azure Container Apps (Consumption Plan)
          - Scale to zero = $0 when idle
          - Pay only when running
       
       Would you like me to create detailed documentation for either of these?
```

### Cost Estimation

```
You: @azure-advisor calculate cost for:
     - 5 Azure SQL serverless databases
     - 3 Function Apps with light usage
     - 1 Static Web App

Agent: **Monthly Cost Estimate for Your POC**
       
       Azure SQL Serverless (5 databases):
       - Free tier: 100K vCore-sec/month per DB = FREE
       - Assuming light usage stays within limits = $0/month
       
       Azure Functions (3 apps):
       - Free tier: 1M executions shared = FREE
       - Assuming <1M total executions = $0/month
       
       Static Web App (1 app):
       - Free tier: 100GB bandwidth, custom domain = FREE
       - Standard POC usage = $0/month
       
       **TOTAL: $0/month** (within free tier limits)
       **Warning**: Monitor vCore usage on SQL databases to avoid overages
```

### Documentation Workflow

```
You: @azure-advisor research Azure Service Bus pricing 
     and create comprehensive documentation

Agent: [Researches using Microsoft Learn MCP tools]
       
       I've created documentation at docs/azure-service-bus-pricing.md
       
       Key findings:
       - Basic tier: $0.05/million operations
       - Standard tier: $10/month base + operations
       - Premium tier: Expensive, not POC-friendly
       
       Recommendation: Use Basic tier for POCs
       
       I've also updated docs/README.md with the new entry.
```

## Available Commands

The agent exposes the following capabilities through MCP:

| Command | Example |
|---------|---------|
| **Research** | `@azure-advisor research Azure Container Apps` |
| **List Docs** | `@azure-advisor list all documentation` |
| **Read Doc** | `@azure-advisor read azure-sql-free-tier.md` |
| **Create Doc** | `@azure-advisor create doc about Azure Functions` |
| **Calculate Cost** | `@azure-advisor calculate cost for my services` |
| **Compare** | `@azure-advisor compare SQL vs Cosmos DB for POCs` |

## Benefits of MCP Integration

### ✅ Natural Conversations
- Ask questions in plain English
- Context-aware responses
- Follow-up questions work naturally

### ✅ IDE Integration
- No context switching
- Access while coding
- Inline documentation

### ✅ Hybrid Approach
- MCP server for Copilot Chat
- HTTP API still available for scripts
- F5 debugging for development

### ✅ Tool Access
- All custom tools exposed
- Microsoft Learn integration
- File system operations

## Troubleshooting

### Agent Not Responding

```bash
# Check if agent is running
curl http://localhost:8087/health

# Restart agent
cd src/BudgetFriendlyAzureAdvisor
dotnet run
```

### MCP Server Not Found

1. Verify agent is running on port 8087
2. Check MCP endpoint: `http://localhost:8087/mcp`
3. Ensure GitHub Copilot configuration points to correct URL

### Authentication Errors

```bash
# Ensure Azure CLI is authenticated
az login

# Verify credentials
az account show
```

### No Tools Visible

The agent exposes a single tool called `BudgetFriendlyAzureAdvisor`. When you use `@azure-advisor` in Copilot Chat, it automatically invokes this tool with your query.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     VS Code + Copilot Chat                  │
│                                                             │
│  User: "@azure-advisor what's the free tier for SQL?"      │
└────────────────────────┬────────────────────────────────────┘
                         │ MCP Protocol
                         │ (Streamable HTTP)
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              BudgetFriendlyAzureAdvisor Agent               │
│                                                             │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ HTTP Server │  │  MCP Server  │  │  Agent Core      │  │
│  │ :8087       │  │  :8087/mcp   │  │  w/ 6 Tools      │  │
│  └─────────────┘  └──────────────┘  └──────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Microsoft Learn MCP Client                          │  │
│  │  (microsoft_docs_search, fetch, code_samples)        │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Microsoft Foundry (AI Model)                   │
│                     gpt-4o / gpt-4.1                        │
└─────────────────────────────────────────────────────────────┘
```

## Next Steps

1. **Start using**: Launch agent and try in Copilot Chat
2. **Configure environment**: Set up `.env` with your Foundry endpoint
3. **Explore workflows**: Research → Document → Calculate costs
4. **Build POCs**: Use agent to plan Azure architectures

## Related Documentation

- [Main Agent README](../src/BudgetFriendlyAzureAdvisor/README.md)
- [Quick Start Guide](./quick-start-agent.md)
- [Comprehensive Agent Documentation](./budget-friendly-azure-advisor-agent.md)
- [GitHub Copilot Instructions](../.github/copilot-instructions.md)

# Budget-Friendly Azure Advisor Agent

> **An AI Agent that helps you explore Azure services while keeping costs at $0-5/month**

## 🎯 What It Does

BudgetFriendlyAzureAdvisor is a .NET 10/C# AI agent that:

- ✅ **Researches Azure services** using Microsoft Learn documentation
- ✅ **Creates comprehensive guides** automatically in markdown format
- ✅ **Calculates costs** for service combinations
- ✅ **Recommends free-tier architectures** for POC projects
- ✅ **Updates documentation index** automatically
- ✅ **Reads existing docs** from your workspace

It's built on **Microsoft Agent Framework** and runs as an HTTP server for easy integration.

## 🚀 Quick Start

### Prerequisites

- **.NET 10 SDK** installed
- **Azure subscription** (for Microsoft Foundry)
- **Microsoft Foundry project** with a deployed model (GPT-4o recommended)
- **Azure CLI** installed and authenticated (`az login`)

### Setup

1. **Configure your environment**

   Create a `.env` file in this directory:

   ```env
   FOUNDRY_PROJECT_ENDPOINT=https://your-project.api.azureml.ms
   FOUNDRY_MODEL_DEPLOYMENT_NAME=gpt-4o
   ```

   Get these values from:
   - Microsoft Foundry extension in VS Code, OR
   - Azure AI Foundry portal at https://ai.azure.com

2. **Restore dependencies**

   ```bash
   dotnet restore
   ```

3. **Run the agent**

   ```bash
   dotnet run
   ```

   The agent HTTP server will start on `http://localhost:8087`

### Usage

#### Option 1: AI Toolkit Test Tool (Recommended for Development)

1. Press **F5** in VS Code to start debugging
2. AI Toolkit Test Tool will open automatically
3. Chat with the agent interactively

#### Option 2: HTTP Client

Send POST requests to `http://localhost:8087`:

```bash
curl -X POST http://localhost:8087 \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "What is the cheapest way to run background workers in Azure?"}
    ]
  }'
```

#### Option 3: Use as MCP Server

The agent can be integrated with other tools via Model Context Protocol.

## 💡 Example Queries

Try asking the agent:

- "What's the cheapest way to run background workers in Azure?"
- "Research Azure Functions free tier and create documentation"
- "Calculate the cost for 3 SQL databases, 2 static web apps, and 500K function executions"
- "Compare Azure Container Apps vs Azure App Service for a .NET API"
- "List all existing Azure documentation"
- "Read the azure-sql-free-tier.md file"

## 🛠️ Tools & Capabilities

The agent has access to:

### Custom Tools
- **ReadDocumentationFile** - Read existing Azure docs from `/docs`
- **ListDocumentationFiles** - See all available documentation
- **CreateDocumentationFile** - Generate new service guides
- **UpdateDocumentationIndex** - Update the main README
- **CalculateMonthlyAzureCost** - Estimate costs
- **SearchWebForPricing** - Get latest pricing info

### Microsoft Learn MCP Tools
- **microsoft_docs_search** - Search official Azure documentation
- **microsoft_docs_fetch** - Fetch complete doc pages
- **microsoft_code_sample_search** - Find official code examples

## 🏗️ Architecture

```
BudgetFriendlyAzureAdvisor/
├── Program.cs              # Main agent logic
├── BudgetFriendlyAzureAdvisor.csproj
├── .env                    # Configuration (you create this)
└── README.md              # This file
```

The agent:
1. Loads instructions from `/.github/copilot-instructions.md`
2. Connects to Microsoft Learn MCP server
3. Creates an AI agent with combined tools
4. Exposes HTTP endpoint at port 8087
5. Responds to chat messages with Azure guidance

## 🐛 Debugging

### VS Code (F5)

1. Open workspace in VS Code
2. Set breakpoints in `Program.cs`
3. Press **F5** to start debugging
4. AI Toolkit Test Tool opens for interactive testing
5. Debug as the agent processes requests

### Console Output

The agent logs:
- Workspace and docs folder paths
- MCP connection status
- Available tools count
- HTTP server URL

Check console for any startup errors.

## 📝 Cost Estimates

The agent uses these baseline costs (as of January 2026):

| Service | Free Tier | After Free Tier |
|---------|-----------|-----------------|
| **Azure SQL Database** | 10 databases × 100K vCore-sec/mo × 32GB | ~$4.78/month per database |
| **Azure Functions** | 1M executions/month | $0.20 per million executions |
| **Azure Storage** | 5GB, 20K transactions/month | ~$0.02/GB/month |
| **Azure Static Web Apps** | 100GB bandwidth/month | $9/month after |
| **Azure Service Bus** | N/A (pay-per-use) | ~$0.05/million operations |

## 🔧 Troubleshooting

### "FOUNDRY_PROJECT_ENDPOINT is not set"

Create a `.env` file with your Microsoft Foundry details:

```env
FOUNDRY_PROJECT_ENDPOINT=https://your-project.api.azureml.ms
FOUNDRY_MODEL_DEPLOYMENT_NAME=gpt-4o
```

### "Failed to authenticate with Azure"

Run `az login` in your terminal to authenticate with Azure CLI.

### "Cannot connect to Microsoft Learn MCP"

Check your internet connection. The agent needs to connect to `https://learn.microsoft.com/api/mcp`.

### Package restore issues

The agent requires preview packages. Ensure you have:
```bash
dotnet nuget add source https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-tools/nuget/v3/index.json
```

## 📚 Next Steps

Once the agent is running:

1. **Try basic queries** - "List all documentation files"
2. **Research a service** - "Research Azure Container Apps free tier"
3. **Calculate costs** - "Calculate cost for 5 SQL databases"
4. **Create documentation** - Agent will auto-create markdown files

The agent follows the patterns defined in your `.github/copilot-instructions.md` file.

## 🤝 Integration

### Use in Your Own Apps

The agent runs as an HTTP server, so you can call it from:
- Web applications
- CLI tools
- Other agents
- Automation scripts

### Example Integration

```csharp
using HttpClient client = new();
var response = await client.PostAsJsonAsync("http://localhost:8087", new
{
    messages = new[]
    {
        new { role = "user", content = "What's the cheapest Azure database option?" }
    }
});
var result = await response.Content.ReadAsStringAsync();
```

## 📄 License

This agent is part of the az-devops workspace for personal Azure exploration and POC development.

---

**Built with:** Microsoft Agent Framework for .NET 10  
**Model:** Microsoft Foundry (GPT-4o recommended)  
**MCP Server:** Microsoft Learn Documentation

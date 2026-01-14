# BudgetFriendlyAzureAdvisor Agent

**Last Updated:** January 13, 2026  
**Cost Level:** Free (for local execution)  
**Technology:** .NET 10 / C#, Microsoft Agent Framework

## Overview

The **BudgetFriendlyAzureAdvisor** is an AI agent specifically built to help you explore Azure services while maintaining minimal costs. It serves as your personal Azure research assistant, capable of reading existing documentation, researching new services, creating comprehensive guides, and calculating costs—all while following the cost-optimization principles defined in your workspace.

## Key Capabilities

### 📚 Documentation Management
- **Read existing docs** from the `/docs` folder
- **List all documentation** files
- **Create new comprehensive guides** for Azure services
- **Auto-update the documentation index**

### 🔍 Azure Research
- **Search Microsoft Learn** documentation via MCP tools
- **Fetch complete documentation pages**
- **Find official code samples**
- **Cross-reference pricing** information

### 💰 Cost Calculation
- **Estimate monthly costs** for service combinations
- **Calculate free tier usage** across multiple services
- **Provide transparent pricing breakdowns**
- **Warn about cost implications**

### 🎯 Architectural Guidance
- **Recommend free-tier** service combinations
- **Suggest POC-appropriate architectures**
- **Prioritize serverless and auto-pause** options
- **Optimize for $0-5/month** total cost

## Architecture

### Technology Stack
```
.NET 10 / C#
├── Microsoft Agent Framework (Agent creation & tools)
├── Azure.AI.Projects (Microsoft Foundry integration)
├── ModelContextProtocol (MCP client for Microsoft Learn)
├── ASP.NET Core (HTTP server)
└── Azure.Identity (DefaultAzureCredential authentication)
```

### Tools Available to the Agent

#### Custom File System Tools
1. **ReadDocumentationFile** - Read markdown files from `/docs`
2. **ListDocumentationFiles** - Get all available documentation
3. **CreateDocumentationFile** - Generate new Azure service guides
4. **UpdateDocumentationIndex** - Add entries to `/docs/README.md`
5. **CalculateMonthlyAzureCost** - Estimate costs for usage scenarios
6. **SearchWebForPricing** - Guide to latest pricing resources

#### Microsoft Learn MCP Tools
1. **microsoft_docs_search** - Search official Azure documentation
2. **microsoft_docs_fetch** - Retrieve complete documentation pages
3. **microsoft_code_sample_search** - Find official Azure code examples

### Agent Instructions

The agent loads its system instructions from [`.github/copilot-instructions.md`](../.github/copilot-instructions.md), which defines:
- Cost optimization priorities (free tier first)
- Documentation standards (structure, naming, format)
- Research approach (verify, compare, document)
- Architectural guidance (serverless, shared infrastructure)
- Response style (cost implications first, concrete numbers)

## Usage

### Local Development

1. **Configure environment**
   ```bash
   cd src/BudgetFriendlyAzureAdvisor
   cp .env.template .env
   # Edit .env with your Microsoft Foundry details
   ```

2. **Run the agent**
   ```bash
   dotnet run
   ```

3. **Send requests**
   ```bash
   curl -X POST http://localhost:8087 \
     -H "Content-Type: application/json" \
     -d '{
       "messages": [
         {"role": "user", "content": "What is the cheapest Azure database option?"}
       ]
     }'
   ```

### VS Code Debugging

Press **F5** in VS Code to:
- Start the agent with debugger attached
- Set breakpoints in `Program.cs`
- Inspect tool invocations
- Debug request/response flow

## Example Workflows

### Research New Azure Service
```
User: "Research Azure Container Apps consumption plan and create documentation"

Agent Workflow:
1. Calls microsoft_docs_search("Azure Container Apps consumption plan pricing")
2. Calls microsoft_docs_fetch(relevant_url)
3. Analyzes free tier and cost implications
4. Calls CreateDocumentationFile("azure-container-apps-consumption.md", content)
5. Calls UpdateDocumentationIndex("Azure Container Apps", ...)
6. Returns summary with link to new doc
```

### Calculate Multi-Service Cost
```
User: "Calculate cost for 3 SQL databases, 5 function apps, and 10GB storage"

Agent Workflow:
1. Calls CalculateMonthlyAzureCost with usage JSON
2. Returns detailed breakdown:
   - SQL: 3 databases (all free within limits) = $0.00
   - Functions: 5 apps in consumption plan (free tier) = $0.00
   - Storage: 10GB (5GB free, 5GB paid at $0.02/GB) = $0.10
   - Total: $0.10/month
```

### Compare Services
```
User: "Compare Azure Functions vs Azure Container Apps for background workers"

Agent Workflow:
1. Calls ReadDocumentationFile("azure-functions-free-tier.md") if exists
2. If not, researches both services
3. Compares:
   - Free tier availability
   - Cost per execution/hour
   - Best use cases
   - POC suitability
4. Recommends based on cost optimization
```

## Integration Points

### With Your Workspace
- **Reads from**: `/.github/copilot-instructions.md` (agent instructions)
- **Reads from**: `/docs/*.md` (existing documentation)
- **Writes to**: `/docs/*.md` (new documentation)
- **Updates**: `/docs/README.md` (documentation index)

### With Microsoft Foundry
- **Requires**: Deployed model (GPT-4o, GPT-4.1, or GPT-4o-mini)
- **Authentication**: Azure CLI (`az login`)
- **Cost**: ~$0.01-0.10 per interaction (depending on model and complexity)

### With Microsoft Learn
- **MCP Server**: https://learn.microsoft.com/api/mcp
- **Tools**: Search, Fetch, Code Samples
- **Cost**: Free (public API)

## Cost Analysis

### Running the Agent Locally
| Component | Monthly Cost |
|-----------|--------------|
| **Agent Execution** | $0.00 (local) |
| **Microsoft Foundry API Calls** | ~$1-3 (for 100-300 interactions) |
| **Microsoft Learn MCP** | $0.00 (free) |
| **Total** | **$1-3/month** |

### Production Deployment (Future)
If deployed to Azure:
| Component | Monthly Cost |
|-----------|--------------|
| **Azure Container Apps (Consumption)** | ~$0-2 |
| **Microsoft Foundry API Calls** | ~$5-10 (higher usage) |
| **Total** | **$5-12/month** |

## Limitations

### Current Limitations
- **No real web search** - `SearchWebForPricing` provides guidance only (not live search)
- **No direct Azure API calls** - Agent doesn't create/modify Azure resources
- **Local only** - Not yet containerized or deployed
- **Single-turn conversations** - No conversation history/memory

### Microsoft Foundry Requirements
- **Requires deployed model** - Must have active Microsoft Foundry project
- **Azure CLI authentication** - Must run `az login` first
- **Preview packages** - Uses preview .NET packages (may have breaking changes)

### Document Creation Constraints
- **Cannot overwrite** - Won't replace existing documentation files
- **Simple index updates** - Index updates use basic string replacement
- **No version control** - Doesn't commit changes to git

## Future Enhancements

### Short-Term (Next 1-2 weeks)
- [ ] Add real web search integration (Bing Search API)
- [ ] Implement conversation history/threads
- [ ] Add git commit support for documentation changes
- [ ] Create CLI wrapper for easier local use

### Medium-Term (Next 1-2 months)
- [ ] Containerize for Azure Container Apps deployment
- [ ] Add Azure resource cost tracking (actual usage monitoring)
- [ ] Implement Azure Resource Graph queries for real-time pricing
- [ ] Create VS Code extension integration

### Long-Term (3+ months)
- [ ] Multi-agent orchestration (separate research, writing, cost agents)
- [ ] Integration with Azure Cost Management API
- [ ] Automated architecture diagram generation
- [ ] Interactive architecture design workflow

## Troubleshooting

### Agent Won't Start
**Error**: "FOUNDRY_PROJECT_ENDPOINT is not set"
- **Fix**: Create `.env` file with your Microsoft Foundry details

**Error**: "Failed to authenticate with Azure"
- **Fix**: Run `az login` in terminal

### MCP Connection Issues
**Error**: "Cannot connect to Microsoft Learn MCP"
- **Fix**: Check internet connection
- **Fallback**: Agent will work with reduced capabilities (no MCP tools)

### Build Errors
**Error**: "Package restore failed"
- **Fix**: Run `dotnet restore` to download preview packages

**Error**: "EnablePreviewFeatures" warning
- **Expected**: Agent uses preview .NET packages (safe to ignore)

## Development Notes

### Adding New Tools

To add a custom tool to the agent:

1. **Define the function**:
   ```csharp
   [Description("Your tool description")]
   static string YourToolFunction(
       [Description("Parameter description")] string parameter)
   {
       // Your logic here
       return "Result";
   }
   ```

2. **Add to tools list**:
   ```csharp
   var customTools = new List<AITool>
   {
       // ... existing tools
       AIFunctionFactory.Create(YourToolFunction)
   };
   ```

3. **Rebuild and test**

### Modifying Agent Instructions

Edit [`.github/copilot-instructions.md`](../.github/copilot-instructions.md) to change:
- Agent personality and behavior
- Cost optimization rules
- Documentation standards
- Response patterns

Changes take effect on next agent restart.

## Related Documentation

- [Azure SQL Database Free Tier](../docs/azure-sql-free-tier.md)
- [Custom GitHub Copilot Instructions](../.github/copilot-instructions.md)
- [Documentation Index](../docs/README.md)

## Changelog

- **2026-01-13**: Initial agent creation
  - .NET 10/C# implementation
  - Microsoft Agent Framework integration
  - Microsoft Learn MCP tools
  - File system operations
  - Cost calculation capabilities
  - HTTP server mode
  - VS Code debugging support

# Quick Start: BudgetFriendlyAzureAdvisor Agent

Get up and running with the Azure advisor agent in 5 minutes!

## ⚡ Prerequisites Checklist

- [ ] **.NET 10 SDK** installed - [Download here](https://dotnet.microsoft.com/download/dotnet/10.0)
- [ ] **Azure CLI** installed - [Download here](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [ ] **Microsoft Foundry project** with deployed model - [Create at ai.azure.com](https://ai.azure.com)
- [ ] **VS Code** (recommended) - [Download here](https://code.visualstudio.com/)

## 🚀 5-Minute Setup

### Step 1: Get Your Microsoft Foundry Details

**Option A: Via Microsoft Foundry Extension (Easiest)**

1. Install "Microsoft Foundry" extension in VS Code
2. Open the extension, find your project
3. Click on your deployed model
4. Copy the endpoint and model name

**Option B: Via Azure Portal**

1. Go to https://ai.azure.com
2. Navigate to your project
3. Click "Deployments" → Select your model
4. Copy "Target URI" (endpoint) and "Deployment name"

### Step 2: Configure the Agent

```bash
cd c:\dev\tools\az-devops\src\BudgetFriendlyAzureAdvisor

# Copy the template
copy .env.template .env

# Edit .env with your details
notepad .env
```

Update these values:
```env
FOUNDRY_PROJECT_ENDPOINT=https://YOUR-PROJECT.api.azureml.ms
FOUNDRY_MODEL_DEPLOYMENT_NAME=gpt-4o
```

### Step 3: Authenticate with Azure

```bash
az login
```

This opens a browser window. Sign in with your Azure account.

### Step 4: Run the Agent

```bash
dotnet run
```

You should see:
```
📁 Workspace: c:\dev\tools\az-devops
📚 Docs folder: c:\dev\tools\az-devops\docs
🤖 Model: gpt-4o

🔌 Connecting to Microsoft Learn MCP server...
✅ Connected! 3 MCP tools available
🤖 Agent 'BudgetFriendlyAzureAdvisor' created successfully!

🚀 BudgetFriendlyAzureAdvisor HTTP server starting...
📡 Server URL: http://localhost:8087
```

### Step 5: Test It!

Open a new terminal and try:

```bash
curl -X POST http://localhost:8087 ^
  -H "Content-Type: application/json" ^
  -d "{\"messages\": [{\"role\": \"user\", \"content\": \"List all documentation files\"}]}"
```

## 💡 What to Try First

### 1. List Existing Docs
```json
{
  "messages": [
    {"role": "user", "content": "List all documentation files"}
  ]
}
```

### 2. Read a Doc
```json
{
  "messages": [
    {"role": "user", "content": "Read the azure-sql-free-tier.md file"}
  ]
}
```

### 3. Research a New Service
```json
{
  "messages": [
    {"role": "user", "content": "Research Azure Functions free tier and create documentation for it"}
  ]
}
```

### 4. Calculate Costs
```json
{
  "messages": [
    {"role": "user", "content": "Calculate the monthly cost for 3 SQL databases, 500,000 function executions, and 10GB of storage"}
  ]
}
```

### 5. Get Architecture Advice
```json
{
  "messages": [
    {"role": "user", "content": "What's the best free-tier architecture for a .NET API with a database?"}
  ]
}
```

## 🐛 Troubleshooting

### "FOUNDRY_PROJECT_ENDPOINT is not set"
- Make sure you created the `.env` file in the correct location
- Check that there are no typos in variable names
- Restart the agent after changing `.env`

### "Failed to authenticate"
- Run `az login` again
- Check that you have access to the Microsoft Foundry project
- Try `az account show` to verify which subscription is active

### "Cannot connect to Microsoft Learn MCP"
- Check your internet connection
- The agent will still work, but without MCP tools
- Try again in a few minutes (service may be temporarily unavailable)

### Build errors
```bash
# If packages won't restore
dotnet clean
dotnet restore --force

# If preview packages are missing
dotnet nuget add source https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-tools/nuget/v3/index.json
```

## 🎯 Next Steps

1. **Try VS Code Debugging**
   - Open workspace in VS Code
   - Press F5
   - Interactive debugging experience!

2. **Ask About Your Projects**
   - "What's the cheapest way to host a .NET Aspire application?"
   - "Compare Azure Service Bus vs RabbitMQ for microservices"
   - "What free-tier options exist for background workers?"

3. **Create Custom Documentation**
   - The agent will auto-create markdown files for services you research
   - All docs go into `/docs` folder
   - Index is auto-updated

4. **Integrate into Your Workflow**
   - Keep the agent running while you work
   - Ask questions as they come up
   - Let it handle Azure research for you

## 📚 Learn More

- **Full Documentation**: [budget-friendly-azure-advisor-agent.md](budget-friendly-azure-advisor-agent.md)
- **Agent Instructions**: [../.github/copilot-instructions.md](../.github/copilot-instructions.md)
- **Azure SQL Guide**: [azure-sql-free-tier.md](azure-sql-free-tier.md)
- **Documentation Index**: [README.md](README.md)

## 💬 Example Session

```bash
# Terminal 1: Start the agent
C:\dev\tools\az-devops\src\BudgetFriendlyAzureAdvisor> dotnet run

# Terminal 2: Interact with it
curl -X POST http://localhost:8087 -H "Content-Type: application/json" -d "{\"messages\": [{\"role\": \"user\", \"content\": \"What Azure services have completely free tiers?\"}]}"

# Response (example):
{
  "response": "Several Azure services offer completely free tiers perfect for POC projects:

  **Database & Storage:**
  - Azure SQL Database: 10 databases, 32GB each, 100K vCore-sec/mo
  - Azure Cosmos DB: 1000 RU/s, 25GB storage
  - Azure Storage: 5GB blob storage, 20K transactions

  **Compute:**
  - Azure Functions: 1M executions/month
  - Azure Static Web Apps: 100GB bandwidth/month
  - Azure Container Apps: 180,000 vCPU-sec, 360,000 GiB-sec/month

  **Messaging & Integration:**
  - Azure Service Bus Basic: Pay per operation only (~$0.05/M ops)
  - Azure Event Grid: 100K operations/month free

  Would you like me to create detailed documentation for any of these services?"
}
```

---

**Ready to explore Azure with minimal cost? Start the agent and ask away!** 🚀

// Copyright (c) Microsoft. All rights reserved.

using System.ComponentModel;
using System.Text;
using System.Text.Json;
using Azure.AI.Projects;
using Azure.Identity;
using Microsoft.Agents.AI;
using Microsoft.Agents.Hosting.AspNetCore;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ModelContextProtocol.Client;
using ModelContextProtocol.Server;

var builder = WebApplication.CreateBuilder(args);

// Load environment variables from .env file
var configuration = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: true)
    .AddEnvironmentVariables()
    .Build();

// Load from .env if it exists (for local development)
var envPath = Path.Combine(Directory.GetCurrentDirectory(), ".env");
if (File.Exists(envPath))
{
    foreach (var line in File.ReadAllLines(envPath))
    {
        if (string.IsNullOrWhiteSpace(line) || line.StartsWith('#')) continue;
        var parts = line.Split('=', 2, StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 2)
        {
            Environment.SetEnvironmentVariable(parts[0].Trim(), parts[1].Trim());
        }
    }
}

// Get configuration values
var foundryEndpoint = Environment.GetEnvironmentVariable("FOUNDRY_PROJECT_ENDPOINT")
    ?? throw new InvalidOperationException("FOUNDRY_PROJECT_ENDPOINT is not set. Please configure in .env file.");
var modelDeployment = Environment.GetEnvironmentVariable("FOUNDRY_MODEL_DEPLOYMENT_NAME")
    ?? "gpt-4o"; // Default model

// Configure workspace paths
var workspaceRoot = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), "..", ".."));
var docsPath = Path.Combine(workspaceRoot, "docs");
var indexPath = Path.Combine(docsPath, "README.md");

Console.WriteLine($"📁 Workspace: {workspaceRoot}");
Console.WriteLine($"📚 Docs folder: {docsPath}");
Console.WriteLine($"🤖 Model: {modelDeployment}");
Console.WriteLine();

// Create AIProjectClient for Foundry
var aiProjectClient = new AIProjectClient(new Uri(foundryEndpoint), new DefaultAzureCredential());

// Create MCP client for Microsoft Learn documentation
Console.WriteLine("🔌 Connecting to Microsoft Learn MCP server...");
var mcpClient = await McpClient.CreateAsync(new HttpClientTransport(new()
{
    Name = "Microsoft Learn MCP",
    Endpoint = new Uri("https://learn.microsoft.com/api/mcp")
}));

// Get MCP tools
var mcpTools = await mcpClient.ListToolsAsync();
Console.WriteLine($"✅ Connected! {mcpTools.Count} MCP tools available");

// Define custom tools for the agent
var customTools = new List<AITool>
{
    AIFunctionFactory.Create(ReadDocumentationFile),
    AIFunctionFactory.Create(ListDocumentationFiles),
    AIFunctionFactory.Create(CreateDocumentationFile),
    AIFunctionFactory.Create(UpdateDocumentationIndex),
    AIFunctionFactory.Create(CalculateMonthlyAzureCost),
    AIFunctionFactory.Create(SearchWebForPricing)
};

// Combine MCP tools with custom tools
var allTools = mcpTools.Cast<AITool>().Concat(customTools).ToList();

// Create the agent
var agent = aiProjectClient.CreateAIAgent(
    name: "BudgetFriendlyAzureAdvisor",
    model: modelDeployment,
    instructions: LoadAgentInstructions(),
    tools: allTools
);

Console.WriteLine($"🤖 Agent '{agent.Name}' created successfully!");
Console.WriteLine();

// Check if running as MCP server (stdio mode) or HTTP server
bool isMcpMode = args.Contains("--mcp") || args.Contains("-m");

if (isMcpMode)
{
    // MCP Server Mode (for GitHub Copilot integration via stdio)
    Console.WriteLine("🔌 Running in MCP Server mode (stdio)");
    Console.WriteLine("   Connect GitHub Copilot to use @azure-advisor commands");
    Console.WriteLine();
    
    var mcpBuilder = Host.CreateEmptyApplicationBuilder(settings: null);
    mcpBuilder.Services
        .AddMcpServer()
        .WithStdioServerTransport()
        .WithTools([McpServerTool.Create(agent.AsAIFunction())]);
    
    await mcpBuilder.Build().RunAsync();
}
else
{
    // HTTP Server Mode (default)
    Console.WriteLine("🌐 Running in HTTP Server mode");
    Console.WriteLine($"   Agent available at: http://localhost:8087");
    Console.WriteLine("   Use --mcp flag for GitHub Copilot integration");
    Console.WriteLine();
    
    // Configure ASP.NET Core
    builder.Services.AddControllers();
    var app = builder.Build();

app.MapPost("/", async (HttpContext context) =>
{
    var requestBody = await new StreamReader(context.Request.Body).ReadToEndAsync();
    var message = JsonSerializer.Deserialize<ChatRequest>(requestBody);
    
    if (message?.Messages == null || message.Messages.Length == 0)
    {
        context.Response.StatusCode = 400;
        await context.Response.WriteAsync("Invalid request");
        return;
    }
    
    var userMessage = message.Messages.Last().Content;
    var response = await agent.RunAsync(userMessage);
    
    await context.Response.WriteAsJsonAsync(new { response = response.ToString() });
});

    Console.WriteLine("🚀 BudgetFriendlyAzureAdvisor HTTP server starting...");
    Console.WriteLine("📡 Server URL: http://localhost:8087");
    Console.WriteLine("🧪 Test by sending POST requests with JSON: {\"messages\": [{\"role\": \"user\", \"content\": \"your question\"}]}");
    Console.WriteLine("⏸️  Press Ctrl+C to stop");
    Console.WriteLine();

    await app.RunAsync("http://localhost:8087");
}

// Note: Cleanup happens on process termination
// await mcpClient.DisposeAsync();

// ===== Tool Functions =====

[Description("Read the contents of an existing Azure documentation file")]
static string ReadDocumentationFile(
    [Description("The filename (e.g., 'azure-sql-free-tier.md')")] string filename)
{
    try
    {
        var workspaceRoot = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), "..", ".."));
        var docsPath = Path.Combine(workspaceRoot, "docs");
        var filePath = Path.Combine(docsPath, filename);

        if (!File.Exists(filePath))
        {
            return $"❌ File not found: {filename}";
        }

        var content = File.ReadAllText(filePath);
        return $"📄 Content of {filename}:\n\n{content}";
    }
    catch (Exception ex)
    {
        return $"❌ Error reading file: {ex.Message}";
    }
}

[Description("List all documentation files in the docs folder")]
static string ListDocumentationFiles()
{
    try
    {
        var workspaceRoot = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), "..", ".."));
        var docsPath = Path.Combine(workspaceRoot, "docs");

        if (!Directory.Exists(docsPath))
        {
            return "❌ Docs folder not found";
        }

        var files = Directory.GetFiles(docsPath, "*.md", SearchOption.AllDirectories)
            .Select(f => Path.GetRelativePath(docsPath, f))
            .OrderBy(f => f)
            .ToList();

        if (files.Count == 0)
        {
            return "📭 No documentation files found";
        }

        var result = new StringBuilder("📚 Available documentation files:\n\n");
        foreach (var file in files)
        {
            result.AppendLine($"- {file}");
        }

        return result.ToString();
    }
    catch (Exception ex)
    {
        return $"❌ Error listing files: {ex.Message}";
    }
}

[Description("Create a new Azure service documentation file with the specified content")]
static string CreateDocumentationFile(
    [Description("The filename (e.g., 'azure-functions-free-tier.md')")] string filename,
    [Description("The complete markdown content for the file")] string content)
{
    try
    {
        var workspaceRoot = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), "..", ".."));
        var docsPath = Path.Combine(workspaceRoot, "docs");

        if (!Directory.Exists(docsPath))
        {
            Directory.CreateDirectory(docsPath);
        }

        var filePath = Path.Combine(docsPath, filename);

        if (File.Exists(filePath))
        {
            return $"⚠️ File already exists: {filename}. Use a different name or update the existing file manually.";
        }

        File.WriteAllText(filePath, content);
        return $"✅ Successfully created: {filename} at {filePath}";
    }
    catch (Exception ex)
    {
        return $"❌ Error creating file: {ex.Message}";
    }
}

[Description("Update the main documentation index (README.md) to add a new service entry")]
static string UpdateDocumentationIndex(
    [Description("The service name (e.g., 'Azure Functions')")] string serviceName,
    [Description("The filename to link to (e.g., 'azure-functions-free-tier.md')")] string filename,
    [Description("The category (e.g., 'Compute Services', 'Database Services')")] string category,
    [Description("Brief description of the service")] string description)
{
    try
    {
        var workspaceRoot = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), "..", ".."));
        var docsPath = Path.Combine(workspaceRoot, "docs");
        var indexPath = Path.Combine(docsPath, "README.md");

        if (!File.Exists(indexPath))
        {
            return "❌ Documentation index (README.md) not found";
        }

        var content = File.ReadAllText(indexPath);

        // Add to the appropriate section based on category
        var linkEntry = $"- [**{serviceName}**]({filename}) - {description}";

        // Simple append to relevant section (could be enhanced with more intelligent parsing)
        var updatedContent = content.Replace(
            $"### {category}",
            $"### {category}\n{linkEntry}"
        );

        if (content == updatedContent)
        {
            return $"⚠️ Could not find category '{category}' in index. Entry not added.";
        }

        File.WriteAllText(indexPath, updatedContent);
        return $"✅ Successfully added {serviceName} to documentation index under '{category}'";
    }
    catch (Exception ex)
    {
        return $"❌ Error updating index: {ex.Message}";
    }
}

[Description("Calculate estimated monthly cost for Azure services based on usage parameters")]
static string CalculateMonthlyAzureCost(
    [Description("JSON object with service usage. Example: {\"sql_databases\": 2, \"function_executions\": 500000, \"storage_gb\": 10}")] string usageJson)
{
    try
    {
        var usage = JsonSerializer.Deserialize<Dictionary<string, object>>(usageJson);
        if (usage == null)
        {
            return "❌ Invalid usage JSON format";
        }

        var result = new StringBuilder("💰 **Estimated Monthly Azure Cost**\n\n");
        decimal totalCost = 0;

        // SQL Database calculations (free tier)
        if (usage.TryGetValue("sql_databases", out var sqlDbValue))
        {
            var sqlDbs = Convert.ToInt32(sqlDbValue.ToString());
            var sqlCost = 0m; // Free for up to 10 databases within limits
            result.AppendLine($"**Azure SQL Database:** {sqlDbs} databases");
            result.AppendLine($"  - Within free tier (up to 10 databases): $0.00");
            result.AppendLine($"  - Each database: 100K vCore-sec/month, 32GB storage");
            totalCost += sqlCost;
            result.AppendLine();
        }

        // Azure Functions calculations (consumption plan)
        if (usage.TryGetValue("function_executions", out var funcExecValue))
        {
            var executions = Convert.ToInt64(funcExecValue.ToString());
            var freeExecutions = 1_000_000L;
            var paidExecutions = Math.Max(0, executions - freeExecutions);
            var funcCost = paidExecutions * 0.20m / 1_000_000m; // $0.20 per million executions
            result.AppendLine($"**Azure Functions:** {executions:N0} executions");
            result.AppendLine($"  - Free tier: {freeExecutions:N0} executions = $0.00");
            if (paidExecutions > 0)
            {
                result.AppendLine($"  - Paid: {paidExecutions:N0} executions = ${funcCost:F2}");
            }
            totalCost += funcCost;
            result.AppendLine();
        }

        // Azure Storage calculations (blob storage)
        if (usage.TryGetValue("storage_gb", out var storageValue))
        {
            var storageGb = Convert.ToDecimal(storageValue.ToString());
            var freeStorage = 5m;
            var paidStorage = Math.Max(0, storageGb - freeStorage);
            var storageCost = paidStorage * 0.02m; // ~$0.02 per GB/month (hot tier)
            result.AppendLine($"**Azure Storage:** {storageGb}GB");
            result.AppendLine($"  - Free tier: {freeStorage}GB = $0.00");
            if (paidStorage > 0)
            {
                result.AppendLine($"  - Paid: {paidStorage}GB = ${storageCost:F2}");
            }
            totalCost += storageCost;
            result.AppendLine();
        }

        // Static Web Apps (always free tier)
        if (usage.TryGetValue("static_web_apps", out var swaValue))
        {
            var swaCount = Convert.ToInt32(swaValue.ToString());
            result.AppendLine($"**Azure Static Web Apps:** {swaCount} apps");
            result.AppendLine($"  - Free tier: $0.00");
            result.AppendLine($"  - Includes 100GB bandwidth/month per app");
            result.AppendLine();
        }

        result.AppendLine("---");
        result.AppendLine($"**💵 Total Estimated Cost: ${totalCost:F2}/month**");
        result.AppendLine();
        result.AppendLine("_Note: Estimates based on free tier allocations as of January 2026. Actual costs may vary._");

        return result.ToString();
    }
    catch (Exception ex)
    {
        return $"❌ Error calculating cost: {ex.Message}";
    }
}

[Description("Search the web for latest Azure pricing information (use when pricing docs may be outdated)")]
static string SearchWebForPricing(
    [Description("The Azure service to search pricing for (e.g., 'Azure SQL Database pricing 2026')")] string searchQuery)
{
    // Note: In production, you'd integrate with Bing Search API or similar
    // For now, return guidance on where to check
    return $"""
    🔍 **Web Search Required: {searchQuery}**
    
    For the most up-to-date pricing, check these resources:
    
    1. **Azure Pricing Calculator**: https://azure.microsoft.com/pricing/calculator/
    2. **Official Pricing Pages**: https://azure.microsoft.com/pricing/
    3. **Service-specific pricing**: Search for '{searchQuery}'
    
    💡 **Tip**: Pricing in official Microsoft docs can lag by a few months. Always cross-reference with:
    - Azure portal's cost estimator
    - Azure Pricing Calculator
    - Recent blog posts or announcements
    
    ⚠️ **Note**: This is a placeholder. To enable real-time web search, integrate Bing Search API or similar service.
    """;
}

// Load agent instructions from the copilot-instructions.md file
static string LoadAgentInstructions()
{
    try
    {
        var workspaceRoot = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), "..", ".."));
        var instructionsPath = Path.Combine(workspaceRoot, ".github", "copilot-instructions.md");

        if (File.Exists(instructionsPath))
        {
            var content = File.ReadAllText(instructionsPath);
            return $"""
            You are the BudgetFriendlyAzureAdvisor - an expert Azure cost optimization agent.
            
            Your mission is to help with POC Azure projects while keeping costs at $0-5/month.
            
            {content}
            
            ## Your Capabilities
            
            You have access to these tools:
            - **ReadDocumentationFile**: Read existing Azure docs from the workspace
            - **ListDocumentationFiles**: See what docs already exist
            - **CreateDocumentationFile**: Create new comprehensive Azure service guides
            - **UpdateDocumentationIndex**: Add new docs to the main README index
            - **CalculateMonthlyAzureCost**: Estimate costs for service combinations
            - **SearchWebForPricing**: Guide users to latest pricing info
            - **microsoft_docs_search**: Search official Microsoft/Azure documentation
            - **microsoft_docs_fetch**: Fetch complete Microsoft doc pages
            - **microsoft_code_sample_search**: Find official Azure code examples
            
            ## Your Workflow
            
            When asked about an Azure service:
            1. Check existing docs first (ListDocumentationFiles, ReadDocumentationFile)
            2. If doc doesn't exist, research using microsoft_docs_search
            3. Fetch detailed info with microsoft_docs_fetch
            4. Create comprehensive doc with CreateDocumentationFile
            5. Update index with UpdateDocumentationIndex
            6. Provide cost estimates with CalculateMonthlyAzureCost
            
            Always prioritize FREE TIER options and calculate costs transparently.
            """;
        }
        else
        {
            return "You are the BudgetFriendlyAzureAdvisor. Help users explore Azure services with minimal cost, focusing on free tiers and POC-appropriate solutions.";
        }
    }
    catch
    {
        return "You are the BudgetFriendlyAzureAdvisor. Help users explore Azure services with minimal cost, focusing on free tiers and POC-appropriate solutions.";
    }
}

// Request/Response models
public class ChatRequest
{
    public ChatMessageDto[]? Messages { get; set; }
}

public class ChatMessageDto
{
    public string Role { get; set; } = "";
    public string Content { get; set; } = "";
}

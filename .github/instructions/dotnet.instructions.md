---
applyTo: "**/*.csproj,**/tasks.json,**/*.cs"
---

# .NET Corporate Environment Workarounds

**CRITICAL**: In this corporate environment, standard .NET execution is blocked by security policies.

## Required Execution Pattern

❌ **NEVER use these (blocked by security):**
- `dotnet run`
- Direct `.exe` execution
- `dotnet watch run`

✅ **ALWAYS use this pattern:**
```bash
# 1. Build first
dotnet build -c Release

# 2. Run via DLL
dotnet bin/Release/net10.0/<app-name>.dll [arguments]
```

## VS Code Tasks Configuration

When creating or updating tasks.json, always use DLL paths:

**✅ CORRECT:**
```json
{
    "label": "run-agent",
    "command": "dotnet",
    "type": "process",
    "args": [
        "${workspaceFolder}/bin/Release/net10.0/BudgetFriendlyAzureAdvisor.dll",
        "--mcp"
    ]
}
```

**❌ WRONG:**
```json
{
    "label": "run-agent",
    "command": "dotnet",
    "type": "process",
    "args": ["run", "--project", "${workspaceFolder}/App.csproj"]
}
```

## Application-Specific Paths

### BudgetFriendlyAzureAdvisor
```bash
# Build
cd src/BudgetFriendlyAzureAdvisor
dotnet build -c Release

# Run HTTP mode
dotnet bin/Release/net10.0/BudgetFriendlyAzureAdvisor.dll

# Run MCP mode
dotnet bin/Release/net10.0/BudgetFriendlyAzureAdvisor.dll --mcp
```

### MCP Server Configuration
When configuring MCP servers in GitHub Copilot, use absolute DLL paths:

```json
{
  "mcpServers": {
    "azure-advisor": {
      "command": "dotnet",
      "args": [
        "c:\\dev\\side-projects\\azure-planner\\src\\BudgetFriendlyAzureAdvisor\\bin\\Release\\net10.0\\BudgetFriendlyAzureAdvisor.dll",
        "--mcp"
      ]
    }
  }
}
```

## Publishing for Production

For cleaner deployments:
```bash
dotnet publish -c Release -o publish
dotnet publish/<app-name>.dll
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| File not found error | Run `dotnet build -c Release` first |
| Old code still running | Rebuild: `dotnet build -c Release` |
| VS Code task fails | Verify DLL path matches actual build output |
| Security/access denied | You're using `dotnet run` - switch to DLL pattern |

## Key Rules

1. Always build before running
2. Always use `dotnet <dll-path>` instead of `dotnet run`
3. Always rebuild after code changes
4. Always use Release configuration for consistent paths
5. Never mention or suggest `dotnet run` to users in this environment

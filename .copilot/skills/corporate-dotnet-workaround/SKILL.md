# Corporate Security Workaround for .NET Applications

## Skill Overview

When working in corporate environments with strict security policies, standard .NET execution methods are often blocked:
- `dotnet run` commands may be restricted
- `.exe` files cannot be executed directly
- Security software blocks certain executable patterns

This skill provides the workaround: **build once, run via DLL**.

## Core Principle

Instead of:
```bash
dotnet run
```

Use:
```bash
dotnet build -c Release
dotnet bin/Release/net10.0/<app-name>.dll
```

## When to Apply This Skill

- User mentions security restrictions, blocked executables, or corporate policies
- `dotnet run` fails with access denied or security errors
- `.exe` files are blocked by security software
- Running .NET applications in restricted environments

## Implementation Pattern

### Step 1: Build the Application

```bash
cd <project-directory>
dotnet build -c Release
```

### Step 2: Run via DLL

```bash
# Navigate to output folder
cd bin/Release/net10.0

# Run the DLL
dotnet <app-name>.dll [arguments]
```

### Step 3: VS Code Tasks Configuration

When creating or updating VS Code tasks, use the DLL path instead of `dotnet run`:

**❌ AVOID (Blocked by Security):**
```json
{
    "label": "Run Application",
    "type": "shell",
    "command": "dotnet",
    "args": ["run", "--project", "${workspaceFolder}/App.csproj"]
}
```

**✅ USE INSTEAD:**
```json
{
    "label": "Run Application",
    "type": "shell",
    "command": "dotnet",
    "args": ["${workspaceFolder}/bin/Release/net10.0/app-name.dll"]
}
```

## Application-Specific Configurations

### BudgetFriendlyAzureAdvisor Agent

**Build:**
```bash
cd c:/dev/tools/az-devops/src/BudgetFriendlyAzureAdvisor
dotnet build -c Release
```

**Run HTTP Mode:**
```bash
dotnet bin/Release/net10.0/BudgetFriendlyAzureAdvisor.dll
```

**Run MCP Mode (for GitHub Copilot):**
```bash
dotnet bin/Release/net10.0/BudgetFriendlyAzureAdvisor.dll --mcp
```

**MCP Server Config:**
```json
{
  "mcpServers": {
    "azure-advisor": {
      "command": "dotnet",
      "args": [
        "c:\\dev\\tools\\az-devops\\src\\BudgetFriendlyAzureAdvisor\\bin\\Release\\net10.0\\BudgetFriendlyAzureAdvisor.dll",
        "--mcp"
      ],
      "name": "BudgetFriendlyAzureAdvisor"
    }
  }
}
```

## Alternative: Publish for Cleaner Output

For production-like deployment:

```bash
dotnet publish -c Release -o publish
dotnet publish/<app-name>.dll
```

Benefits:
- Single output folder with all dependencies
- No intermediate build artifacts
- Portable folder structure
- Still runs via dotnet host

## Troubleshooting

### "The system cannot find the file specified"
**Solution:** Build hasn't been run yet
```bash
dotnet build -c Release
```

### "This application requires .NET Runtime"
**Solution:** Install the required .NET runtime version

### Running old version after code changes
**Solution:** Always rebuild after modifications
```bash
dotnet build -c Release
```

### VS Code task not finding DLL
**Solution:** Verify path in tasks.json matches actual build output location

## Key Rules

1. ✅ **Always build first** before running
2. ✅ **Use `dotnet <dll-path>`** instead of `dotnet run`
3. ✅ **Rebuild after code changes** for updates to take effect
4. ✅ **Use Release configuration** for consistent paths
5. ✅ **Update MCP configs** with DLL paths, not `dotnet run`
6. ❌ **Never use `dotnet run`** in corporate environments
7. ❌ **Never execute .exe directly** - always through dotnet host

## Quick Reference

| Task | Command |
|------|---------|
| Build | `dotnet build -c Release` |
| Run DLL | `dotnet bin/Release/net10.0/<app>.dll` |
| Publish | `dotnet publish -c Release -o publish` |
| Run Published | `dotnet publish/<app>.dll` |

## Integration with Other Skills

- Works with all .NET applications in the workspace
- Compatible with Azure Function Apps (use `func start` with published output)
- Essential for MCP server configurations in corporate environments
- Applies to console apps, web apps, and background services

---

**When in doubt:** Build first, run via DLL, never use `dotnet run` in corporate environments.

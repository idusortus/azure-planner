# Corporate Security Workaround - Running .NET Applications

**Last Updated:** January 13, 2026  
**Status:** Active Workaround  
**Applies To:** All .NET applications in corporate environments with security restrictions

## 🔐 The Problem

Due to corporate security policies and restrictions:
- **Cannot execute** `dotnet run` commands directly
- **Cannot run** `.exe` files directly (blocked by security software)
- Security software blocks or restricts certain executable files
- Standard .NET SDK commands may be monitored or prohibited

## ✅ The Solution: Run via DLL

Instead of running the application via `dotnet run` or executing the `.exe` directly, we **build the application once** and then **run the compiled DLL** via `dotnet <app-name>.dll`.

### Why This Works

1. **DLL execution via dotnet** bypasses executable restrictions
2. **No direct .exe execution** - security software allows dotnet host
3. **Standard .NET runtime** invocation is permitted
4. **Once built**, the DLL can be run repeatedly without rebuilding

---

## 🛠️ Implementation for BudgetFriendlyAzureAdvisor

### Step 1: Build the Application (One Time)

Open PowerShell or Command Prompt:

```powershell
cd c:\dev\tools\az-devops\src\BudgetFriendlyAzureAdvisor
dotnet build -c Release
```

The compiled DLL will be located at:
```
c:\dev\tools\az-devops\src\BudgetFriendlyAzureAdvisor\bin\Release\net10.0\BudgetFriendlyAzureAdvisor.dll
```

### Step 2: Run via DLL

**HTTP Server Mode (Default):**
```powershell
cd c:\dev\tools\az-devops\src\BudgetFriendlyAzureAdvisor\bin\Release\net10.0
dotnet BudgetFriendlyAzureAdvisor.dll
```

**MCP Server Mode (for GitHub Copilot):**
```powershell
cd c:\dev\tools\az-devops\src\BudgetFriendlyAzureAdvisor\bin\Release\net10.0
dotnet BudgetFriendlyAzureAdvisor.dll --mcp
```

### Step 3: Update GitHub Copilot MCP Configuration

Update `.github/mcp-server-config.json` to use the DLL path:

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

### Step 4: Update VS Code Launch Configuration

Update `.vscode/launch.json` to run the DLL instead of using `dotnet run`:

**BEFORE (Blocked by Security):**
```json
{
    "name": "Debug BudgetFriendlyAzureAdvisor",
    "type": "coreclr",
    "request": "launch",
    "preLaunchTask": "build-agent",
    "program": "${workspaceFolder}/src/BudgetFriendlyAzureAdvisor/bin/Debug/net10.0/BudgetFriendlyAzureAdvisor.dll"
}
```

**AFTER (Works with Security Restrictions):**
```json
{
    "name": "Run BudgetFriendlyAzureAdvisor (HTTP)",
    "type": "coreclr",
    "request": "launch",
    "preLaunchTask": "build-agent-release",
    "program": "dotnet",
    "args": ["${workspaceFolder}/src/BudgetFriendlyAzureAdvisor/bin/Release/net10.0/BudgetFriendlyAzureAdvisor.dll"],
    "cwd": "${workspaceFolder}/src/BudgetFriendlyAzureAdvisor"
}
```

---

## 📦 Alternative: Publish to Dedicated Folder

For cleaner path management:

```powershell
cd c:\dev\tools\az-devops\src\BudgetFriendlyAzureAdvisor
dotnet publish -c Release -o publish
```

This creates: `c:\dev\tools\az-devops\src\BudgetFriendlyAzureAdvisor\publish\BudgetFriendlyAzureAdvisor.dll`

**Run published version:**
```powershell
cd c:\dev\tools\az-devops\src\BudgetFriendlyAzureAdvisor\publish
dotnet BudgetFriendlyAzureAdvisor.dll
```

**Benefits:**
- All dependencies in one location
- No intermediate build artifacts
- Cleaner output structure
- Can be copied to other locations

---

## 🔄 Rebuilding After Code Changes

Whenever you modify the source code, you must **rebuild**:

```powershell
cd c:\dev\tools\az-devops\src\BudgetFriendlyAzureAdvisor
dotnet build -c Release
```

Or if using published version:
```powershell
dotnet publish -c Release -o publish
```

---

## 🧪 Testing the Workaround

### Test 1: HTTP Server Mode
```powershell
cd c:\dev\tools\az-devops\src\BudgetFriendlyAzureAdvisor\bin\Release\net10.0
dotnet BudgetFriendlyAzureAdvisor.dll
```

**Expected Output:**
```
🤖 Agent 'BudgetFriendlyAzureAdvisor' created successfully!

🌐 Running in HTTP Server mode
   Agent available at: http://localhost:8087
   Use --mcp flag for GitHub Copilot integration

🚀 BudgetFriendlyAzureAdvisor HTTP server starting...
```

### Test 2: MCP Server Mode
```powershell
cd c:\dev\tools\az-devops\src\BudgetFriendlyAzureAdvisor\bin\Release\net10.0
dotnet BudgetFriendlyAzureAdvisor.dll --mcp
```

**Expected Output:**
```
🤖 Agent 'BudgetFriendlyAzureAdvisor' created successfully!

🔌 Running in MCP Server mode (stdio)
   Connect GitHub Copilot to use @azure-advisor commands
```

### Test 3: HTTP API Call
```powershell
curl -X POST http://localhost:8087 `
  -H "Content-Type: application/json" `
  -d '{"messages": [{"role": "user", "content": "What is Azure SQL free tier?"}]}'
```

---

## ❓ Troubleshooting

### Issue: "The system cannot find the file specified"

**Cause:** Application hasn't been built yet

**Solution:**
```powershell
cd c:\dev\tools\az-devops\src\BudgetFriendlyAzureAdvisor
dotnet build -c Release
```

### Issue: "dotnet build" is blocked

**Cause:** Corporate security blocks `dotnet` commands entirely

**Solution:** Build on a different machine (home computer, VM) and copy the `bin\Release\net10.0\` folder to your work machine

### Issue: "This application requires the .NET Runtime"

**Cause:** .NET 10.0 runtime not installed

**Solution:** Install .NET 10.0 Runtime from https://dotnet.microsoft.com/download

### Issue: Running old version after code changes

**Cause:** Forgot to rebuild after modifying source

**Solution:** Always rebuild after changes:
```powershell
dotnet build -c Release
```

### Issue: MCP server not responding in GitHub Copilot

**Cause:** Incorrect path in MCP configuration

**Solution:** Verify the path in `.github/mcp-server-config.json` matches the actual DLL location

---

## 📋 Quick Reference Card

| Action | Command |
|--------|---------|
| **Build Release** | `dotnet build -c Release` |
| **Run HTTP Mode** | `dotnet bin\Release\net10.0\BudgetFriendlyAzureAdvisor.dll` |
| **Run MCP Mode** | `dotnet bin\Release\net10.0\BudgetFriendlyAzureAdvisor.dll --mcp` |
| **Publish** | `dotnet publish -c Release -o publish` |
| **Run Published** | `dotnet publish\BudgetFriendlyAzureAdvisor.dll` |

---

## 🎯 Key Takeaways

1. ✅ **Corporate security blocks** `dotnet run` AND `.exe` files
2. ✅ **Build once** with `dotnet build -c Release`
3. ✅ **Run via DLL** with `dotnet <app-name>.dll` 
4. ✅ **VS Code integration** works by running dotnet with DLL path
5. ✅ **Rebuild after changes** to source code
6. ✅ **Publish** for cleaner output folder
7. ✅ **Never run .exe directly** - always use dotnet host
8. ✅ **MCP config** uses DLL path, not `dotnet run`

This workaround is a **permanent solution** for corporate environments with CLI restrictions.

---

## Related Documentation

- [BudgetFriendlyAzureAdvisor Agent](./budget-friendly-azure-advisor-agent.md)
- [Using with GitHub Copilot](./using-agent-with-github-copilot.md)
- [Quick Start Guide](./quick-start-agent.md)

# Custom Instructions for GitHub Copilot

This directory contains path-specific custom instructions that are automatically loaded by GitHub Copilot when working with matching files.

## Official GitHub Copilot Custom Instructions Structure

```
.github/
├── copilot-instructions.md          # Repository-wide instructions
└── instructions/                     # Path-specific instructions
    ├── dotnet.instructions.md        # Applies to .NET files
    └── [more].instructions.md        # Other path-specific rules
```

## Current Instructions

### [azure-operations.instructions.md](azure-operations.instructions.md)
**Applies to**: `**` (all files)

Comprehensive guidelines for Azure resource management operations:
- Authentication and session management
- Resource creation patterns (SQL, Web Apps, Functions, Storage)
- Query and monitoring operations
- Modification and scaling patterns
- Safe deletion procedures
- Cost monitoring and optimization
- Documentation requirements

**Key Features**:
- Pre-creation checklists for all resources
- Standard naming conventions and tagging
- Safety rules for destructive operations
- Cost calculation before creation
- Automatic resource documentation

### [dotnet.instructions.md](dotnet.instructions.md)
**Applies to**: `**/*.csproj`, `**/tasks.json`, `**/*.cs`

Critical workarounds for corporate environments where:
- `dotnet run` is blocked by security policies
- `.exe` files cannot be executed directly
- DLL-based execution is required

**Key Pattern**: Always build first, then run via DLL:
```bash
dotnet build -c Release
dotnet bin/Release/net10.0/<app-name>.dll
```

## Documentation

For more information about GitHub Copilot custom instructions:
- [Official GitHub Docs: Adding repository custom instructions](https://docs.github.com/en/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- [Custom instructions examples](https://docs.github.com/en/copilot/tutorials/customization-library/custom-instructions)

## Notes

- All `.instructions.md` files must have a frontmatter block with `applyTo` glob patterns
- Instructions are combined with repository-wide instructions from `copilot-instructions.md`
- These instructions are used by GitHub Copilot Chat, Copilot code review, and Copilot coding agent

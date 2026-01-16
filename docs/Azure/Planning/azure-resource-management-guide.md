# Azure Resource Management - Quick Start Guide

**Status**: ✅ **ENABLED** - This session can create and manage Azure resources

## Authentication Status

✅ **Authenticated**  
- **Subscription**: Azure subscription 1
- **User**: samuel.johnson.wi@gmail.com  
- **Resource Group**: Shared (centralus)

Test authentication anytime:
```bash
az account show
```

## What This Session Can Do

### 1. Query Resources
Ask me about any Azure resource:
- "What SQL databases do I have?"
- "Show me all resources in the Shared resource group"
- "What's my current Azure spending?"

### 2. Create Resources
I can create Azure resources directly:
- Azure SQL Database (serverless, free tier)
- Azure Static Web Apps (free tier)
- Azure Functions (consumption plan)
- Storage Accounts (LRS, standard)
- App Services (free tier)
- Any Azure resource via `az` CLI

**I'll always**:
- Calculate costs before creating
- Recommend free/low-cost options
- Ask for confirmation
- Document everything created

### 3. Modify Resources
I can update existing resources:
- Scale up/down
- Change configurations
- Add connection strings
- Update app settings
- Modify firewall rules

### 4. Deploy Infrastructure
I can deploy using:
- Azure CLI commands
- Bicep templates
- ARM templates
- Multi-resource deployments

### 5. Monitor & Optimize
I can help you:
- Check resource costs
- Monitor performance
- Optimize spending
- Set up auto-pause
- Clean up unused resources

## Example Requests

### Discovery
```
"What Azure resources do I currently have?"
"Show me my SQL databases"
"What's in the Shared resource group?"
"How much am I spending this month?"
```

### Creation
```
"Create a free-tier Azure SQL database for my POC"
"Set up a Static Web App for my React project"
"Deploy an Azure Function app with consumption plan"
"Create a serverless SQL database that auto-pauses"
```

### Configuration
```
"Add a firewall rule to allow my IP"
"Set up a connection string for my web app"
"Configure auto-pause on my SQL database"
"Scale my database to 2 vCores"
```

### Deployment
```
"Deploy a complete Aspire microservices architecture"
"Set up infrastructure for a betting app POC"
"Create a database + web app + function app stack"
"Deploy with Bicep template"
```

## Safety Features

✅ **Cost-First Approach**
- I always calculate and show costs before creating resources
- I recommend free tiers whenever possible
- Target: $0-5/month for POC projects

✅ **Confirmation Required**
- I'll ask before creating resources
- I'll ask before deleting resources
- I'll preview changes when possible

✅ **Automatic Documentation**
- All created resources are documented in `/docs/deployed-resources.md`
- Cleanup commands provided for every resource
- Cost tracking maintained

✅ **Prefer Existing**
- I'll check if resources exist before creating
- I'll use existing resource groups
- I'll suggest reusing shared infrastructure

## Getting Started

### Check Current State
Ask me: "What Azure resources do I have?"

### Create Your First Resource
Ask me: "Create a free-tier SQL database for testing"

### Plan Architecture
Ask me: "Help me plan infrastructure for a [your project description]"

## Resource Management Guidelines

When I create resources, I will:

1. **Check** if authentication is valid
2. **Calculate** estimated monthly cost
3. **Recommend** the cheapest tier that meets requirements
4. **Show** you the resource details
5. **Ask** for your confirmation
6. **Create** the resource
7. **Document** it in deployed-resources.md
8. **Provide** connection strings and access info
9. **Give** cleanup commands

## Cost Optimization Rules

- ✅ Always suggest free tiers first
- ✅ Use serverless for SQL (auto-pause after 60 min)
- ✅ Use consumption plans for Functions
- ✅ Use local-redundant storage (LRS)
- ✅ Share resources across projects when possible
- ✅ Monitor spending weekly

## Important Notes

### What I WON'T Do Without Confirmation
- Delete resource groups
- Delete databases
- Scale up to expensive tiers
- Create multiple instances of expensive services
- Deploy to production environments

### What I WILL Do Automatically
- Verify authentication
- Calculate costs
- Check for existing resources
- Apply standard tags
- Document created resources
- Provide cleanup commands

## Troubleshooting

**Authentication Expired?**
Run: `az login`

**Want to see what I can do?**
Ask: "What Azure operations can you perform?"

**Need to verify authentication?**
Ask: "Check my Azure authentication status"

**Want to see current costs?**
Ask: "Show me my Azure spending"

---

## Ready to Start?

I'm ready to help you create and manage Azure resources! 

Just ask me about Azure services, request resource creation, or ask me to plan infrastructure for your project. I'll guide you through every step with cost optimization in mind.

**Example**: "I need a database for a betting app POC - what do you recommend?"

# Azure Documentation Index

## Planning

- [PoC Platform Roadmap](Planning/poc-platform-roadmap.md) - Implementation plan for shared infrastructure + per-PoC pattern
- [API Approach Analysis](Planning/poc-api-approach-analysis.md) - Decision rationale for Container Apps over shared API
- [AI Feedback](Planning/AiFeedback-AzurePoCArchitecture.md) - Multi-model architecture consultation
- [Azure Resource Management Guide](Planning/azure-resource-management-guide.md) - Session capabilities for Azure operations
- [Azure SQL Free Tier](Planning/azure-sql-free-tier.md) - Serverless SQL configuration details

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| API Hosting | Container Apps (consumption) | Scales to zero, Aspire compatible, separate repos |
| Database | Azure SQL Serverless | Auto-pause, per-PoC isolation on shared server |
| Frontend | Static Web Apps (free) | Zero cost, built-in CI/CD |
| Messaging | Service Bus (shared namespace) | Cost-effective, queue-per-PoC isolation |
| Orchestration | Aspire per PoC | Modern .NET pattern, local dev + cloud deploy |

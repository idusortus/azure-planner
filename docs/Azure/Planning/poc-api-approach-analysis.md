# PoC API Hosting - Approach Analysis

**Date**: January 16, 2026  
**Decision**: Container Apps (individual API per PoC)

## Approaches Considered

### A. Shared Multi-Tenant API
Single .NET WebAPI serving all PoCs with tenant resolution middleware.

| Factor | Assessment |
|--------|------------|
| Cost | ~$13-50/month (App Service B1) |
| Repo structure | Requires monorepo |
| Aspire compatible | No |
| Maintenance | High (coupled deployments, tenant middleware) |
| Graduation path | Difficult (extraction required) |

**Rejected**: Conflicts with separate-repo and Aspire requirements.

### B. Container Apps (Individual APIs)
Each PoC gets its own Container App on consumption plan.

| Factor | Assessment |
|--------|------------|
| Cost | ~$0.50-5/month per app (scales to zero) |
| Repo structure | Separate repo per PoC |
| Aspire compatible | Yes (native deployment target) |
| Maintenance | Low (independent lifecycles) |
| Graduation path | Easy (increase resources) |

**Selected**: Satisfies all constraints.

### C. App Service Free Tier
Separate App Service per PoC on F1 tier.

| Factor | Assessment |
|--------|------------|
| Cost | $0 |
| Limitations | 60 CPU min/day, no custom domains, 1GB RAM |

**Rejected**: Too limited for realistic PoCs.

## Decision Rationale

User constraints that drove the decision:
1. Separate GitHub repo per PoC - eliminates shared API
2. Aspire per PoC - eliminates shared API
3. Low maintenance friction - favors isolation
4. No Azure Functions - rules out serverless functions
5. .NET WebAPI skill building - both A and B work

## Cost Comparison (5 PoCs)

| Approach | Monthly Estimate |
|----------|------------------|
| Shared Multi-Tenant | $30-50 |
| Container Apps | $30-60 |
| App Service Free | $0 (unusable) |

Costs are comparable; isolation benefits outweigh minor cost difference.

# Documentation Index

## Deployment

| Document | Purpose |
|----------|---------|
| [**MASTER.md**](MASTER.md) | **Single source of truth** — full deployment process, infrastructure, troubleshooting |
| [**deployed-resources.md**](deployed-resources.md) | Live Azure resource inventory with cleanup commands |
| [**DECISIONS.md**](poc-deployment/DECISIONS.md) | Architecture Decision Records (15 ADRs) |

## Azure Research

| Document | Purpose |
|----------|---------|
| [azure-sql-free-tier.md](azure-sql-free-tier.md) | Free SQL tier research and limits |
| [Azure/Planning/](Azure/Planning/) | Historical architecture research docs |

## MCP Agent (BudgetFriendlyAzureAdvisor)

| Document | Purpose |
|----------|---------|
| [budget-friendly-azure-advisor-agent.md](budget-friendly-azure-advisor-agent.md) | Agent overview |
| [quick-start-agent.md](quick-start-agent.md) | 5-minute setup guide |
| [using-agent-with-github-copilot.md](using-agent-with-github-copilot.md) | Copilot MCP integration |
| [corporate-security-workaround.md](corporate-security-workaround.md) | Running .NET in restricted environments |

## Live POCs

| POC | API | Frontend | Schema |
|-----|-----|----------|--------|
| TodoApp | [API](https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/todos) | [Web](https://happy-desert-065eace10.6.azurestaticapps.net) | `todo` |
| LeaveACommentApp | [API](https://leave-a-comment-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/comments) | [Web](https://nice-sand-0b0628510.6.azurestaticapps.net) | `comments` |
| FriendsPrediction | [API](https://friends-prediction-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/events) | [Web](https://kind-pebble-0eeaa2310.2.azurestaticapps.net) | `predictions` |

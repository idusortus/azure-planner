# Basic Deployable Framework - Complete Guide

> **Pragmatic, repeatable process for deploying POC applications to Azure**

This guide demonstrates a simple, cost-effective approach to taking an app idea from concept to deployed Azure application. Three frontend options are provided: Vanilla JS, React, and React Native.

## Project Overview

**What's Included:**
- ✅ .NET 10 Minimal Web API (backend)
- ✅ Three frontend options (Vanilla JS, React, React Native)
- ✅ Azure SQL Serverless (database)
- ✅ .NET Aspire framework (local orchestration)
- ✅ Deployment scripts and guides
- ✅ Complete working example (TODO app)

**Live Demo:**
- API: https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io
- Vanilla JS Frontend: https://happy-desert-065eace10.6.azurestaticapps.net
- Health Check: https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/health

**Monthly Cost:** ~$0-5 (using free tiers and serverless)

---

## The Repeatable Process

### Phase 1: Choose Your Frontend Approach

```
┌─────────────┬──────────────┬─────────────────┐
│  Vanilla JS │    React     │ React Native    │
├─────────────┼──────────────┼─────────────────┤
│ Simplest    │ Standard SPA │ Mobile App      │
│ No build    │ Build step   │ Complex build   │
│ ~2 hours    │ ~3 hours     │ ~5 hours        │
│ 0 deps      │ 156 deps     │ 695 deps        │
└─────────────┴──────────────┴─────────────────┘
```

**Decision Matrix:**
- **Quick POC?** → Vanilla JS
- **Team knows React?** → React
- **Need mobile?** → React Native

See [FRAMEWORK_COMPARISON.md](FRAMEWORK_COMPARISON.md) for detailed analysis.

---

### Phase 2: Local Development

#### 2.1 Backend API (.NET Aspire)

```bash
# Clone and setup
cd TestPOCApp/TodoApp

# Copy infrastructure config (database connection, etc.)
chmod +x copy-config.sh
./copy-config.sh

# Apply database migrations
cd src/TodoApp.Api
dotnet ef database update

# Run with Aspire orchestration
cd ../..
dotnet run --project TodoApp.AppHost
```

**Aspire Dashboard:** http://localhost:17135

#### 2.2 Frontend Options

**Option A: Vanilla JS** (Served by TodoApp.Web)
- Already running via Aspire
- No build step needed
- Edit `src/TodoApp.Web/wwwroot/` files directly

**Option B: React SPA**
```bash
cd src/TodoApp.ReactWeb
npm install
npm run dev
```
- Runs at: http://localhost:3000
- Hot reload enabled
- Edit `src/` files and see changes immediately

**Option C: React Native Mobile**
```bash
cd mobile/TodoApp.Mobile
npm install
npm run android  # or npm run ios (macOS only)
```
- Requires Android Studio or Xcode
- See [mobile/TodoApp.Mobile/README.md](mobile/TodoApp.Mobile/README.md)

---

### Phase 3: Infrastructure Setup (Azure)

This POC reuses existing shared infrastructure. For a NEW POC, run:

```bash
cd apps/todo-app  # or apps/your-poc-name

# 1. Setup database (creates schema in shared sandbox DB)
./setup-database.sh

# 2. Setup static web app (for frontend)
./setup-static-web-app.sh

# 3. Optional: Storage, Key Vault, etc.
./setup-storage.sh
./setup-keyvault.sh
```

**What this creates:**
- Schema in shared SQL database (`sandbox`)
- Resource group for your POC
- Static Web App (Free tier)
- Configuration files (`.env.local`, `azure-config.json`)

**Cost:** $0 (uses free tiers)

---

### Phase 4: Deploy Backend API

```bash
cd TestPOCApp/TodoApp

# 1. Build Docker image
docker build -t wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/todoapp-api:latest \
  -f src/TodoApp.Api/Dockerfile .

# 2. Push to Azure Container Registry
az acr login --name wiscodevacr
docker push wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/todoapp-api:latest

# 3. Deploy to Container Apps (first time)
az containerapp create \
  --name todoapp-api \
  --resource-group todo-app \
  --environment todoapp-env \
  --image wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/todoapp-api:latest \
  --target-port 8080 \
  --ingress external \
  --min-replicas 0 \
  --max-replicas 1

# Or update existing app
az containerapp update \
  --name todoapp-api \
  --resource-group todo-app \
  --image wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/todoapp-api:latest
```

**Cost:** $0-2/month (consumption plan, scales to zero)

---

### Phase 5: Deploy Frontend

#### Option A: Vanilla JS

```bash
cd src/TodoApp.Web/wwwroot
swa deploy . --deployment-token "YOUR_TOKEN"
```

#### Option B: React SPA

```bash
cd src/TodoApp.ReactWeb

# 1. Set production API URL
echo "VITE_API_URL=https://YOUR-API.azurecontainerapps.io/api/todos" > .env.production

# 2. Build
npm run build

# 3. Deploy
cd dist
swa deploy . --deployment-token "YOUR_TOKEN"
```

See [DEPLOY_REACT_SPA.md](DEPLOY_REACT_SPA.md) for detailed React deployment guide.

#### Option C: React Native

```bash
cd mobile/TodoApp.Mobile

# Android
npx expo build:android

# iOS (requires macOS + Xcode)
npx expo build:ios
```

See [mobile/TodoApp.Mobile/README.md](mobile/TodoApp.Mobile/README.md) for mobile deployment.

**Cost:** $0 (Static Web Apps free tier)

---

### Phase 6: Verify Deployment

```bash
# Check API health
curl https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/health

# Check todos endpoint
curl https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/todos

# Visit frontend in browser
open https://happy-desert-065eace10.6.azurestaticapps.net
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    FRONTEND OPTIONS                     │
├──────────────┬──────────────┬───────────────────────────┤
│ Vanilla JS   │ React SPA    │ React Native              │
│ (Static)     │ (Static)     │ (Mobile App)              │
└──────┬───────┴──────┬───────┴───────┬───────────────────┘
       │              │               │
       └──────────────┼───────────────┘
                      │ HTTPS
       ┌──────────────▼──────────────┐
       │  Azure Container Apps       │
       │  (.NET 10 Minimal API)      │
       └──────────────┬──────────────┘
                      │
       ┌──────────────▼──────────────┐
       │  Azure SQL Serverless       │
       │  (sandbox DB, todo schema)  │
       └─────────────────────────────┘
```

**Key Design Decisions:**
1. **Shared Infrastructure**: One SQL server, one database, schema-per-POC
2. **Serverless**: Auto-pause when idle, pay only for usage
3. **Free Tiers**: Static Web Apps, Container Apps consumption plan
4. **Simple Deployment**: Manual Azure CLI (no complex IaC for POC)

---

## Cost Breakdown

| Resource | Tier | Monthly Cost |
|----------|------|--------------|
| Azure SQL Database | Free (serverless) | $0 |
| Container Apps | Consumption | $0-2 |
| Static Web Apps | Free | $0 |
| Container Registry | Basic | $5 |
| **Total** | | **$5-7/month** |

**Cost Optimization:**
- Auto-pause SQL when idle (60 min)
- Container Apps scale to 0 replicas
- Static content served from free tier
- Shared infrastructure across POCs

---

## Files & Directories

```
TestPOCApp/TodoApp/
├── src/
│   ├── TodoApp.Api/              # .NET Web API
│   ├── TodoApp.Web/              # Vanilla JS frontend
│   └── TodoApp.ReactWeb/         # React SPA frontend
├── mobile/
│   └── TodoApp.Mobile/           # React Native app
├── TodoApp.AppHost/              # Aspire orchestration
├── TodoApp.ServiceDefaults/      # Shared configs
├── README.md                     # Quick start
├── DEPLOY_REACT_SPA.md          # React deployment guide
├── FRAMEWORK_COMPARISON.md      # Honest comparison
└── THIS_FILE.md                 # You are here
```

---

## GitHub Copilot Integration

This repository includes instructions for GitHub Copilot to automate POC creation:

**Location:** `.github/instructions/`

- `aspire-development.instructions.md` - Aspire patterns
- `javascript-frontend.instructions.md` - Frontend patterns
- `poc-setup.instructions.md` - Infrastructure setup
- `azure-operations.instructions.md` - Azure CLI operations

**Usage:**
```
@workspace Create a new POC called "MyApp" with React frontend
```

Copilot will:
1. Generate Aspire solution structure
2. Create database schema
3. Setup infrastructure scripts
4. Configure deployment

---

## Troubleshooting

### Database Connection Timeout

**Cause:** Azure SQL Serverless is waking up (30-60s on first request)

**Solution:** API has retry logic configured (5 retries, 30s max delay). Just wait.

### CORS Errors

**Cause:** API not allowing frontend domain

**Solution:** Update `Program.cs`:
```csharp
policy.WithOrigins(
    "https://localhost:3000",
    "https://*.azurestaticapps.net"
);
```

### React Build Fails

```bash
# Clear and rebuild
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Container Apps Not Starting

```bash
# Check logs
az containerapp logs show \
  --name todoapp-api \
  --resource-group todo-app \
  --follow
```

---

## Next Steps

### For Production

1. **Add Authentication** (Azure AD B2C or Auth0)
2. **Add Monitoring** (Application Insights)
3. **Setup CI/CD** (GitHub Actions)
4. **Add Tests** (xUnit for API, Jest for React)
5. **Custom Domain** (Free with Static Web Apps)

### For Learning

1. Try deploying with Bicep/ARM templates
2. Add Redis cache for performance
3. Implement SignalR for real-time updates
4. Add background jobs with Azure Functions

---

## Key Lessons (Harsh Truth)

✅ **What worked:**
- Starting with Vanilla JS is faster than React for simple POCs
- Sharing infrastructure dramatically reduces cost
- Manual Azure CLI is simpler than IaC for POCs
- .NET Aspire makes local dev much easier

❌ **What didn't:**
- React adds significant complexity for minimal benefit (for this simple app)
- React Native is overkill unless you NEED mobile
- Auto-scaling is unnecessary for low-traffic POCs
- Complex IaC (Bicep/Terraform) is premature for POCs

**Recommendation:** Start simple, add complexity only when justified.

---

## Resources

- [Azure Static Web Apps Docs](https://docs.microsoft.com/azure/static-web-apps/)
- [.NET Aspire Docs](https://learn.microsoft.com/dotnet/aspire/)
- [React Native Expo Docs](https://docs.expo.dev/)
- [Azure Container Apps Docs](https://learn.microsoft.com/azure/container-apps/)

---

**Last Updated:** February 16, 2026  
**Author:** GitHub Copilot (with harsh self-critique enabled)  
**License:** MIT

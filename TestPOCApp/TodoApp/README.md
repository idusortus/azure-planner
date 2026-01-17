# TODO App - Aspire Solution

**Location**: `/TestPOCApp/TodoApp`  
**Framework**: .NET 10 Aspire  
**Status**: ✅ DEPLOYED TO AZURE

## 🌐 Live URLs

| Component | URL |
|-----------|-----|
| **API** | https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io |
| **Health Check** | https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/health |
| **Todos Endpoint** | https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/todos |
| **Frontend** | https://happy-desert-065eace10.6.azurestaticapps.net |

## Quick Start (Local Development)

### 1. Copy Configuration

```bash
chmod +x copy-config.sh
./copy-config.sh
```

This copies database credentials and Azure resource details from `apps/todo-app/`.

### 2. Apply Database Migration

```bash
cd src/TodoApp.Api
dotnet ef database update
```

### 3. Run with Aspire

```bash
cd ../..
dotnet run --project TodoApp.AppHost
```

The Aspire Dashboard will open at: **https://localhost:17135** (or similar)

### 4. Access the App

Check the Aspire dashboard for service URLs:
- **Frontend**: Click the "web" endpoint
- **API**: Click the "api" endpoint (add `/api/todos` to path)
- **Health**: API endpoint + `/health`

## Local Testing - ✅ Verified Working

- ✅ Database migration applied successfully
- ✅ Aspire orchestration running
- ✅ API serving at assigned port
- ✅ Frontend connecting to API via service discovery
- ✅ Full CRUD operations functional

## Project Structure

```
TodoApp/
├── TodoApp.sln
├── TodoApp.AppHost/          # Aspire orchestrator
│   └── AppHost.cs            # Defines services
├── TodoApp.ServiceDefaults/  # Shared Aspire defaults
├── src/
│   ├── TodoApp.Api/          # .NET Web API
│   │   ├── Program.cs        # API endpoints
│   │   ├── Models/
│   │   │   └── TodoItem.cs
│   │   ├── Data/
│   │   │   └── TodoDbContext.cs
│   │   └── Migrations/       # EF Core migrations
│   └── TodoApp.Web/          # Static frontend host
│       ├── Program.cs
│       └── wwwroot/
│           ├── index.html
│           ├── css/styles.css
│           └── js/app.js
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/todos` | Get all todos |
| GET | `/api/todos/{id}` | Get todo by ID |
| POST | `/api/todos` | Create new todo |
| PUT | `/api/todos/{id}` | Update todo |
| DELETE | `/api/todos/{id}` | Delete todo |
| GET | `/health` | Health check |

## Deployment to Azure

### Deploy API (Container Apps)

```powershell
# From TestPOCApp/TodoApp/
.\deploy-to-azure.ps1
```

### Deploy Frontend (Static Web Apps)

```powershell
# From TestPOCApp/TodoApp/
.\deploy-frontend.ps1
```

### Manual Deployment

```bash
# Build and push Docker image
az acr login --name wiscodevacr
docker build -t wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/todoapp-api:latest -f src/TodoApp.Api/Dockerfile .
docker push wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/todoapp-api:latest

# Deploy to Container Apps
az containerapp update --name todoapp-api --resource-group todo-app --image wiscodevacr-b0cegxg6hnd2bwc8.azurecr.io/todoapp-api:latest

# Deploy frontend
cd src/TodoApp.Web/wwwroot
swa deploy . --deployment-token "[token from azure-static-web-config.json]"
```

## Azure Resources

| Resource | Type | Location |
|----------|------|----------|
| `todo-app` | Resource Group | centralus |
| `todo-app-db` | Azure SQL Database | Shared/dev-wiscodev |
| `todo-app-web` | Static Web App | todo-app |
| `todoapp-env` | Container Apps Environment | todo-app |
| `todoapp-api` | Container App | todo-app |
| `wiscodevacr` | Container Registry | Shared |

## Troubleshooting

### Database Connection Timeout
Azure SQL Serverless may take 30-60 seconds to wake up on first connection. The API has retry logic configured (5 retries, 30s max delay).

### CORS Errors
The API is configured to allow all origins for development. Update `Program.cs` for production.

### Migration Errors
Ensure your IP is whitelisted in Azure SQL firewall (run `setup-database.sh` again if IP changed).

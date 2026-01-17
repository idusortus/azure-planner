# TODO App - Aspire Solution

**Location**: `/TestPOCApp/TodoApp`  
**Framework**: .NET 9 Aspire  
**Status**: Ready for local testing

## Quick Start

### 1. Set Database Password

Edit `src/TodoApp.Api/appsettings.Development.json` and replace `YOUR_PASSWORD_HERE` with your actual SQL Server password.

### 2. Apply Database Migration

```bash
cd TestPOCApp/TodoApp/src/TodoApp.Api

# Set connection string (replace YOUR_PASSWORD with actual)
export CONNECTION_STRING="Server=tcp:dev-wiscodev.database.windows.net,1433;Database=todo-app-db;User ID=sqladmin;Password=YOUR_PASSWORD;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Apply migration
dotnet ef database update --connection "$CONNECTION_STRING"
```

### 3. Run with Aspire

```bash
cd TestPOCApp/TodoApp
dotnet run --project TodoApp.AppHost
```

The Aspire Dashboard will open at: **http://localhost:15888**

### 4. Access the App

- **Frontend**: http://localhost:5000 (or check Aspire dashboard)
- **API**: http://localhost:5001/api/todos (or check Aspire dashboard)
- **Health**: http://localhost:5001/health

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

```bash
# Initialize Azure Developer CLI
azd init

# Deploy to Azure
azd up
```

This will deploy:
- Container App for the API
- Static Web App for the frontend (already created)
- Connect to existing Azure SQL Database

## Troubleshooting

### Database Connection Timeout
Azure SQL Serverless may take 30-60 seconds to wake up on first connection. The API has retry logic configured (5 retries, 30s max delay).

### CORS Errors
The API is configured to allow all origins for development. Update `Program.cs` for production.

### Migration Errors
Ensure your IP is whitelisted in Azure SQL firewall (run `setup-database.sh` again if IP changed).

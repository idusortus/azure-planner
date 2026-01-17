# POC Application to Aspire Architecture Conversion

**Purpose**: Convert existing JavaScript POC applications into a standardized .NET Aspire solution with budget-friendly Azure deployment.

## Target Architecture Overview

Transform the existing POC application into a .NET Aspire solution with the following structure:

```
{AppName}.sln                          # Solution file
src/
  {AppName}.AppHost/                   # Aspire orchestration
    Program.cs
    appsettings.json
  {AppName}.ServiceDefaults/           # Shared configurations
    Extensions.cs
  {AppName}.Api/                       # .NET WebAPI backend
    Program.cs
    appsettings.json
    Controllers/
    Models/
    Services/
  {AppName}.Web/                       # JavaScript SPA frontend
    wwwroot/
      index.html
      css/
      js/
        app.js                          # Vanilla JavaScript (preferred)
      assets/
```

## Conversion Requirements

### 1. Frontend Requirements

**Technology**: JavaScript SPA (Vanilla JavaScript preferred, framework acceptable if existing)

**Structure**:
- Move all frontend code to `{AppName}.Web/wwwroot/`
- Use static file hosting (no server-side rendering required)
- **Key Change**: Update all API calls to use Aspire service discovery or environment-based API URL
  ```javascript
  // Example API call pattern
  const apiBaseUrl = window.ENV?.API_URL || 'https://localhost:7001';
  
  async function fetchData() {
    const response = await fetch(`${apiBaseUrl}/api/data`);
    return await response.json();
  }
  ```

**Azure Deployment Target**: Azure Static Web Apps (Free Tier)

### 2. Backend API Requirements

**Technology**: .NET 10 WebAPI (C#)

**Key Components**:
- Migrate all API endpoints to ASP.NET Core controllers
- Implement dependency injection for services
- Add Azure SQL database integration using Entity Framework Core
- Configure CORS for Static Web App origin
- Add health checks for Aspire monitoring

**Connection String Pattern**:
```csharp
// The user will provide the actual connection string
// Use this configuration pattern in appsettings.json:
{
  "ConnectionStrings": {
    "DefaultConnection": "TO_BE_PROVIDED"
  }
}
```

**Azure Deployment Target**: Azure Container Apps (Consumption plan, auto-scale to zero)

### 3. Database Configuration

**Provider**: Azure SQL Database (Serverless, free tier eligible)

**Requirements**:
- Create Entity Framework Core DbContext
- Design migrations for schema
- Use connection resiliency for serverless database (handles auto-pause)
- **Connection string will be provided separately** - leave placeholder in config

**DbContext Pattern**:
```csharp
builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sqlOptions =>
        {
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 5,
                maxRetryDelay: TimeSpan.FromSeconds(30),
                errorNumbersToAdd: null);
        });
});
```

### 4. Service Bus Integration (Optional)

**When to Include**: If the application requires:
- Background processing
- Message queuing
- Event-driven communication
- Asynchronous workflows

**Shared Resource**: Use existing Service Bus namespace `wiscoshared` in resource group `Shared` (centralus)

**Configuration Pattern**:
```csharp
// Connection string will be provided if needed
builder.AddAzureServiceBusClient("messaging");
```

**Leave placeholder if Service Bus is needed**:
```json
{
  "Azure": {
    "ServiceBus": {
      "Namespace": "TO_BE_PROVIDED",
      "ConnectionString": "TO_BE_PROVIDED"
    }
  }
}
```

### 5. Aspire Orchestration Setup

**AppHost Program.cs Structure**:
```csharp
var builder = DistributedApplication.CreateBuilder(args);

// Add SQL Server (local for development)
var sqlServer = builder.AddSqlServer("sql")
    .WithLifetime(ContainerLifetime.Persistent);

var database = sqlServer.AddDatabase("appdb");

// Add Service Bus if needed (uncomment if required)
// var serviceBus = builder.AddAzureServiceBus("messaging");

// Add API project
var api = builder.AddProject<Projects.{AppName}_Api>("api")
    .WithReference(database)
    // .WithReference(serviceBus)  // Uncomment if needed
    .WithReplicas(1);

// Add Web frontend
builder.AddProject<Projects.{AppName}_Web>("web")
    .WithReference(api)
    .WithExternalHttpEndpoints();

builder.Build().Run();
```

## Conversion Steps

Follow these steps to convert the existing application:

### Step 1: Create Aspire Solution Structure
```bash
dotnet new aspire -n {AppName}
cd {AppName}
```

### Step 2: Create API Project
```bash
dotnet new webapi -n {AppName}.Api -o src/{AppName}.Api
dotnet sln add src/{AppName}.Api
```

### Step 3: Create Web Project (Static Files)
```bash
dotnet new web -n {AppName}.Web -o src/{AppName}.Web
dotnet sln add src/{AppName}.Web
```

### Step 4: Migrate Backend Code
1. **Extract API logic** from existing project
2. **Create controllers** for each endpoint group
3. **Implement services** with dependency injection
4. **Add Entity Framework models** matching database schema
5. **Configure CORS** for frontend origin

### Step 5: Migrate Frontend Code
1. **Copy all HTML/CSS/JS** to `{AppName}.Web/wwwroot/`
2. **Update API URLs** to use environment-based configuration
3. **Ensure static file middleware** is configured in Program.cs
4. **Test locally** with Aspire dashboard

### Step 6: Configure Database
1. **Add EF Core packages**:
   ```bash
   dotnet add src/{AppName}.Api package Microsoft.EntityFrameworkCore.SqlServer
   dotnet add src/{AppName}.Api package Microsoft.EntityFrameworkCore.Design
   ```
2. **Create DbContext** and models
3. **Add migrations**:
   ```bash
   dotnet ef migrations add InitialCreate --project src/{AppName}.Api
   ```
4. **Leave connection string as placeholder** - will be provided later

### Step 7: Wire Up Aspire References
1. Update AppHost to reference API and Web projects
2. Add database reference to API project
3. Configure service discovery between frontend and backend
4. Test with `dotnet run --project src/{AppName}.AppHost`

## Budget-Friendly Azure Deployment Configuration

### Cost Optimization Requirements

**API Deployment (Container Apps)**:
- **Tier**: Consumption plan
- **Scaling**: Scale to zero when idle
- **Min Replicas**: 0
- **Max Replicas**: 2 (for POC)
- **Expected Cost**: $0-2/month

**Frontend Deployment (Static Web Apps)**:
- **Tier**: Free
- **Expected Cost**: $0/month

**Database (Azure SQL)**:
- **Tier**: Serverless (Basic or GP)
- **Auto-pause**: 60 minutes of inactivity
- **Min vCores**: 0.5
- **Max vCores**: 1-2 (as needed)
- **Expected Cost**: $0-5/month (minimal activity)

**Service Bus (Shared)**:
- **Namespace**: wiscoshared (pre-existing)
- **Expected Cost**: Shared across POCs ($0 incremental if Basic tier)

### Deployment Commands (Reference)

The conversion should result in a project that can be deployed with:

```bash
# Deploy with Azure Developer CLI
azd init
azd up
```

Or manually:
```bash
# Container Apps deployment
az containerapp up --name {app}-api --resource-group Shared --location centralus

# Static Web App deployment
az staticwebapp create --name {app}-web --resource-group Shared --location centralus
```

## Expected Deliverables

After conversion, the project should include:

### ✅ Required Files
- [ ] `{AppName}.sln` - Solution file
- [ ] `src/{AppName}.AppHost/Program.cs` - Aspire orchestration
- [ ] `src/{AppName}.Api/Program.cs` - WebAPI with health checks
- [ ] `src/{AppName}.Api/Controllers/` - Migrated API endpoints
- [ ] `src/{AppName}.Api/Data/AppDbContext.cs` - EF Core context
- [ ] `src/{AppName}.Api/Models/` - Entity models
- [ ] `src/{AppName}.Web/wwwroot/index.html` - Frontend entry point
- [ ] `src/{AppName}.Web/wwwroot/js/app.js` - JavaScript logic
- [ ] `src/{AppName}.Web/Program.cs` - Static file hosting

### ✅ Configuration Files
- [ ] `src/{AppName}.Api/appsettings.json` - With connection string placeholder
- [ ] `src/{AppName}.AppHost/appsettings.json` - Aspire settings
- [ ] `.github/workflows/azure-deploy.yml` (optional) - CI/CD pipeline

### ✅ Documentation
- [ ] `README.md` - Project overview, setup instructions, deployment guide
- [ ] `docs/API.md` - API endpoint documentation
- [ ] `docs/DEPLOYMENT.md` - Azure deployment instructions

## Post-Conversion Checklist

After restructuring, verify:

- [ ] **Local Development**: `dotnet run --project src/{AppName}.AppHost` works
- [ ] **Aspire Dashboard**: Accessible at `http://localhost:15888`
- [ ] **API Health**: Health endpoint responds at `/health`
- [ ] **Frontend Loads**: SPA loads in browser
- [ ] **API Communication**: Frontend successfully calls API
- [ ] **Database Placeholder**: Connection string clearly marked as TO_BE_PROVIDED
- [ ] **Service Bus Placeholder**: Config present if needed, marked as TO_BE_PROVIDED
- [ ] **Cost Estimation**: Documented in README (target: $0-5/month)
- [ ] **Cleanup Commands**: Provided for all Azure resources

## Additional Notes

### Resource Naming Convention
Use this pattern for Azure resources:
- **API**: `{appname}-api-{region}` (e.g., `polymarket-api-centralus`)
- **Web**: `{appname}-web-{region}` (e.g., `polymarket-web-centralus`)
- **Database**: `{appname}-db` (e.g., `polymarket-db`)

### Existing Infrastructure
- **Resource Group**: `Shared` (centralus) - use this for all resources
- **Service Bus**: `wiscoshared` - already exists for message queuing
- **SQL Server**: TBD - may need to create per-app or share logical server

### Testing Before Deployment
Before deploying to Azure:
1. Run locally with Aspire: `dotnet run --project src/{AppName}.AppHost`
2. Test all API endpoints
3. Verify frontend loads and interacts with API
4. Confirm database migrations work (against local SQL Server container)

### Migration Strategy
1. **Start with backend**: Get API working first
2. **Then frontend**: Ensure static files serve correctly
3. **Add database**: Wire up EF Core and migrations
4. **Service Bus last**: Only if application needs it

---

## Ready to Convert?

Provide this document to GitHub Copilot agent along with:
1. **Your existing POC repository**
2. **Desired app name** (will be used for solution naming)
3. **Database connection string** (when ready to deploy)
4. **Service Bus connection string** (if needed)

The agent will restructure your application following this guide, optimizing for:
- ✅ Budget-friendly Azure deployment ($0-5/month target)
- ✅ .NET Aspire orchestration
- ✅ Modern JavaScript SPA frontend
- ✅ Scalable .NET WebAPI backend
- ✅ Azure SQL serverless database
- ✅ Optional shared Service Bus integration

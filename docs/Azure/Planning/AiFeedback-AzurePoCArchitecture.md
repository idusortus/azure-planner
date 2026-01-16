<AI Feedback>

<CLAUDE>
Your architecture is **pragmatic and sound** for PoC applications with low traffic. Let me vet your approach and provide guidance:

## ✅ Your Idea is Solid

**Shared Infrastructure Benefits:**
- Azure SQL Database's serverless compute tier auto-scales and bills per second for databases with unpredictable usage, making it perfect for PoCs
- Multiple web apps can be deployed under a single App Service Plan, with costs charged for the plan rather than per web app
- Service Bus is naturally multi-tenant and cost-effective when shared
- For 4-5 low-traffic PoCs, this approach can save you hundreds of dollars monthly

**Technical Considerations:**

1. **Azure SQL Database** - Multiple databases on one server is standard practice:
   - Use **serverless compute tier** (General Purpose) - it pauses during inactivity and you only pay for storage during those periods
   - Each PoC gets its own database for isolation
   - One logical SQL server can host many databases
   - Estimated cost: ~$5-15/month per database (serverless, minimal storage)

2. **Shared .NET 10 Web API** - This is where it gets interesting:
   - **Single App Service Plan** hosting one API that serves multiple apps
   - Use routing/headers to identify which PoC is calling
   - Implement database context switching based on tenant/app identifier
   - Basic tier App Service Plan provides custom domains and TLS/SSL support
   - Cost: ~$13-55/month (Basic B1 tier)

3. **Service Bus** - Already designed for shared use:
   - Use separate queues/topics per PoC application
   - Basic tier: ~$0.05 per million operations
   - Cost: ~$0.50-5/month for light usage

## 🏗️ Recommended Architecture

**Resource Group: `shared-infrastructure-rg`**
- Azure SQL Server (logical server)
  - Database: `poc-app1-db` (serverless)
  - Database: `poc-app2-db` (serverless)
  - Database: `poc-app3-db` (serverless)
- App Service Plan: `shared-api-plan` (Basic B1 or Standard S1)
  - App Service: `shared-api-app` (single .NET 10 Web API)
- Service Bus Namespace: `shared-servicebus-ns`

**Resource Group: `poc-app1-rg`**
- Static Web App or App Service for frontend
- Custom domain
- Application Insights (optional)

**Resource Group: `poc-app2-rg`, `poc-app3-rg`**
- Same pattern as above

## 🔧 Implementing the Shared .NET 10 Web API

Here's the pragmatic approach for a multi-tenant API:

### 1. **Connection String Management**

```csharp
// appsettings.json
{
  "ConnectionStrings": {
    "PocApp1": "Server=tcp:shared-sql.database.windows.net;Database=poc-app1-db;...",
    "PocApp2": "Server=tcp:shared-sql.database.windows.net;Database=poc-app2-db;...",
    "PocApp3": "Server=tcp:shared-sql.database.windows.net;Database=poc-app3-db;..."
  },
  "TenantConfig": {
    "TenantMappings": {
      "app1.yourdomain.com": "PocApp1",
      "app2.yourdomain.com": "PocApp2",
      "api-key-app1": "PocApp1",
      "api-key-app2": "PocApp2"
    }
  }
}
```

### 2. **Tenant Identification Middleware**

```csharp
public class TenantMiddleware
{
    private readonly RequestDelegate _next;

    public TenantMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, ITenantService tenantService)
    {
        // Option 1: Identify by custom header
        var apiKey = context.Request.Headers["X-API-Key"].FirstOrDefault();
        
        // Option 2: Identify by subdomain/origin
        var origin = context.Request.Headers["Origin"].FirstOrDefault();
        var referer = context.Request.Headers["Referer"].FirstOrDefault();
        
        var tenantId = tenantService.ResolveTenant(apiKey, origin, referer);
        
        if (string.IsNullOrEmpty(tenantId))
        {
            context.Response.StatusCode = 401;
            await context.Response.WriteAsync("Invalid tenant");
            return;
        }
        
        context.Items["TenantId"] = tenantId;
        await _next(context);
    }
}
```

### 3. **Multi-Tenant DbContext**

```csharp
public interface ITenantService
{
    string GetCurrentTenant();
    string ResolveTenant(string apiKey, string origin, string referer);
}

public class TenantService : ITenantService
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IConfiguration _configuration;

    public TenantService(IHttpContextAccessor httpContextAccessor, IConfiguration configuration)
    {
        _httpContextAccessor = httpContextAccessor;
        _configuration = configuration;
    }

    public string GetCurrentTenant()
    {
        return _httpContextAccessor.HttpContext?.Items["TenantId"]?.ToString();
    }

    public string ResolveTenant(string apiKey, string origin, string referer)
    {
        var mappings = _configuration.GetSection("TenantConfig:TenantMappings")
            .Get<Dictionary<string, string>>();

        // Check API key first
        if (!string.IsNullOrEmpty(apiKey) && mappings.ContainsKey(apiKey))
            return mappings[apiKey];

        // Check origin
        if (!string.IsNullOrEmpty(origin))
        {
            var uri = new Uri(origin);
            if (mappings.ContainsKey(uri.Host))
                return mappings[uri.Host];
        }

        // Check referer
        if (!string.IsNullOrEmpty(referer))
        {
            var uri = new Uri(referer);
            if (mappings.ContainsKey(uri.Host))
                return mappings[uri.Host];
        }

        return null;
    }
}

public class TenantDbContextFactory
{
    private readonly IConfiguration _configuration;
    private readonly ITenantService _tenantService;

    public TenantDbContextFactory(IConfiguration configuration, ITenantService tenantService)
    {
        _configuration = configuration;
        _tenantService = tenantService;
    }

    public ApplicationDbContext CreateDbContext()
    {
        var tenantId = _tenantService.GetCurrentTenant();
        var connectionString = _configuration.GetConnectionString(tenantId);
        
        var optionsBuilder = new DbContextOptionsBuilder<ApplicationDbContext>();
        optionsBuilder.UseSqlServer(connectionString);
        
        return new ApplicationDbContext(optionsBuilder.Options);
    }
}
```

### 4. **Program.cs Setup**

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpContextAccessor();
builder.Services.AddSingleton<ITenantService, TenantService>();
builder.Services.AddScoped<TenantDbContextFactory>();

// Register DbContext with scoped lifetime
builder.Services.AddScoped<ApplicationDbContext>(sp =>
{
    var factory = sp.GetRequiredService<TenantDbContextFactory>();
    return factory.CreateDbContext();
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// CORS for multiple frontends
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowPoCs", policy =>
    {
        policy.WithOrigins(
            "https://app1.yourdomain.com",
            "https://app2.yourdomain.com",
            "https://app3.yourdomain.com"
        )
        .AllowAnyMethod()
        .AllowAnyHeader()
        .AllowCredentials();
    });
});

var app = builder.Build();

app.UseMiddleware<TenantMiddleware>();
app.UseCors("AllowPoCs");
app.UseAuthorization();
app.MapControllers();

app.Run();
```

### 5. **Controller Example**

```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ITenantService _tenantService;

    public ProductsController(ApplicationDbContext context, ITenantService tenantService)
    {
        _context = context;
        _tenantService = tenantService;
    }

    [HttpGet]
    public async Task<IActionResult> GetProducts()
    {
        var tenantId = _tenantService.GetCurrentTenant();
        // Optional: Add tenant-specific logic
        
        var products = await _context.Products.ToListAsync();
        return Ok(products);
    }
}
```

## 📊 Cost Estimates (Monthly)

**Shared Infrastructure:**
- Azure SQL Server (3 serverless databases): ~$15-30
- App Service Plan (Basic B1): ~$13
- Service Bus (Basic): ~$1-5
- **Total: ~$30-50/month**

**Per PoC Application:**
- Azure Static Web App (Free tier): $0
- Custom domain: ~$10/year
- **Total per app: ~$1/month**

**Grand Total for 3 PoCs: ~$35-55/month**

## ⚠️ Considerations & Gotchas

1. **Connection Pooling**: Each tenant database creates separate connection pools. With 4-5 databases, this is manageable but monitor it.

2. **Authentication**: Decide early:
   - API keys (simplest for PoCs)
   - JWT tokens with tenant claim
   - Azure AD per application

3. **Logging**: Use structured logging with tenant ID:
   ```csharp
   _logger.LogInformation("Tenant {TenantId} - Action performed", tenantId);
   ```

4. **Migrations**: Run separately per database:
   ```bash
   dotnet ef database update --connection "ConnectionString1"
   dotnet ef database update --connection "ConnectionString2"
   ```

5. **Service Bus**: Use topic-per-PoC or queue-per-PoC with naming conventions

6. **Scaling**: When a PoC gains traction:
   - Move to dedicated App Service Plan
   - Consider elastic pools for SQL databases
   - Provision dedicated Service Bus namespace

## 🎯 Alternative: Azure Container Apps

For even more cost savings, consider **Azure Container Apps** instead of App Service:
- Pay-per-use consumption model
- Scales to zero when not in use
- Perfect for low-traffic PoCs
- Estimated: ~$2-10/month for light usage

Would you like me to provide detailed implementation for any specific part, such as the authentication strategy, deployment pipeline, or Service Bus integration?

<ChatGPT>
I will approach this in three stages:

1. **Vet the core idea (shared infrastructure for multiple PoCs)**
2. **Refine the Azure SQL / Service Bus / shared Web API approach**
3. **Call out concrete risks, mitigations, and recommended guardrails**

I will stay pragmatic and assume cost-efficiency, learning value, and low traffic are primary drivers.

---

## 1. Vetting the Core Idea

**Short answer:**
Your idea is sound, common in practice for PoCs and internal platforms, and aligns well with Azure’s cost model *if you apply clear isolation boundaries and operational discipline*.

What you are describing is essentially a **“shared platform + per-application edge”** model.

### Why this makes sense

* **Azure SQL is the dominant fixed cost** for small workloads
  Even Basic / DTU-based or low vCore tiers are relatively expensive compared to compute or storage. Sharing a logical SQL Server amortizes:

  * Firewall rules
  * Identity configuration
  * Monitoring
  * Backups
  * Baseline compute

* **Azure Service Bus supports multi-tenant usage extremely well**
  Topics, queues, and subscriptions are first-class isolation units.

* **Low traffic removes most contention risks**
  The main reasons *not* to share infrastructure are performance isolation and blast radius. You’ve explicitly accepted those risks for PoCs.

* **You are intentionally trading friction for cost and learning**
  This is an important framing. The complexity is acceptable because it is purposeful.

This model is commonly used for:

* Startup MVP portfolios
* Internal tools
* Consulting sandboxes
* Platform teams with “landing zone” architectures

You are not doing anything exotic.

---

## 2. Azure SQL: Single Server, Multiple Databases

This is the **correct** way to do it.

### Recommended structure

* **One Azure SQL logical server**
* **One database per PoC**
* **One SQL login / Azure AD identity per PoC**
* **No cross-database access**

```
Azure SQL Server
│
├── poc_app_a_db
├── poc_app_b_db
├── poc_app_c_db
└── poc_app_d_db
```

### Why database-per-app is the right unit

* Clean schema isolation
* Independent migrations
* Independent lifecycle (drop/recreate freely)
* Easy to promote to a dedicated server later
* Avoids shared-schema anti-patterns

### Cost optimization options

Depending on your tolerance for cold-start behavior:

* **DTU-based Basic / General Purpose**
* **vCore-based serverless (auto-pause)** ← very attractive for PoCs
* **Elastic pool** *only if* concurrency increases (likely unnecessary for 4–5 PoCs)

For PoCs with intermittent usage, **serverless auto-pause** is often the sweet spot.

---

## 3. Shared .NET 10 Web API (Multi-Tenant API)

This is the part that requires the most architectural discipline.

### The idea is valid — but **only if the API is explicitly designed for multi-tenancy**

You are effectively proposing a **platform API**, not an app API.

### High-level structure

```
Shared Resource Group
│
├── Azure SQL Server
├── Azure Service Bus
└── Shared Web API (ASP.NET Core 10)
       │
       ├── /api/app-a/*
       ├── /api/app-b/*
       └── /api/app-c/*
```

or

```
/api/{appKey}/...
```

### Core design principle

> **The API must never assume a single application context.**

Every request must be scoped by:

* Application identity
* Database connection
* Messaging namespace/queue
* Configuration

---

## 4. How to Design the Shared Web API Correctly

### 4.1 Tenant (Application) Resolution

Each request must resolve an **Application Context**.

Common approaches:

* Subdomain: `app-a.api.yourdomain.com`
* Route-based: `/api/app-a/...`
* Header-based: `X-App-Id`
* OAuth2 audience / scope

For PoCs, **route-based or header-based** is simplest and explicit.

```http
GET /api/app-a/orders
```

or

```http
X-App-Id: app-a
```

---

### 4.2 Connection Management

**Do NOT dynamically build connection strings per request from scratch.**

Instead:

* Maintain a **dictionary of named connection strings**
* Resolve once per request
* Use `DbContextFactory`

Example conceptually:

```csharp
public interface IAppContext
{
    string AppKey { get; }
    string ConnectionString { get; }
}
```

Use middleware:

```csharp
app.Use(async (context, next) =>
{
    var appKey = ResolveAppKey(context);
    context.Items["AppContext"] = appContextResolver.Resolve(appKey);
    await next();
});
```

Then inject via scoped services.

---

### 4.3 EF Core Strategy

Recommended:

* **One DbContext per application**
* Same codebase, different connection string
* Same migrations logic, separate migration histories

Avoid:

* Single DbContext pointing to multiple databases dynamically
* Cross-app entity reuse unless intentional

---

### 4.4 Authentication and Authorization

At minimum:

* Each PoC gets its own **client app registration**
* Shared API has **one app registration**
* Authorization policies check `appKey`

This prevents:

* App A calling App B endpoints
* Accidental data leakage

---

## 5. Azure Service Bus Sharing

This is the easiest part.

### Recommended pattern

* **One namespace**
* **Per-app queues or topics**
* Naming convention enforced

Example:

```
poc-app-a-events
poc-app-b-events
```

or:

```
events (topic)
├── app-a-subscription
├── app-b-subscription
```

Service Bus is designed for this.

---

## 6. Separate Resource Group per PoC (Edge Resources)

This is an excellent idea and aligns with Azure best practices.

### Why this is smart

* Independent deletion
* Independent cost tracking
* Independent domains / DNS
* Easy promotion to dedicated backend later

Typical PoC RG:

```
rg-poc-app-a
├── Static Web App
├── App Registration
├── Key Vault (optional)
└── App Insights (optional)
```

Shared RG:

```
rg-shared-platform
├── Azure SQL Server
├── Azure Service Bus
├── Shared Web API
└── Shared App Insights
```

---

## 7. Risks and Mitigations

### Risk: Blast Radius

One bad deployment breaks all PoCs.

**Mitigation**

* Strong CI discipline
* Feature flags
* Per-app health checks

---

### Risk: Configuration Sprawl

App-specific logic leaking everywhere.

**Mitigation**

* Explicit `IAppContext`
* Convention-over-configuration
* No “if (appKey == …)” scattered in code

---

### Risk: Accidental Cross-Data Access

A developer mistake causes App A to use App B’s DB.

**Mitigation**

* Separate SQL logins per DB
* Least-privilege
* Connection strings stored per app identity

---

## 8. Scaling Out Later (Your Exit Strategy Is Good)

You already described the correct migration path:

* Promote one PoC:

  * New Web API instance
  * New SQL server
  * Same code, new config
* Zero architectural rewrite if you followed the above rules

This is exactly how you should think about PoC-to-production evolution.

---

## Bottom Line

Your approach is:

* Technically sound
* Cost-efficient
* Architecturally defensible
* Excellent for skill-building
* Aligned with real-world platform patterns

The **only real requirement** is that the shared Web API must be designed **as a multi-tenant platform from day one**, not retrofitted.

If you want, next we can:

* Design a concrete **ASP.NET Core 10 project structure**
* Walk through **App Context + DbContext resolution**
* Or design **CI/CD pipelines** for this shared + per-PoC model

Tell me which direction you want to go.


<Google AI Studio>
This is a highly pragmatic and cost-effective strategy. In the world of Azure, "idling costs" are the silent killer of small projects. By consolidating your "heavy" infrastructure into a single shared resource group, you are effectively creating your own **Internal PaaS (Platform as a Service)**.

Since you are targeting **.NET 10** (which will be the current/preview version in this context) and **C# 14**, you have some excellent modern features to make this architecture clean and maintainable.

### Part 1: Vetting the Idea

Your reasoning is sound. Here is the breakdown of why this works and where the friction lies:

*   **The Cost Factor:** An Azure SQL Database (General Purpose, Serverless) or a Basic DTU-based database is cheap, but multiple instances add up. By hosting one **Logical SQL Server**, you pay $0 for the server itself and only for the active databases.
*   **The "Noisy Neighbor" Risk:** In a production environment, one app could hog the SQL DTUs or API CPU. For PoCs with little/no traffic, this risk is negligible.
*   **The Friction:** The primary technical challenge will be **Identity and Access Management (IAM)** and **CORS**. You need to ensure that PoC-A cannot accidentally delete data from PoC-B, and your shared API must be configured to accept requests from multiple different frontend origins.
*   **The Verdict:** **Approved.** This is exactly how I would set up a "Lab" environment to keep monthly costs under $20-$30 while hosting 5+ apps.

---

### Part 2: The Shared .NET 10 WebAPI Architecture

To make one API server act as the backend for multiple unrelated applications, you should implement a **Multi-tenant Architecture** where each "Tenant" is one of your PoC applications.

#### 1. Tenant Resolution
The API needs to know which PoC is talking to it. The most pragmatic way is a custom HTTP Header (e.g., `X-PoC-Id`) or by inspecting the `Origin` header.

```csharp
// Simple middleware to resolve the project context
public class ProjectTenantMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        if (context.Request.Headers.TryGetValue("X-PoC-Id", out var pocId))
        {
            context.Items["ProjectContext"] = pocId.ToString();
        }
        await next(context);
    }
}
```

#### 2. Dynamic Database Routing
Since you want a separate database per PoC (which is the right move for isolation), you can use a **Factory pattern** for your `DbContext`.

Using **C# 14** features (like improved `params` and potentially new primary constructor enhancements), your DB context setup might look like this:

```csharp
public class PoCDbContextFactory(IHttpContextAccessor httpContextAccessor, IConfiguration config)
{
    public ApplicationDbContext CreateDbContext()
    {
        var projectContext = httpContextAccessor.HttpContext?.Items["ProjectContext"] as string 
                             ?? throw new InvalidOperationException("No Project Context found.");

        // Grab the specific connection string for this PoC from Azure Key Vault or App Settings
        var connectionString = config.GetConnectionString(projectContext);
        
        var optionsBuilder = new DbContextOptionsBuilder<ApplicationDbContext>();
        optionsBuilder.UseSqlServer(connectionString);
        
        return new ApplicationDbContext(optionsBuilder.Options);
    }
}
```

#### 3. Service Bus Isolation
For the Service Bus, don't create separate Namespaces (too expensive). Use one Namespace and use **Topic Filters** or **Prefix-based Queue naming**.
*   PoC-A Queue: `poc-a-orders`
*   PoC-B Queue: `poc-b-emails`

### Part 3: Individual PoC Resource Groups

Your idea of separate RGs for the "Frontend" bits is excellent. It allows you to delete a PoC entirely (and all its specific assets) without touching your shared core.

**The "Per-PoC" Resource Group would contain:**
1.  **Azure Static Web Apps (SWA):** Use the **Free Tier**. It includes a free SSL certificate and allows custom domains. It's perfect for your SPA/Vanilla JS frontends.
2.  **Managed Identity:** Create a User-Assigned Managed Identity in the PoC RG and grant it specific "Contributor" or "Data Reader" roles to the Shared RG resources.
3.  **Application Insights:** I recommend a separate App Insights instance per PoC so your logs aren't a jumbled mess of 5 different apps.

### Part 4: Pragmatic Infrastructure as Code (Bicep)

Since you want to practice your skills, I strongly suggest using **Azure Bicep** to manage this.

*   **Core.bicep:** Deploys the SQL Server, Service Bus, and the Web App (API).
*   **Poc-Project.bicep:** Deploys a Static Web App and creates a new SQL Database on the *existing* server from the Core.

### Immediate Practical Advice

1.  **Azure SQL:** Use the **Serverless (vCore)** tier with "Auto-pause" enabled. If no one visits your PoCs for an hour, the database shuts down and you stop paying for compute entirely.
2.  **CORS:** In your shared API, you cannot just use `AllowAnyOrigin()` if you want to use credentials/auth. You will need a logic block in `Program.cs` that reads an array of allowed PoC domains from your configuration.
3.  **Authentication:** This is the trickiest part. Will all PoCs share the same user database? If not, you’ll want to use **Azure AD B2C** (free for the first 50k users) or a shared **IdentityServer** instance running on your API.

**How would you like to proceed?** I can provide a concrete implementation for the Multi-tenant `.NET 10` DbContext, or we can look at the `Bicep` templates to link the separate Resource Groups.
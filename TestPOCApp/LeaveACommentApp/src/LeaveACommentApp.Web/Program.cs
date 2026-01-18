var builder = WebApplication.CreateBuilder(args);

// Add service defaults (Aspire)
builder.AddServiceDefaults();

var app = builder.Build();

// Serve static files from wwwroot
app.UseDefaultFiles();
app.UseStaticFiles();

// Dynamic config endpoint for Aspire service discovery
app.MapGet("/config.js", (IConfiguration config) =>
{
    var apiUrl = config["services:api:https:0"] 
                 ?? config["services:api:http:0"] 
                 ?? "http://localhost:5001";
    return Results.Content(
        $"window.API_BASE_URL = '{apiUrl}/api/comments';",
        "application/javascript");
});

// Fallback to index.html for SPA routing
app.MapFallbackToFile("index.html");

app.Run();

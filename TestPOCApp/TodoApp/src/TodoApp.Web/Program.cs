var builder = WebApplication.CreateBuilder(args);

// Add Aspire service defaults
builder.AddServiceDefaults();

var app = builder.Build();

// Map Aspire default endpoints
app.MapDefaultEndpoints();

// Serve static files from wwwroot
app.UseStaticFiles();

// Inject API URL into the HTML for JavaScript to use
app.MapGet("/config.js", (IConfiguration config) =>
{
    // Get the API service URL from Aspire service discovery
    var apiUrl = config["services:api:https:0"] 
               ?? config["services:api:http:0"]
               ?? "http://localhost:5001";
    
    var js = $"window.API_BASE_URL = '{apiUrl}/api/todos';";
    return Results.Content(js, "application/javascript");
});

// Serve index.html for SPA fallback
app.MapFallbackToFile("index.html");

app.Run();

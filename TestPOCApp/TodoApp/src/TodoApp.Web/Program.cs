var builder = WebApplication.CreateBuilder(args);

// Add Aspire service defaults
builder.AddServiceDefaults();

var app = builder.Build();

// Map Aspire default endpoints
app.MapDefaultEndpoints();

// Serve static files from wwwroot
app.UseStaticFiles();

// Serve index.html for SPA fallback
app.MapFallbackToFile("index.html");

app.Run();

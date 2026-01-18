var builder = DistributedApplication.CreateBuilder(args);

// Add API project with reference to Web
var api = builder.AddProject<Projects.LeaveACommentApp_Api>("api");

// Add Web project with reference to API for service discovery
var web = builder.AddProject<Projects.LeaveACommentApp_Web>("web")
    .WithReference(api);

builder.Build().Run();

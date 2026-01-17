var builder = DistributedApplication.CreateBuilder(args);

// Add the API project with reference to the database connection
var api = builder.AddProject<Projects.TodoApp_Api>("api");

// Add the Web frontend project with reference to the API
var web = builder.AddProject<Projects.TodoApp_Web>("web")
    .WithReference(api)
    .WaitFor(api);

builder.Build().Run();

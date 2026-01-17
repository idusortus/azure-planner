using Microsoft.EntityFrameworkCore;
using TodoApp.Api.Data;
using TodoApp.Api.Models;

var builder = WebApplication.CreateBuilder(args);

// Add Aspire service defaults (health checks, logging, telemetry)
builder.AddServiceDefaults();

// Configure EF Core with SQL Server and retry logic for serverless
builder.Services.AddDbContext<TodoDbContext>(options =>
{
    var connectionString = builder.Configuration.GetConnectionString("TodoDb") 
        ?? throw new InvalidOperationException("Connection string 'TodoDb' not found.");
    
    options.UseSqlServer(connectionString, sqlOptions =>
    {
        // Enable retry logic for Azure SQL Serverless (which may need 30-60s to wake up)
        sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 5,
            maxRetryDelay: TimeSpan.FromSeconds(30),
            errorNumbersToAdd: null);
    });
});

// Add CORS for frontend
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Map Aspire default endpoints (health, etc.)
app.MapDefaultEndpoints();

// Use CORS
app.UseCors();

// API Routes for TODO items
var todoGroup = app.MapGroup("/api/todos");

// GET all todos
todoGroup.MapGet("/", async (TodoDbContext db) =>
{
    return await db.TodoItems
        .OrderByDescending(t => t.CreatedAt)
        .ToListAsync();
});

// GET single todo by id
todoGroup.MapGet("/{id:int}", async (int id, TodoDbContext db) =>
{
    return await db.TodoItems.FindAsync(id)
        is TodoItem todo
            ? Results.Ok(todo)
            : Results.NotFound();
});

// POST create new todo
todoGroup.MapPost("/", async (TodoItem todo, TodoDbContext db) =>
{
    todo.CreatedAt = DateTime.UtcNow;
    todo.IsComplete = false;
    
    db.TodoItems.Add(todo);
    await db.SaveChangesAsync();

    return Results.Created($"/api/todos/{todo.Id}", todo);
});

// PUT update todo
todoGroup.MapPut("/{id:int}", async (int id, TodoItem inputTodo, TodoDbContext db) =>
{
    var todo = await db.TodoItems.FindAsync(id);

    if (todo is null) return Results.NotFound();

    todo.Title = inputTodo.Title;
    todo.Description = inputTodo.Description;
    todo.IsComplete = inputTodo.IsComplete;
    
    if (inputTodo.IsComplete && todo.CompletedAt is null)
    {
        todo.CompletedAt = DateTime.UtcNow;
    }
    else if (!inputTodo.IsComplete)
    {
        todo.CompletedAt = null;
    }

    await db.SaveChangesAsync();

    return Results.NoContent();
});

// DELETE todo
todoGroup.MapDelete("/{id:int}", async (int id, TodoDbContext db) =>
{
    if (await db.TodoItems.FindAsync(id) is TodoItem todo)
    {
        db.TodoItems.Remove(todo);
        await db.SaveChangesAsync();
        return Results.NoContent();
    }

    return Results.NotFound();
});

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

app.Run();

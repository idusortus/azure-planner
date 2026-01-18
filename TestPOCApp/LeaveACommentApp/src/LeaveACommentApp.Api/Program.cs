using Microsoft.EntityFrameworkCore;
using LeaveACommentApp.Api.Data;
using LeaveACommentApp.Api.Models;

var builder = WebApplication.CreateBuilder(args);

// Add service defaults (Aspire)
builder.AddServiceDefaults();

// Add database context with retry logic for serverless SQL
var connectionString = builder.Configuration.GetConnectionString("CommentDb");
builder.Services.AddDbContext<CommentDbContext>(options =>
    options.UseSqlServer(connectionString, sqlOptions =>
        sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 5,
            maxRetryDelay: TimeSpan.FromSeconds(30),
            errorNumbersToAdd: null)));

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

// Add OpenAPI/Swagger
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure pipeline
app.UseCors();
app.MapOpenApi();

// Health endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
   .WithName("Health")
   .WithTags("Health");

// GET /api/comments - Get all comments (newest first)
app.MapGet("/api/comments", async (CommentDbContext db) =>
{
    var comments = await db.Comments
        .OrderByDescending(c => c.CreatedAt)
        .ToListAsync();
    return Results.Ok(comments);
})
.WithName("GetComments")
.WithTags("Comments");

// POST /api/comments - Create a new comment
app.MapPost("/api/comments", async (CommentDbContext db, CreateCommentRequest request) =>
{
    if (string.IsNullOrWhiteSpace(request.Username) || request.Username.Length > 50)
        return Results.BadRequest("Username must be 1-50 characters");
    
    if (string.IsNullOrWhiteSpace(request.Message) || request.Message.Length > 255)
        return Results.BadRequest("Message must be 1-255 characters");

    var comment = new Comment
    {
        Username = request.Username.Trim(),
        Message = request.Message.Trim(),
        CreatedAt = DateTime.UtcNow
    };

    db.Comments.Add(comment);
    await db.SaveChangesAsync();

    return Results.Created($"/api/comments/{comment.Id}", comment);
})
.WithName("CreateComment")
.WithTags("Comments");

// DELETE /api/comments/{id} - Delete a comment (by username check)
app.MapDelete("/api/comments/{id}", async (CommentDbContext db, int id, string username) =>
{
    var comment = await db.Comments.FindAsync(id);
    
    if (comment is null)
        return Results.NotFound();
    
    if (comment.Username != username)
        return Results.Forbid();

    db.Comments.Remove(comment);
    await db.SaveChangesAsync();

    return Results.NoContent();
})
.WithName("DeleteComment")
.WithTags("Comments");

app.Run();

// Request DTOs
public record CreateCommentRequest(string Username, string Message);

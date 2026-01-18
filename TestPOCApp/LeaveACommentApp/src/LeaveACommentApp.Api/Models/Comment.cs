namespace LeaveACommentApp.Api.Models;

public class Comment
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

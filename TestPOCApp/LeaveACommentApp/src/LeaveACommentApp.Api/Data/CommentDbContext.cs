using Microsoft.EntityFrameworkCore;
using LeaveACommentApp.Api.Models;

namespace LeaveACommentApp.Api.Data;

public class CommentDbContext : DbContext
{
    public CommentDbContext(DbContextOptions<CommentDbContext> options) : base(options)
    {
    }

    public DbSet<Comment> Comments => Set<Comment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Comment>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Username).HasMaxLength(50).IsRequired();
            entity.Property(e => e.Message).HasMaxLength(255).IsRequired();
            entity.Property(e => e.CreatedAt).IsRequired();
            
            // Index for efficient ordering by date
            entity.HasIndex(e => e.CreatedAt);
        });
    }
}

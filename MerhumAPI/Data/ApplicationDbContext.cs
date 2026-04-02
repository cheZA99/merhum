using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using MerhumAPI.Models;

namespace MerhumAPI.Data;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

    // Reference tables
    public DbSet<Country> Countries => Set<Country>();
    public DbSet<City> Cities => Set<City>();
    public DbSet<ServiceType> ServiceTypes => Set<ServiceType>();
    public DbSet<CemeterySection> CemeterySections => Set<CemeterySection>();

    // Functional tables
    public DbSet<ProcedureStatus> ProcedureStatuses => Set<ProcedureStatus>();
    public DbSet<Deceased> Deceased => Set<Deceased>();
    public DbSet<StatusHistory> StatusHistories => Set<StatusHistory>();
    public DbSet<Obituary> Obituaries => Set<Obituary>();
    public DbSet<Condolence> Condolences => Set<Condolence>();
    public DbSet<Mosque> Mosques => Set<Mosque>();
    public DbSet<Imam> Imams => Set<Imam>();
    public DbSet<Cemetery> Cemeteries => Set<Cemetery>();
    public DbSet<GraveSite> GraveSites => Set<GraveSite>();
    public DbSet<FuneralHome> FuneralHomes => Set<FuneralHome>();
    public DbSet<Appointment> Appointments => Set<Appointment>();
    public DbSet<ServiceOrder> ServiceOrders => Set<ServiceOrder>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Deceased
        builder.Entity<Deceased>(e =>
        {
            e.Property(x => x.CreatedAt).HasDefaultValueSql("GETDATE()");
        });

        // StatusHistory
        builder.Entity<StatusHistory>(e =>
        {
            e.Property(x => x.ChangedAt).HasDefaultValueSql("GETDATE()");
        });

        // Obituary — one-to-one with Deceased
        builder.Entity<Obituary>(e =>
        {
            e.HasIndex(x => x.DeceasedId).IsUnique();
            e.HasIndex(x => x.UniqueSlug).IsUnique();
            e.Property(x => x.ViewCount).HasDefaultValue(0);
            e.Property(x => x.IsPublic).HasDefaultValue(true);
            e.Property(x => x.IsActive).HasDefaultValue(true);
            e.Property(x => x.CreatedAt).HasDefaultValueSql("GETDATE()");
        });

        // Condolence
        builder.Entity<Condolence>(e =>
        {
            e.Property(x => x.IsApproved).HasDefaultValue(false);
            e.Property(x => x.CreatedAt).HasDefaultValueSql("GETDATE()");
        });

        // GraveSite
        builder.Entity<GraveSite>(e =>
        {
            e.Property(x => x.Status).HasDefaultValue("Available");
            // Avoid multiple cascade paths from Deceased
            e.HasOne(x => x.Deceased)
             .WithOne(x => x.GraveSite)
             .HasForeignKey<GraveSite>(x => x.DeceasedId)
             .OnDelete(DeleteBehavior.SetNull);
        });

        // Appointment — avoid multiple cascade paths
        builder.Entity<Appointment>(e =>
        {
            e.Property(x => x.Status).HasDefaultValue("Scheduled");
            e.Property(x => x.CreatedAt).HasDefaultValueSql("GETDATE()");

            e.HasOne(x => x.Deceased)
             .WithMany(x => x.Appointments)
             .HasForeignKey(x => x.DeceasedId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.Mosque)
             .WithMany(x => x.Appointments)
             .HasForeignKey(x => x.MosqueId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.Cemetery)
             .WithMany(x => x.Appointments)
             .HasForeignKey(x => x.CemeteryId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.Imam)
             .WithMany(x => x.Appointments)
             .HasForeignKey(x => x.ImamId)
             .OnDelete(DeleteBehavior.SetNull);

            e.HasOne(x => x.CreatedByUser)
             .WithMany()
             .HasForeignKey(x => x.CreatedByUserId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ServiceOrder
        builder.Entity<ServiceOrder>(e =>
        {
            e.Property(x => x.Status).HasDefaultValue("Ordered");
            e.Property(x => x.OrderedAt).HasDefaultValueSql("GETDATE()");
        });

        // Deceased — avoid cascade conflicts
        builder.Entity<Deceased>(e =>
        {
            e.HasOne(x => x.User)
             .WithMany()
             .HasForeignKey(x => x.UserId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.ProcedureStatus)
             .WithMany(x => x.Deceased)
             .HasForeignKey(x => x.ProcedureStatusId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // StatusHistory — avoid cascade conflicts
        builder.Entity<StatusHistory>(e =>
        {
            e.HasOne(x => x.ChangedByUser)
             .WithMany()
             .HasForeignKey(x => x.ChangedByUserId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // Obituary — avoid cascade on user
        builder.Entity<Obituary>(e =>
        {
            e.HasOne(x => x.CreatedByUser)
             .WithMany()
             .HasForeignKey(x => x.CreatedByUserId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // Condolence — optional user FK
        builder.Entity<Condolence>(e =>
        {
            e.HasOne(x => x.User)
             .WithMany()
             .HasForeignKey(x => x.UserId)
             .OnDelete(DeleteBehavior.SetNull);
        });
    }
}

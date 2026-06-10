using Microsoft.EntityFrameworkCore;
using Pharmacy.Domain;

namespace Pharmacy.Infrastructure;

public sealed class PharmacyDbContext(DbContextOptions<PharmacyDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Medicine> Medicines => Set<Medicine>();
    public DbSet<MedicineAlias> MedicineAliases => Set<MedicineAlias>();
    public DbSet<MedicineInteraction> MedicineInteractions => Set<MedicineInteraction>();
    public DbSet<Supplier> Suppliers => Set<Supplier>();
    public DbSet<MedicineBatch> MedicineBatches => Set<MedicineBatch>();
    public DbSet<InventoryItem> InventoryItems => Set<InventoryItem>();
    public DbSet<InventoryTransaction> InventoryTransactions => Set<InventoryTransaction>();
    public DbSet<ScanHistory> ScanHistories => Set<ScanHistory>();
    public DbSet<DispensingCheck> DispensingChecks => Set<DispensingCheck>();
    public DbSet<VerificationLog> VerificationLogs => Set<VerificationLog>();
    public DbSet<Alert> Alerts => Set<Alert>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>().HasIndex(x => x.Username).IsUnique();
        modelBuilder.Entity<Medicine>().Property(x => x.SalePrice).HasPrecision(18, 2);
        modelBuilder.Entity<Medicine>().HasIndex(x => x.Barcode).IsUnique();
        modelBuilder.Entity<MedicineBatch>().HasIndex(x => x.BatchNumber);
        modelBuilder.Entity<UserRole>().HasKey(x => new { x.UserId, x.RoleId });
        modelBuilder.Entity<InventoryItem>().HasIndex(x => x.MedicineBatchId).IsUnique();

        modelBuilder.Entity<MedicineInteraction>()
            .HasOne(x => x.MedicineA)
            .WithMany()
            .HasForeignKey(x => x.MedicineAId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<MedicineInteraction>()
            .HasOne(x => x.MedicineB)
            .WithMany()
            .HasForeignKey(x => x.MedicineBId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Role>().HasData(
            new Role { Id = 1, Name = UserRoleName.Admin },
            new Role { Id = 2, Name = UserRoleName.Staff });

        modelBuilder.Entity<User>().HasData(
            new User { Id = 1, FullName = "System Admin", Username = "admin", PasswordHash = PasswordHasher.Hash("admin123") },
            new User { Id = 2, FullName = "Nhan vien quay", Username = "staff", PasswordHash = PasswordHasher.Hash("staff123") });

        modelBuilder.Entity<UserRole>().HasData(
            new { UserId = 1, RoleId = 1 },
            new { UserId = 2, RoleId = 2 });

        modelBuilder.Entity<Supplier>().HasData(
            new Supplier { Id = 1, Name = "Demo Pharma Distributor", Phone = "0900000001", Address = "Ho Chi Minh City" });

        modelBuilder.Entity<Medicine>().HasData(
            new Medicine
            {
                Id = 1,
                Name = "Paracetamol 500mg",
                Barcode = "8938505974190",
                ActiveIngredient = "Paracetamol",
                Manufacturer = "Demo Pharma",
                DosageForm = "Tablet",
                Strength = "500mg",
                UsageInstruction = "Dung theo huong dan cua duoc si hoac bac si.",
                WarningNote = "Than trong voi benh gan va qua lieu.",
                SalePrice = 25000,
                RequiresPrescription = false
            },
            new Medicine
            {
                Id = 2,
                Name = "Ibuprofen 200mg",
                Barcode = "8938505974206",
                ActiveIngredient = "Ibuprofen",
                Manufacturer = "Demo Pharma",
                DosageForm = "Tablet",
                Strength = "200mg",
                UsageInstruction = "Dung sau an, tranh dung khi co tien su loet da day.",
                WarningNote = "Than trong voi benh da day, than va dung cung thuoc chong dong.",
                SalePrice = 30000,
                RequiresPrescription = false
            },
            new Medicine
            {
                Id = 3,
                Name = "Amoxicillin 500mg",
                Barcode = "8938505974213",
                ActiveIngredient = "Amoxicillin",
                Manufacturer = "Demo Antibiotics",
                DosageForm = "Capsule",
                Strength = "500mg",
                UsageInstruction = "Dung dung lieu va du lieu trinh.",
                WarningNote = "Can hoi tien su di ung khang sinh beta-lactam.",
                SalePrice = 45000,
                RequiresPrescription = true
            });

        modelBuilder.Entity<MedicineAlias>().HasData(
            new MedicineAlias { Id = 1, MedicineId = 1, Alias = "Acetaminophen" },
            new MedicineAlias { Id = 2, MedicineId = 3, Alias = "Amox" });

        modelBuilder.Entity<MedicineInteraction>().HasData(
            new MedicineInteraction
            {
                Id = 1,
                MedicineAId = 1,
                MedicineBId = 2,
                Severity = AlertSeverity.Warning,
                Description = "Can kiem tra tong lieu giam dau/ha sot va nguy co tac dung phu khi phoi hop."
            });

        modelBuilder.Entity<MedicineBatch>().HasData(
            new MedicineBatch { Id = 1, MedicineId = 1, SupplierId = 1, BatchNumber = "PCM-2026-01", ManufactureDate = new DateOnly(2025, 1, 1), ExpiryDate = new DateOnly(2027, 1, 1), InitialQuantity = 100 },
            new MedicineBatch { Id = 2, MedicineId = 2, SupplierId = 1, BatchNumber = "IBU-2025-12", ManufactureDate = new DateOnly(2024, 12, 1), ExpiryDate = new DateOnly(2026, 8, 1), InitialQuantity = 8 },
            new MedicineBatch { Id = 3, MedicineId = 3, SupplierId = 1, BatchNumber = "AMX-2025-02", ManufactureDate = new DateOnly(2025, 2, 1), ExpiryDate = new DateOnly(2026, 7, 1), InitialQuantity = 40 });

        modelBuilder.Entity<InventoryItem>().HasData(
            new InventoryItem { Id = 1, MedicineBatchId = 1, Quantity = 100, LowStockThreshold = 10 },
            new InventoryItem { Id = 2, MedicineBatchId = 2, Quantity = 8, LowStockThreshold = 10 },
            new InventoryItem { Id = 3, MedicineBatchId = 3, Quantity = 40, LowStockThreshold = 10 });
    }
}

namespace Pharmacy.Domain;

public enum UserRoleName { Admin, Staff }
public enum AlertType { Expired, NearExpiry, LowStock, DispensingError, VerificationWarning }
public enum AlertSeverity { Info, Warning, Critical }
public enum InventoryTransactionType { Import, Export, Sale, Adjustment }
public enum DispensingCheckStatus { Safe, Warning, Blocked }

public abstract class Entity
{
    public int Id { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}

public sealed class User : Entity
{
    public string FullName { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public List<UserRole> UserRoles { get; set; } = [];
}

public sealed class Role : Entity
{
    public UserRoleName Name { get; set; }
    public List<UserRole> UserRoles { get; set; } = [];
}

public sealed class UserRole
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public int RoleId { get; set; }
    public Role Role { get; set; } = null!;
}

public sealed class Medicine : Entity
{
    public string Name { get; set; } = string.Empty;
    public string Barcode { get; set; } = string.Empty;
    public string ActiveIngredient { get; set; } = string.Empty;
    public string Manufacturer { get; set; } = string.Empty;
    public string DosageForm { get; set; } = string.Empty;
    public string Strength { get; set; } = string.Empty;
    public string UsageInstruction { get; set; } = string.Empty;
    public string WarningNote { get; set; } = string.Empty;
    public bool RequiresPrescription { get; set; }
    public List<MedicineAlias> Aliases { get; set; } = [];
    public List<MedicineBatch> Batches { get; set; } = [];
}

public sealed class MedicineAlias : Entity
{
    public int MedicineId { get; set; }
    public Medicine Medicine { get; set; } = null!;
    public string Alias { get; set; } = string.Empty;
}

public sealed class MedicineInteraction : Entity
{
    public int MedicineAId { get; set; }
    public Medicine MedicineA { get; set; } = null!;
    public int MedicineBId { get; set; }
    public Medicine MedicineB { get; set; } = null!;
    public AlertSeverity Severity { get; set; }
    public string Description { get; set; } = string.Empty;
}

public sealed class Supplier : Entity
{
    public string Name { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
}

public sealed class MedicineBatch : Entity
{
    public int MedicineId { get; set; }
    public Medicine Medicine { get; set; } = null!;
    public int? SupplierId { get; set; }
    public Supplier? Supplier { get; set; }
    public string BatchNumber { get; set; } = string.Empty;
    public DateOnly ManufactureDate { get; set; }
    public DateOnly ExpiryDate { get; set; }
    public int InitialQuantity { get; set; }
    public InventoryItem? InventoryItem { get; set; }
}

public sealed class InventoryItem : Entity
{
    public int MedicineBatchId { get; set; }
    public MedicineBatch MedicineBatch { get; set; } = null!;
    public int Quantity { get; set; }
    public int LowStockThreshold { get; set; } = 10;
}

public sealed class InventoryTransaction : Entity
{
    public int MedicineBatchId { get; set; }
    public MedicineBatch MedicineBatch { get; set; } = null!;
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public InventoryTransactionType Type { get; set; }
    public int Quantity { get; set; }
    public string Note { get; set; } = string.Empty;
}

public sealed class ScanHistory : Entity
{
    public int? MedicineId { get; set; }
    public Medicine? Medicine { get; set; }
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public string Barcode { get; set; } = string.Empty;
    public bool Found { get; set; }
}

public sealed class DispensingCheck : Entity
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public DispensingCheckStatus Status { get; set; }
    public string Message { get; set; } = string.Empty;
    public string Barcodes { get; set; } = string.Empty;
}

public sealed class VerificationLog : Entity
{
    public int? MedicineId { get; set; }
    public Medicine? Medicine { get; set; }
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public string Barcode { get; set; } = string.Empty;
    public string BatchNumber { get; set; } = string.Empty;
    public bool IsVerified { get; set; }
    public string Message { get; set; } = string.Empty;
}

public sealed class Alert : Entity
{
    public int? MedicineId { get; set; }
    public Medicine? Medicine { get; set; }
    public int? MedicineBatchId { get; set; }
    public MedicineBatch? MedicineBatch { get; set; }
    public AlertType Type { get; set; }
    public AlertSeverity Severity { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool IsResolved { get; set; }
}

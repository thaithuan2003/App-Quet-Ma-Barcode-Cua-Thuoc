using Pharmacy.Domain;

namespace Pharmacy.Application;

public sealed record LoginRequest(string Username, string Password);
public sealed record LoginResponse(string Token, string FullName, string Username, IReadOnlyList<string> Roles);

public sealed record MedicineDto(
    int Id,
    string Name,
    string Barcode,
    string ActiveIngredient,
    string Manufacturer,
    string DosageForm,
    string Strength,
    string UsageInstruction,
    string WarningNote,
    decimal SalePrice,
    bool RequiresPrescription,
    int TotalQuantity,
    DateOnly? NearestExpiryDate);

public sealed record UpsertMedicineRequest(
    string Name,
    string Barcode,
    string ActiveIngredient,
    string Manufacturer,
    string DosageForm,
    string Strength,
    string UsageInstruction,
    string WarningNote,
    decimal SalePrice,
    bool RequiresPrescription);

public sealed record BatchDto(
    int Id,
    int MedicineId,
    string MedicineName,
    string BatchNumber,
    DateOnly ManufactureDate,
    DateOnly ExpiryDate,
    int Quantity,
    int LowStockThreshold,
    int? SupplierId,
    string? SupplierName);

public sealed record InventoryTransactionDto(
    int Id,
    string MedicineName,
    string BatchNumber,
    InventoryTransactionType Type,
    int Quantity,
    string Note,
    DateTime CreatedAt);

public sealed record InventoryChangeRequest(int MedicineBatchId, int Quantity, string Note);
public sealed record InventoryAdjustmentRequest(int MedicineBatchId, int NewQuantity, string Note);

public sealed record CreateBatchRequest(
    int MedicineId,
    int? SupplierId,
    string BatchNumber,
    DateOnly ManufactureDate,
    DateOnly ExpiryDate,
    int Quantity,
    int LowStockThreshold);

public sealed record UpdateBatchRequest(
    int MedicineId,
    int? SupplierId,
    string BatchNumber,
    DateOnly ManufactureDate,
    DateOnly ExpiryDate,
    int Quantity,
    int LowStockThreshold);

public sealed record ScanRequest(string Barcode);
public sealed record ScanResponse(bool Found, string Message, string Barcode, DateTime CreatedAt, MedicineDto? Medicine);
public sealed record MultiScanRequest(IReadOnlyList<string> Barcodes);

public sealed record InteractionResultDto(AlertSeverity Severity, string Message, IReadOnlyList<string> Details);
public sealed record VerificationRequest(string Barcode, string BatchNumber);
public sealed record VerificationResponse(bool IsVerified, AlertSeverity Severity, string Message);

public sealed record AlertDto(
    int Id,
    AlertType Type,
    AlertSeverity Severity,
    string Title,
    string Message,
    bool IsResolved,
    DateTime CreatedAt);

public sealed record ReportDto(
    int MedicineCount,
    int BatchCount,
    int TotalInventoryQuantity,
    int LowStockCount,
    int ExpiredBatchCount,
    int NearExpiryBatchCount,
    int TodayScanCount,
    int TodaySaleQuantity);

public sealed record ScanReportDto(
    int Id,
    string Barcode,
    bool Found,
    string? MedicineName,
    DateTime CreatedAt);

public sealed record SupplierDto(int Id, string Name, string Phone, string Address);
public sealed record UpsertSupplierRequest(string Name, string Phone, string Address);

public sealed record MedicineConsultationRequest(string MedicineName);
public sealed record MedicineConsultationResponse(
    string MedicineName,
    string Summary,
    string SourceTitle,
    string SourceUrl,
    string SourceSnippet);

public sealed record UserDto(int Id, string FullName, string Username, bool IsActive, IReadOnlyList<string> Roles);
public sealed record CreateStaffRequest(string FullName, string Username, string Password);
public sealed record UpdateStaffRequest(string FullName, string Username, string? Password);
public sealed record UpdateUserStatusRequest(bool IsActive);

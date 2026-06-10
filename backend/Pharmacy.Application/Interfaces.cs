namespace Pharmacy.Application;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken);
}

public interface ITokenProvider
{
    string CreateToken(int userId, string username, string fullName, IReadOnlyList<string> roles);
}

public interface IMedicineService
{
    Task<MedicineDto?> GetByBarcodeAsync(string barcode, CancellationToken cancellationToken);
    Task<IReadOnlyList<MedicineDto>> SearchAsync(string query, CancellationToken cancellationToken);
    Task<IReadOnlyList<MedicineDto>> GetSimilarAsync(int medicineId, CancellationToken cancellationToken);
    Task<InteractionResultDto> CheckInteractionsAsync(IReadOnlyList<string> barcodes, CancellationToken cancellationToken);
}

public interface IInventoryService
{
    Task<IReadOnlyList<BatchDto>> GetBatchesAsync(CancellationToken cancellationToken);
    Task<BatchDto> CreateBatchAsync(CreateBatchRequest request, int userId, CancellationToken cancellationToken);
    Task<InventoryTransactionDto> ImportAsync(InventoryChangeRequest request, int userId, CancellationToken cancellationToken);
    Task<InventoryTransactionDto> ExportAsync(InventoryChangeRequest request, int userId, CancellationToken cancellationToken);
    Task<InventoryTransactionDto> AdjustAsync(InventoryAdjustmentRequest request, int userId, CancellationToken cancellationToken);
    Task<IReadOnlyList<InventoryTransactionDto>> GetTransactionsAsync(CancellationToken cancellationToken);
}

public interface IScanService
{
    Task<ScanResponse> ScanAsync(ScanRequest request, int userId, CancellationToken cancellationToken);
    Task<IReadOnlyList<ScanResponse>> MultiScanAsync(MultiScanRequest request, int userId, CancellationToken cancellationToken);
    Task<IReadOnlyList<ScanResponse>> GetHistoryAsync(int userId, CancellationToken cancellationToken);
}

public interface IAlertService
{
    Task<IReadOnlyList<AlertDto>> GetAlertsAsync(CancellationToken cancellationToken);
    Task RefreshSystemAlertsAsync(CancellationToken cancellationToken);
}

public interface IVerificationService
{
    Task<VerificationResponse> VerifyAsync(VerificationRequest request, int userId, CancellationToken cancellationToken);
}

public interface IReportService
{
    Task<ReportDto> GetSummaryAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<MedicineDto>> GetMedicineInventoryAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<BatchDto>> GetBatchesAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<BatchDto>> GetNearExpiryBatchesAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<BatchDto>> GetExpiredBatchesAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<ScanReportDto>> GetTodayScansAsync(CancellationToken cancellationToken);
}

public interface IAdminService
{
    Task<IReadOnlyList<UserDto>> GetUsersAsync(CancellationToken cancellationToken);
    Task<UserDto> CreateStaffAsync(CreateStaffRequest request, CancellationToken cancellationToken);
    Task<UserDto> UpdateStaffAsync(int userId, UpdateStaffRequest request, CancellationToken cancellationToken);
    Task<UserDto> UpdateUserStatusAsync(int userId, UpdateUserStatusRequest request, CancellationToken cancellationToken);
    Task DeleteStaffAsync(int userId, CancellationToken cancellationToken);
}

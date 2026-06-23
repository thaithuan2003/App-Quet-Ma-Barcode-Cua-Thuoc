using Microsoft.EntityFrameworkCore;
using Pharmacy.Application;
using Pharmacy.Domain;

namespace Pharmacy.Infrastructure;

public sealed class VerificationService(PharmacyDbContext db) : IVerificationService
{
    public async Task<VerificationResponse> VerifyAsync(VerificationRequest request, int userId, CancellationToken cancellationToken)
    {
        var batch = await db.MedicineBatches
            .Include(x => x.Medicine)
            .FirstOrDefaultAsync(x => x.Medicine.Barcode == request.Barcode && x.BatchNumber == request.BatchNumber, cancellationToken);

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var verified = batch is not null && batch.ExpiryDate >= today;
        var message = batch is null
            ? "Không tìm thấy mã vạch/số lô trong CSDL. Cần kiểm tra nguồn hàng."
            : batch.ExpiryDate < today
                ? "Tìm thấy lô thuốc nhưng đã hết hạn."
                : "Mã vạch và số lô khớp với dữ liệu nội bộ.";

        db.VerificationLogs.Add(new VerificationLog
        {
            MedicineId = batch?.MedicineId,
            UserId = userId,
            Barcode = request.Barcode,
            BatchNumber = request.BatchNumber,
            IsVerified = verified,
            Message = message
        });

        if (!verified)
        {
            db.Alerts.Add(new Alert
            {
                MedicineId = batch?.MedicineId,
                MedicineBatchId = batch?.Id,
                Type = AlertType.VerificationWarning,
                Severity = AlertSeverity.Warning,
                Title = "Cảnh báo xác thực",
                Message = message
            });
        }

        await db.SaveChangesAsync(cancellationToken);
        return new VerificationResponse(verified, verified ? AlertSeverity.Info : AlertSeverity.Warning, message);
    }
}

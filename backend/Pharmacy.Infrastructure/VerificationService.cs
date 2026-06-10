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
            ? "Khong tim thay ma vach/so lo trong CSDL. Can kiem tra nguon hang."
            : batch.ExpiryDate < today
                ? "Tim thay lo thuoc nhung da het han."
                : "Ma vach va so lo khop voi du lieu noi bo.";

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
                Title = "Canh bao xac thuc",
                Message = message
            });
        }

        await db.SaveChangesAsync(cancellationToken);
        return new VerificationResponse(verified, verified ? AlertSeverity.Info : AlertSeverity.Warning, message);
    }
}

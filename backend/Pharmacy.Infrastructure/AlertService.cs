using Microsoft.EntityFrameworkCore;
using Pharmacy.Application;
using Pharmacy.Domain;

namespace Pharmacy.Infrastructure;

public sealed class AlertService(PharmacyDbContext db) : IAlertService
{
    public async Task<IReadOnlyList<AlertDto>> GetAlertsAsync(CancellationToken cancellationToken)
    {
        await RefreshSystemAlertsAsync(cancellationToken);
        return await db.Alerts
            .Where(x => !x.IsResolved)
            .OrderByDescending(x => x.Severity)
            .ThenByDescending(x => x.CreatedAt)
            .Select(x => new AlertDto(x.Id, x.Type, x.Severity, x.Title, x.Message, x.IsResolved, x.CreatedAt))
            .ToListAsync(cancellationToken);
    }

    public async Task RefreshSystemAlertsAsync(CancellationToken cancellationToken)
    {
        var systemTypes = new[] { AlertType.Expired, AlertType.NearExpiry, AlertType.LowStock };
        var oldAlerts = await db.Alerts.Where(x => systemTypes.Contains(x.Type)).ToListAsync(cancellationToken);
        db.Alerts.RemoveRange(oldAlerts);

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var nearExpiryLimit = today.AddDays(90);
        var batches = await db.MedicineBatches
            .Include(x => x.Medicine)
            .Include(x => x.InventoryItem)
            .ToListAsync(cancellationToken);

        foreach (var batch in batches)
        {
            var quantity = batch.InventoryItem?.Quantity ?? 0;
            if (quantity <= 0)
            {
                continue;
            }

            if (batch.ExpiryDate < today)
            {
                AddAlert(batch, AlertType.Expired, AlertSeverity.Critical, "Thuoc da het han", $"{batch.Medicine.Name} lo {batch.BatchNumber} da het han.");
            }
            else if (batch.ExpiryDate <= nearExpiryLimit)
            {
                AddAlert(batch, AlertType.NearExpiry, AlertSeverity.Warning, "Thuoc sap het han", $"{batch.Medicine.Name} lo {batch.BatchNumber} het han ngay {batch.ExpiryDate:yyyy-MM-dd}.");
            }

            if (batch.InventoryItem is not null && quantity <= batch.InventoryItem.LowStockThreshold)
            {
                AddAlert(batch, AlertType.LowStock, AlertSeverity.Warning, "Ton kho thap", $"{batch.Medicine.Name} lo {batch.BatchNumber} chi con {quantity}.");
            }
        }

        await db.SaveChangesAsync(cancellationToken);
    }

    private void AddAlert(MedicineBatch batch, AlertType type, AlertSeverity severity, string title, string message)
    {
        db.Alerts.Add(new Alert
        {
            MedicineId = batch.MedicineId,
            MedicineBatchId = batch.Id,
            Type = type,
            Severity = severity,
            Title = title,
            Message = message
        });
    }
}

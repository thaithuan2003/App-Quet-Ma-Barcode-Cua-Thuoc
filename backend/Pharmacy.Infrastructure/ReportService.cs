using Microsoft.EntityFrameworkCore;
using Pharmacy.Application;
using Pharmacy.Domain;

namespace Pharmacy.Infrastructure;

public sealed class ReportService(PharmacyDbContext db, IAlertService alerts) : IReportService
{
    public async Task<ReportDto> GetSummaryAsync(CancellationToken cancellationToken)
    {
        await alerts.RefreshSystemAlertsAsync(cancellationToken);
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var tomorrow = DateTime.UtcNow.Date.AddDays(1);
        var todayStart = DateTime.UtcNow.Date;

        return new ReportDto(
            await db.Medicines.CountAsync(cancellationToken),
            await db.MedicineBatches.CountAsync(cancellationToken),
            await db.InventoryItems.SumAsync(x => x.Quantity, cancellationToken),
            await db.InventoryItems.CountAsync(x => x.Quantity <= x.LowStockThreshold, cancellationToken),
            await db.MedicineBatches.CountAsync(x => x.ExpiryDate < today, cancellationToken),
            await db.MedicineBatches.CountAsync(x => x.ExpiryDate >= today && x.ExpiryDate <= today.AddDays(90), cancellationToken),
            await db.ScanHistories.CountAsync(x => x.CreatedAt >= todayStart && x.CreatedAt < tomorrow, cancellationToken),
            await db.InventoryTransactions
                .Where(x => x.Type == InventoryTransactionType.Sale && x.CreatedAt >= todayStart && x.CreatedAt < tomorrow)
                .SumAsync(x => (int?)x.Quantity, cancellationToken) ?? 0);
    }
}

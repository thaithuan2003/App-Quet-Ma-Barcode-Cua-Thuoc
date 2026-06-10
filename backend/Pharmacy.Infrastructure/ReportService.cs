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

    public async Task<IReadOnlyList<MedicineDto>> GetMedicineInventoryAsync(CancellationToken cancellationToken)
    {
        var medicines = await db.Medicines.OrderBy(x => x.Name).ToListAsync(cancellationToken);
        var result = new List<MedicineDto>();
        foreach (var medicine in medicines)
        {
            result.Add(await medicine.ToDtoAsync(db, cancellationToken));
        }

        return result;
    }

    public async Task<IReadOnlyList<BatchDto>> GetBatchesAsync(CancellationToken cancellationToken)
    {
        var batches = await BaseBatchQuery()
            .OrderBy(x => x.Medicine.Name)
            .ThenBy(x => x.ExpiryDate)
            .ToListAsync(cancellationToken);

        return batches.Select(x => x.ToDto()).ToList();
    }

    public async Task<IReadOnlyList<BatchDto>> GetNearExpiryBatchesAsync(CancellationToken cancellationToken)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var batches = await BaseBatchQuery()
            .Where(x => x.ExpiryDate >= today && x.ExpiryDate <= today.AddDays(90))
            .OrderBy(x => x.ExpiryDate)
            .ToListAsync(cancellationToken);

        return batches.Select(x => x.ToDto()).ToList();
    }

    public async Task<IReadOnlyList<BatchDto>> GetExpiredBatchesAsync(CancellationToken cancellationToken)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var batches = await BaseBatchQuery()
            .Where(x => x.ExpiryDate < today)
            .OrderBy(x => x.ExpiryDate)
            .ToListAsync(cancellationToken);

        return batches.Select(x => x.ToDto()).ToList();
    }

    public async Task<IReadOnlyList<ScanReportDto>> GetTodayScansAsync(CancellationToken cancellationToken)
    {
        var todayStart = DateTime.UtcNow.Date;
        var tomorrow = todayStart.AddDays(1);

        return await db.ScanHistories
            .Include(x => x.Medicine)
            .Where(x => x.CreatedAt >= todayStart && x.CreatedAt < tomorrow)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new ScanReportDto(
                x.Id,
                x.Barcode,
                x.Found,
                x.Medicine == null ? null : x.Medicine.Name,
                x.CreatedAt))
            .ToListAsync(cancellationToken);
    }

    private IQueryable<MedicineBatch> BaseBatchQuery()
    {
        return db.MedicineBatches
            .Include(x => x.Medicine)
            .Include(x => x.Supplier)
            .Include(x => x.InventoryItem);
    }
}

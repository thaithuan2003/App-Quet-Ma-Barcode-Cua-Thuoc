using Microsoft.EntityFrameworkCore;
using Pharmacy.Application;
using Pharmacy.Domain;

namespace Pharmacy.Infrastructure;

public sealed class InventoryService(PharmacyDbContext db, IAlertService alerts) : IInventoryService
{
    public async Task<IReadOnlyList<BatchDto>> GetBatchesAsync(CancellationToken cancellationToken)
    {
        var batches = await db.MedicineBatches
            .Include(x => x.Medicine)
            .Include(x => x.Supplier)
            .Include(x => x.InventoryItem)
            .OrderBy(x => x.ExpiryDate)
            .ToListAsync(cancellationToken);

        return batches.Select(x => x.ToDto()).ToList();
    }

    public async Task<BatchDto> CreateBatchAsync(CreateBatchRequest request, int userId, CancellationToken cancellationToken)
    {
        var batch = new MedicineBatch
        {
            MedicineId = request.MedicineId,
            SupplierId = request.SupplierId,
            BatchNumber = request.BatchNumber.Trim(),
            ManufactureDate = request.ManufactureDate,
            ExpiryDate = request.ExpiryDate,
            InitialQuantity = request.Quantity,
            InventoryItem = new InventoryItem
            {
                Quantity = request.Quantity,
                LowStockThreshold = request.LowStockThreshold
            }
        };

        db.MedicineBatches.Add(batch);
        db.InventoryTransactions.Add(new InventoryTransaction
        {
            MedicineBatch = batch,
            UserId = userId,
            Type = InventoryTransactionType.Import,
            Quantity = request.Quantity,
            Note = "Nhap lo moi"
        });
        await db.SaveChangesAsync(cancellationToken);
        await alerts.RefreshSystemAlertsAsync(cancellationToken);

        return (await db.MedicineBatches
            .Include(x => x.Medicine)
            .Include(x => x.Supplier)
            .Include(x => x.InventoryItem)
            .FirstAsync(x => x.Id == batch.Id, cancellationToken)).ToDto();
    }

    public Task<InventoryTransactionDto> ImportAsync(InventoryChangeRequest request, int userId, CancellationToken cancellationToken)
    {
        return ChangeQuantityAsync(request.MedicineBatchId, request.Quantity, InventoryTransactionType.Import, request.Note, userId, cancellationToken);
    }

    public Task<InventoryTransactionDto> ExportAsync(InventoryChangeRequest request, int userId, CancellationToken cancellationToken)
    {
        return ChangeQuantityAsync(request.MedicineBatchId, -request.Quantity, InventoryTransactionType.Sale, request.Note, userId, cancellationToken);
    }

    public async Task<InventoryTransactionDto> AdjustAsync(InventoryAdjustmentRequest request, int userId, CancellationToken cancellationToken)
    {
        var item = await db.InventoryItems.FirstOrDefaultAsync(x => x.MedicineBatchId == request.MedicineBatchId, cancellationToken)
            ?? throw new InvalidOperationException("Khong tim thay lo ton kho.");
        var delta = request.NewQuantity - item.Quantity;
        return await ChangeQuantityAsync(request.MedicineBatchId, delta, InventoryTransactionType.Adjustment, request.Note, userId, cancellationToken);
    }

    public async Task<IReadOnlyList<InventoryTransactionDto>> GetTransactionsAsync(CancellationToken cancellationToken)
    {
        var transactions = await db.InventoryTransactions
            .Include(x => x.MedicineBatch).ThenInclude(x => x.Medicine)
            .OrderByDescending(x => x.CreatedAt)
            .Take(100)
            .ToListAsync(cancellationToken);

        return transactions.Select(x => x.ToDto()).ToList();
    }

    private async Task<InventoryTransactionDto> ChangeQuantityAsync(
        int batchId,
        int delta,
        InventoryTransactionType type,
        string note,
        int userId,
        CancellationToken cancellationToken)
    {
        var item = await db.InventoryItems
            .Include(x => x.MedicineBatch).ThenInclude(x => x.Medicine)
            .FirstOrDefaultAsync(x => x.MedicineBatchId == batchId, cancellationToken)
            ?? throw new InvalidOperationException("Khong tim thay lo ton kho.");

        if (item.Quantity + delta < 0)
        {
            throw new InvalidOperationException("So luong ton kho khong du.");
        }

        item.Quantity += delta;
        var transaction = new InventoryTransaction
        {
            MedicineBatchId = batchId,
            UserId = userId,
            Type = type,
            Quantity = Math.Abs(delta),
            Note = note.Trim()
        };
        db.InventoryTransactions.Add(transaction);
        await db.SaveChangesAsync(cancellationToken);
        await alerts.RefreshSystemAlertsAsync(cancellationToken);

        return (await db.InventoryTransactions
            .Include(x => x.MedicineBatch).ThenInclude(x => x.Medicine)
            .FirstAsync(x => x.Id == transaction.Id, cancellationToken)).ToDto();
    }
}

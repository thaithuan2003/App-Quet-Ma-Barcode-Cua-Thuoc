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
        if (request.Quantity < 0)
        {
            throw new InvalidOperationException("Số lượng lô thuốc không hợp lệ.");
        }
        if (string.IsNullOrWhiteSpace(request.BatchNumber))
        {
            throw new InvalidOperationException("Số lô không được để trống.");
        }
        if (!await db.Medicines.AnyAsync(x => x.Id == request.MedicineId, cancellationToken))
        {
            throw new InvalidOperationException("Không tìm thấy thuốc để tạo lô.");
        }
        if (request.SupplierId is null || !await db.Suppliers.AnyAsync(x => x.Id == request.SupplierId, cancellationToken))
        {
            throw new InvalidOperationException("Vui lòng chọn nhà cung ứng hợp lệ.");
        }
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

    public async Task<BatchDto> UpdateBatchAsync(int batchId, UpdateBatchRequest request, int userId, CancellationToken cancellationToken)
    {
        var batch = await db.MedicineBatches
            .Include(x => x.Medicine)
            .Include(x => x.Supplier)
            .Include(x => x.InventoryItem)
            .FirstOrDefaultAsync(x => x.Id == batchId, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy lô thuốc.");

        if (request.Quantity < 0)
        {
            throw new InvalidOperationException("Số lượng tồn không hợp lệ.");
        }
        if (string.IsNullOrWhiteSpace(request.BatchNumber))
        {
            throw new InvalidOperationException("Số lô không được để trống.");
        }
        if (!await db.Medicines.AnyAsync(x => x.Id == request.MedicineId, cancellationToken))
        {
            throw new InvalidOperationException("Không tìm thấy thuốc để cập nhật lô.");
        }
        if (request.SupplierId is null || !await db.Suppliers.AnyAsync(x => x.Id == request.SupplierId, cancellationToken))
        {
            throw new InvalidOperationException("Vui lòng chọn nhà cung ứng hợp lệ.");
        }

        batch.MedicineId = request.MedicineId;
        batch.SupplierId = request.SupplierId;
        batch.BatchNumber = request.BatchNumber.Trim();
        batch.ManufactureDate = request.ManufactureDate;
        batch.ExpiryDate = request.ExpiryDate;
        batch.UpdatedAt = DateTime.UtcNow;
        if (batch.InventoryItem is null)
        {
            batch.InventoryItem = new InventoryItem { Quantity = request.Quantity, LowStockThreshold = request.LowStockThreshold };
        }
        else
        {
            batch.InventoryItem.Quantity = request.Quantity;
            batch.InventoryItem.LowStockThreshold = request.LowStockThreshold;
            batch.InventoryItem.UpdatedAt = DateTime.UtcNow;
        }

        db.InventoryTransactions.Add(new InventoryTransaction
        {
            MedicineBatchId = batch.Id,
            UserId = userId,
            Type = InventoryTransactionType.Adjustment,
            Quantity = request.Quantity,
            Note = "Cập nhật lô thuốc"
        });
        await db.SaveChangesAsync(cancellationToken);
        await alerts.RefreshSystemAlertsAsync(cancellationToken);
        return (await db.MedicineBatches
            .Include(x => x.Medicine)
            .Include(x => x.Supplier)
            .Include(x => x.InventoryItem)
            .FirstAsync(x => x.Id == batchId, cancellationToken)).ToDto();
    }

    public async Task DeleteBatchAsync(int batchId, CancellationToken cancellationToken)
    {
        var batch = await db.MedicineBatches
            .Include(x => x.InventoryItem)
            .FirstOrDefaultAsync(x => x.Id == batchId, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy lô thuốc.");

        var transactions = await db.InventoryTransactions.Where(x => x.MedicineBatchId == batchId).ToListAsync(cancellationToken);
        var alertsForBatch = await db.Alerts.Where(x => x.MedicineBatchId == batchId).ToListAsync(cancellationToken);
        db.InventoryTransactions.RemoveRange(transactions);
        db.Alerts.RemoveRange(alertsForBatch);
        if (batch.InventoryItem is not null)
        {
            db.InventoryItems.Remove(batch.InventoryItem);
        }
        db.MedicineBatches.Remove(batch);
        await db.SaveChangesAsync(cancellationToken);
        await alerts.RefreshSystemAlertsAsync(cancellationToken);
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

using Microsoft.EntityFrameworkCore;
using Pharmacy.Application;
using Pharmacy.Domain;

namespace Pharmacy.Infrastructure;

internal static class MappingExtensions
{
    public static async Task<MedicineDto> ToDtoAsync(this Medicine medicine, PharmacyDbContext db, CancellationToken cancellationToken)
    {
        var batches = await db.MedicineBatches
            .Include(x => x.InventoryItem)
            .Where(x => x.MedicineId == medicine.Id)
            .ToListAsync(cancellationToken);

        return new MedicineDto(
            medicine.Id,
            medicine.Name,
            medicine.Barcode,
            medicine.ActiveIngredient,
            medicine.Manufacturer,
            medicine.DosageForm,
            medicine.Strength,
            medicine.UsageInstruction,
            medicine.WarningNote,
            medicine.SalePrice,
            medicine.RequiresPrescription,
            batches.Sum(x => x.InventoryItem?.Quantity ?? 0),
            batches.Where(x => (x.InventoryItem?.Quantity ?? 0) > 0).Select(x => (DateOnly?)x.ExpiryDate).OrderBy(x => x).FirstOrDefault());
    }

    public static BatchDto ToDto(this MedicineBatch batch)
    {
        return new BatchDto(
            batch.Id,
            batch.MedicineId,
            batch.Medicine.Name,
            batch.BatchNumber,
            batch.ManufactureDate,
            batch.ExpiryDate,
            batch.InventoryItem?.Quantity ?? 0,
            batch.InventoryItem?.LowStockThreshold ?? 0,
            batch.Supplier?.Name);
    }

    public static InventoryTransactionDto ToDto(this InventoryTransaction transaction)
    {
        return new InventoryTransactionDto(
            transaction.Id,
            transaction.MedicineBatch.Medicine.Name,
            transaction.MedicineBatch.BatchNumber,
            transaction.Type,
            transaction.Quantity,
            transaction.Note,
            transaction.CreatedAt);
    }
}

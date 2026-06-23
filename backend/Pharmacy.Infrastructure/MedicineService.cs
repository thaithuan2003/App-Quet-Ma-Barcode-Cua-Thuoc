using Microsoft.EntityFrameworkCore;
using Pharmacy.Application;
using Pharmacy.Domain;

namespace Pharmacy.Infrastructure;

public sealed class MedicineService(PharmacyDbContext db) : IMedicineService
{
    public async Task<MedicineDto?> GetByBarcodeAsync(string barcode, CancellationToken cancellationToken)
    {
        var medicine = await db.Medicines.FirstOrDefaultAsync(x => x.Barcode == barcode, cancellationToken);
        return medicine is null ? null : await medicine.ToDtoAsync(db, cancellationToken);
    }

    public async Task<IReadOnlyList<MedicineDto>> SearchAsync(string query, CancellationToken cancellationToken)
    {
        query = query.Trim();
        var medicines = await db.Medicines
            .Where(x => query == string.Empty
                || x.Name.Contains(query)
                || x.Barcode.Contains(query)
                || x.ActiveIngredient.Contains(query))
            .OrderBy(x => x.Name)
            .ToListAsync(cancellationToken);

        var result = new List<MedicineDto>();
        foreach (var medicine in medicines)
        {
            result.Add(await medicine.ToDtoAsync(db, cancellationToken));
        }

        return result;
    }

    public async Task<MedicineDto> CreateAsync(UpsertMedicineRequest request, CancellationToken cancellationToken)
    {
        Validate(request);
        var barcode = request.Barcode.Trim();
        if (await db.Medicines.AnyAsync(x => x.Barcode == barcode, cancellationToken))
        {
            throw new InvalidOperationException("Mã vạch thuốc đã tồn tại.");
        }

        var medicine = new Medicine();
        Apply(medicine, request);
        db.Medicines.Add(medicine);
        await db.SaveChangesAsync(cancellationToken);
        return await medicine.ToDtoAsync(db, cancellationToken);
    }

    public async Task<MedicineDto> UpdateAsync(int medicineId, UpsertMedicineRequest request, CancellationToken cancellationToken)
    {
        Validate(request);
        var medicine = await db.Medicines.FirstOrDefaultAsync(x => x.Id == medicineId, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy thuốc.");
        var barcode = request.Barcode.Trim();
        if (await db.Medicines.AnyAsync(x => x.Id != medicineId && x.Barcode == barcode, cancellationToken))
        {
            throw new InvalidOperationException("Mã vạch thuốc đã tồn tại.");
        }

        Apply(medicine, request);
        medicine.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(cancellationToken);
        return await medicine.ToDtoAsync(db, cancellationToken);
    }

    public async Task DeleteAsync(int medicineId, CancellationToken cancellationToken)
    {
        var medicine = await db.Medicines
            .Include(x => x.Batches)
            .FirstOrDefaultAsync(x => x.Id == medicineId, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy thuốc.");

        if (medicine.Batches.Any())
        {
            throw new InvalidOperationException("Thuốc đã có lô/tồn kho, không thể xóa. Hãy xóa lô thuốc trước.");
        }

        db.Medicines.Remove(medicine);
        await db.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<MedicineDto>> GetSimilarAsync(int medicineId, CancellationToken cancellationToken)
    {
        var source = await db.Medicines.FindAsync([medicineId], cancellationToken);
        if (source is null)
        {
            return [];
        }

        var medicines = await db.Medicines
            .Where(x => x.Id != source.Id
                && (x.ActiveIngredient == source.ActiveIngredient || x.DosageForm == source.DosageForm))
            .OrderByDescending(x => x.ActiveIngredient == source.ActiveIngredient)
            .ThenBy(x => x.Name)
            .Take(20)
            .ToListAsync(cancellationToken);

        var result = new List<MedicineDto>();
        foreach (var medicine in medicines)
        {
            result.Add(await medicine.ToDtoAsync(db, cancellationToken));
        }

        return result;
    }

    public async Task<InteractionResultDto> CheckInteractionsAsync(IReadOnlyList<string> barcodes, CancellationToken cancellationToken)
    {
        var medicines = await db.Medicines
            .Where(x => barcodes.Contains(x.Barcode))
            .ToListAsync(cancellationToken);

        var medicineIds = medicines.Select(x => x.Id).ToList();
        var interactions = await db.MedicineInteractions
            .Include(x => x.MedicineA)
            .Include(x => x.MedicineB)
            .Where(x => medicineIds.Contains(x.MedicineAId) && medicineIds.Contains(x.MedicineBId))
            .ToListAsync(cancellationToken);

        var missing = barcodes.Except(medicines.Select(x => x.Barcode)).ToList();
        var details = interactions
            .Select(x => $"{x.MedicineA.Name} + {x.MedicineB.Name}: {x.Description}")
            .Concat(missing.Select(x => $"Không tìm thấy mã vạch {x} để kiểm tra tương tác."))
            .ToList();

        var severity = interactions.Any(x => x.Severity == AlertSeverity.Critical)
            ? AlertSeverity.Critical
            : interactions.Any() || missing.Any() ? AlertSeverity.Warning : AlertSeverity.Info;

        var message = severity == AlertSeverity.Info
            ? "Chưa phát hiện tương tác trong dữ liệu hiện có."
            : "Cần kiểm tra lại trước khi cấp phát.";

        return new InteractionResultDto(severity, message, details);
    }

    private static void Validate(UpsertMedicineRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new InvalidOperationException("Tên thuốc không được để trống.");
        }
        if (string.IsNullOrWhiteSpace(request.Barcode))
        {
            throw new InvalidOperationException("Mã vạch thuốc không được để trống.");
        }
        if (request.SalePrice < 0)
        {
            throw new InvalidOperationException("Đơn giá bán không hợp lệ.");
        }
    }

    private static void Apply(Medicine medicine, UpsertMedicineRequest request)
    {
        medicine.Name = request.Name.Trim();
        medicine.Barcode = request.Barcode.Trim();
        medicine.ActiveIngredient = request.ActiveIngredient.Trim();
        medicine.Manufacturer = request.Manufacturer.Trim();
        medicine.DosageForm = request.DosageForm.Trim();
        medicine.Strength = request.Strength.Trim();
        medicine.UsageInstruction = request.UsageInstruction.Trim();
        medicine.WarningNote = request.WarningNote.Trim();
        medicine.SalePrice = request.SalePrice;
        medicine.RequiresPrescription = request.RequiresPrescription;
    }
}

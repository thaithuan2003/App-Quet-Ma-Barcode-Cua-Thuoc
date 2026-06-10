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
            .Include(x => x.Aliases)
            .Where(x => query == string.Empty
                || x.Name.Contains(query)
                || x.Barcode.Contains(query)
                || x.ActiveIngredient.Contains(query)
                || x.Aliases.Any(a => a.Alias.Contains(query)))
            .OrderBy(x => x.Name)
            .Take(50)
            .ToListAsync(cancellationToken);

        var result = new List<MedicineDto>();
        foreach (var medicine in medicines)
        {
            result.Add(await medicine.ToDtoAsync(db, cancellationToken));
        }

        return result;
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
            .Concat(missing.Select(x => $"Khong tim thay barcode {x} de kiem tra tuong tac."))
            .ToList();

        var severity = interactions.Any(x => x.Severity == AlertSeverity.Critical)
            ? AlertSeverity.Critical
            : interactions.Any() || missing.Any() ? AlertSeverity.Warning : AlertSeverity.Info;

        var message = severity == AlertSeverity.Info
            ? "Chua phat hien tuong tac trong du lieu hien co."
            : "Can kiem tra lai truoc khi cap phat.";

        return new InteractionResultDto(severity, message, details);
    }
}

using Microsoft.EntityFrameworkCore;
using Pharmacy.Application;
using Pharmacy.Domain;

namespace Pharmacy.Infrastructure;

public sealed class ScanService(PharmacyDbContext db) : IScanService
{
    public async Task<ScanResponse> ScanAsync(ScanRequest request, int userId, CancellationToken cancellationToken)
    {
        var medicine = await db.Medicines.FirstOrDefaultAsync(x => x.Barcode == request.Barcode, cancellationToken);
        db.ScanHistories.Add(new ScanHistory
        {
            UserId = userId,
            MedicineId = medicine?.Id,
            Barcode = request.Barcode,
            Found = medicine is not null
        });
        await db.SaveChangesAsync(cancellationToken);

        if (medicine is null)
        {
            return new ScanResponse(false, "Khong tim thay thuoc voi ma vach nay.", null);
        }

        return new ScanResponse(true, "Tim thay thuoc.", await medicine.ToDtoAsync(db, cancellationToken));
    }

    public async Task<IReadOnlyList<ScanResponse>> MultiScanAsync(MultiScanRequest request, int userId, CancellationToken cancellationToken)
    {
        var result = new List<ScanResponse>();
        foreach (var barcode in request.Barcodes.Distinct())
        {
            result.Add(await ScanAsync(new ScanRequest(barcode), userId, cancellationToken));
        }

        return result;
    }

    public async Task<IReadOnlyList<ScanResponse>> GetHistoryAsync(int userId, CancellationToken cancellationToken)
    {
        var histories = await db.ScanHistories
            .Include(x => x.Medicine)
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .Take(100)
            .ToListAsync(cancellationToken);

        var result = new List<ScanResponse>();
        foreach (var item in histories)
        {
            result.Add(new ScanResponse(
                item.Found,
                item.Found ? "Da quet thanh cong." : "Khong tim thay thuoc.",
                item.Medicine is null ? null : await item.Medicine.ToDtoAsync(db, cancellationToken)));
        }

        return result;
    }
}

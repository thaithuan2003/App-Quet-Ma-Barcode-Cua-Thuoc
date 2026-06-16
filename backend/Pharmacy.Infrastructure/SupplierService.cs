using Microsoft.EntityFrameworkCore;
using Pharmacy.Application;
using Pharmacy.Domain;

namespace Pharmacy.Infrastructure;

public sealed class SupplierService(PharmacyDbContext db) : ISupplierService
{
    public async Task<IReadOnlyList<SupplierDto>> GetSuppliersAsync(CancellationToken cancellationToken)
    {
        return await db.Suppliers
            .OrderBy(x => x.Name)
            .Select(x => new SupplierDto(x.Id, x.Name, x.Phone, x.Address))
            .ToListAsync(cancellationToken);
    }

    public async Task<SupplierDto> CreateAsync(UpsertSupplierRequest request, CancellationToken cancellationToken)
    {
        Validate(request);
        var supplier = new Supplier
        {
            Name = request.Name.Trim(),
            Phone = request.Phone.Trim(),
            Address = request.Address.Trim()
        };
        db.Suppliers.Add(supplier);
        await db.SaveChangesAsync(cancellationToken);
        return ToDto(supplier);
    }

    public async Task<SupplierDto> UpdateAsync(int supplierId, UpsertSupplierRequest request, CancellationToken cancellationToken)
    {
        Validate(request);
        var supplier = await db.Suppliers.FindAsync([supplierId], cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy nhà cung ứng.");
        supplier.Name = request.Name.Trim();
        supplier.Phone = request.Phone.Trim();
        supplier.Address = request.Address.Trim();
        supplier.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(cancellationToken);
        return ToDto(supplier);
    }

    public async Task DeleteAsync(int supplierId, CancellationToken cancellationToken)
    {
        var supplier = await db.Suppliers.FindAsync([supplierId], cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy nhà cung ứng.");
        if (await db.MedicineBatches.AnyAsync(x => x.SupplierId == supplierId, cancellationToken))
        {
            throw new InvalidOperationException("Nhà cung ứng đã được dùng trong lô thuốc, không thể xóa.");
        }
        db.Suppliers.Remove(supplier);
        await db.SaveChangesAsync(cancellationToken);
    }

    private static void Validate(UpsertSupplierRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new InvalidOperationException("Tên nhà cung ứng không được để trống.");
        }
    }

    private static SupplierDto ToDto(Supplier supplier)
    {
        return new SupplierDto(supplier.Id, supplier.Name, supplier.Phone, supplier.Address);
    }
}

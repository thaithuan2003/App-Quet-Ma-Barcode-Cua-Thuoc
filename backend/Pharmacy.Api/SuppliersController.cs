using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmacy.Application;

namespace Pharmacy.Api;

[ApiController]
[Authorize]
[Route("api/suppliers")]
public sealed class SuppliersController(ISupplierService suppliers) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<SupplierDto>>> Get(CancellationToken cancellationToken)
    {
        return Ok(await suppliers.GetSuppliersAsync(cancellationToken));
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<SupplierDto>> Create(UpsertSupplierRequest request, CancellationToken cancellationToken)
    {
        return Ok(await suppliers.CreateAsync(request, cancellationToken));
    }

    [HttpPut("{supplierId:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<SupplierDto>> Update(int supplierId, UpsertSupplierRequest request, CancellationToken cancellationToken)
    {
        return Ok(await suppliers.UpdateAsync(supplierId, request, cancellationToken));
    }

    [HttpDelete("{supplierId:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int supplierId, CancellationToken cancellationToken)
    {
        await suppliers.DeleteAsync(supplierId, cancellationToken);
        return NoContent();
    }
}

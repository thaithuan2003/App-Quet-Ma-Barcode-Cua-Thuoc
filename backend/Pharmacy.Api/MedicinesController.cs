using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmacy.Application;

namespace Pharmacy.Api;

[ApiController]
[Authorize]
[Route("api/medicines")]
public sealed class MedicinesController(IMedicineService medicines) : ControllerBase
{
    [HttpGet("barcode/{barcode}")]
    public async Task<ActionResult<MedicineDto>> GetByBarcode(string barcode, CancellationToken cancellationToken)
    {
        var medicine = await medicines.GetByBarcodeAsync(barcode, cancellationToken);
        return medicine is null ? NotFound(new { message = "Không tìm thấy thuốc." }) : Ok(medicine);
    }

    [HttpGet("search")]
    public async Task<ActionResult<IReadOnlyList<MedicineDto>>> Search([FromQuery] string q = "", CancellationToken cancellationToken = default)
    {
        return Ok(await medicines.SearchAsync(q, cancellationToken));
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<MedicineDto>> Create(UpsertMedicineRequest request, CancellationToken cancellationToken)
    {
        return Ok(await medicines.CreateAsync(request, cancellationToken));
    }

    [HttpPut("{medicineId:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<MedicineDto>> Update(int medicineId, UpsertMedicineRequest request, CancellationToken cancellationToken)
    {
        return Ok(await medicines.UpdateAsync(medicineId, request, cancellationToken));
    }

    [HttpDelete("{medicineId:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int medicineId, CancellationToken cancellationToken)
    {
        await medicines.DeleteAsync(medicineId, cancellationToken);
        return NoContent();
    }

    [HttpGet("{medicineId:int}/similar")]
    public async Task<ActionResult<IReadOnlyList<MedicineDto>>> Similar(int medicineId, CancellationToken cancellationToken)
    {
        return Ok(await medicines.GetSimilarAsync(medicineId, cancellationToken));
    }

    [HttpPost("interactions")]
    public async Task<ActionResult<InteractionResultDto>> CheckInteractions(MultiScanRequest request, CancellationToken cancellationToken)
    {
        return Ok(await medicines.CheckInteractionsAsync(request.Barcodes, cancellationToken));
    }
}

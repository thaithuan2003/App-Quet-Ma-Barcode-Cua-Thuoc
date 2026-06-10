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
        return medicine is null ? NotFound(new { message = "Khong tim thay thuoc." }) : Ok(medicine);
    }

    [HttpGet("search")]
    public async Task<ActionResult<IReadOnlyList<MedicineDto>>> Search([FromQuery] string q = "", CancellationToken cancellationToken = default)
    {
        return Ok(await medicines.SearchAsync(q, cancellationToken));
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

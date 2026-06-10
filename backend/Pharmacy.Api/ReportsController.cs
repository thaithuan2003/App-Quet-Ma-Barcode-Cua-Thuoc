using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmacy.Application;

namespace Pharmacy.Api;

[ApiController]
[Authorize]
[Route("api/reports")]
public sealed class ReportsController(IReportService reports) : ControllerBase
{
    [HttpGet("summary")]
    public async Task<ActionResult<ReportDto>> Summary(CancellationToken cancellationToken)
    {
        return Ok(await reports.GetSummaryAsync(cancellationToken));
    }

    [HttpGet("medicines")]
    public async Task<ActionResult<IReadOnlyList<MedicineDto>>> Medicines(CancellationToken cancellationToken)
    {
        return Ok(await reports.GetMedicineInventoryAsync(cancellationToken));
    }

    [HttpGet("batches")]
    public async Task<ActionResult<IReadOnlyList<BatchDto>>> Batches(CancellationToken cancellationToken)
    {
        return Ok(await reports.GetBatchesAsync(cancellationToken));
    }

    [HttpGet("near-expiry-batches")]
    public async Task<ActionResult<IReadOnlyList<BatchDto>>> NearExpiryBatches(CancellationToken cancellationToken)
    {
        return Ok(await reports.GetNearExpiryBatchesAsync(cancellationToken));
    }

    [HttpGet("expired-batches")]
    public async Task<ActionResult<IReadOnlyList<BatchDto>>> ExpiredBatches(CancellationToken cancellationToken)
    {
        return Ok(await reports.GetExpiredBatchesAsync(cancellationToken));
    }

    [HttpGet("today-scans")]
    public async Task<ActionResult<IReadOnlyList<ScanReportDto>>> TodayScans(CancellationToken cancellationToken)
    {
        return Ok(await reports.GetTodayScansAsync(cancellationToken));
    }
}

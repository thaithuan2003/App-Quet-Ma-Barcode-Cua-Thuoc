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
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmacy.Application;

namespace Pharmacy.Api;

[ApiController]
[Authorize]
[Route("api/scans")]
public sealed class ScansController(IScanService scans) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<ScanResponse>> Scan(ScanRequest request, CancellationToken cancellationToken)
    {
        return Ok(await scans.ScanAsync(request, User.GetUserId(), cancellationToken));
    }

    [HttpPost("multi")]
    public async Task<ActionResult<IReadOnlyList<ScanResponse>>> MultiScan(MultiScanRequest request, CancellationToken cancellationToken)
    {
        return Ok(await scans.MultiScanAsync(request, User.GetUserId(), cancellationToken));
    }

    [HttpGet("history")]
    public async Task<ActionResult<IReadOnlyList<ScanResponse>>> History(CancellationToken cancellationToken)
    {
        return Ok(await scans.GetHistoryAsync(User.GetUserId(), cancellationToken));
    }
}

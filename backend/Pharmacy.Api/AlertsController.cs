using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmacy.Application;

namespace Pharmacy.Api;

[ApiController]
[Authorize]
[Route("api/alerts")]
public sealed class AlertsController(IAlertService alerts) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<AlertDto>>> Get(CancellationToken cancellationToken)
    {
        return Ok(await alerts.GetAlertsAsync(cancellationToken));
    }
}

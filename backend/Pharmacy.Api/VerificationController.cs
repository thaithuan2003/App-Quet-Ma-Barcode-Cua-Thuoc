using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmacy.Application;

namespace Pharmacy.Api;

[ApiController]
[Authorize]
[Route("api/verification")]
public sealed class VerificationController(IVerificationService verification) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<VerificationResponse>> Verify(VerificationRequest request, CancellationToken cancellationToken)
    {
        return Ok(await verification.VerifyAsync(request, User.GetUserId(), cancellationToken));
    }
}

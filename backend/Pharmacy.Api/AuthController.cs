using Microsoft.AspNetCore.Mvc;
using Pharmacy.Application;

namespace Pharmacy.Api;

[ApiController]
[Route("api/auth")]
public sealed class AuthController(IAuthService authService) : ControllerBase
{
    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest request, CancellationToken cancellationToken)
    {
        var response = await authService.LoginAsync(request, cancellationToken);
        return response is null ? Unauthorized(new { message = "Sai tai khoan hoac mat khau." }) : Ok(response);
    }
}

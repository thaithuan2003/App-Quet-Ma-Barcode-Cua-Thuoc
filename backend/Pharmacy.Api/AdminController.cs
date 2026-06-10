using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmacy.Application;

namespace Pharmacy.Api;

[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/admin")]
public sealed class AdminController(IAdminService admin) : ControllerBase
{
    [HttpGet("users")]
    public async Task<ActionResult<IReadOnlyList<UserDto>>> Users(CancellationToken cancellationToken)
    {
        return Ok(await admin.GetUsersAsync(cancellationToken));
    }

    [HttpPost("staff")]
    public async Task<ActionResult<UserDto>> CreateStaff(CreateStaffRequest request, CancellationToken cancellationToken)
    {
        return Ok(await admin.CreateStaffAsync(request, cancellationToken));
    }

    [HttpPatch("users/{userId:int}/status")]
    public async Task<ActionResult<UserDto>> UpdateUserStatus(int userId, UpdateUserStatusRequest request, CancellationToken cancellationToken)
    {
        return Ok(await admin.UpdateUserStatusAsync(userId, request, cancellationToken));
    }

    [HttpPut("staff/{userId:int}")]
    public async Task<ActionResult<UserDto>> UpdateStaff(int userId, UpdateStaffRequest request, CancellationToken cancellationToken)
    {
        return Ok(await admin.UpdateStaffAsync(userId, request, cancellationToken));
    }

    [HttpDelete("staff/{userId:int}")]
    public async Task<IActionResult> DeleteStaff(int userId, CancellationToken cancellationToken)
    {
        await admin.DeleteStaffAsync(userId, cancellationToken);
        return NoContent();
    }

}

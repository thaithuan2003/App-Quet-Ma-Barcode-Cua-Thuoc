using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmacy.Application;

namespace Pharmacy.Api;

[ApiController]
[Authorize]
[Route("api/consultation")]
public sealed class ConsultationController(IConsultationService consultation) : ControllerBase
{
    [HttpPost("medicine")]
    public async Task<ActionResult<MedicineConsultationResponse>> SearchMedicine(
        MedicineConsultationRequest request,
        CancellationToken cancellationToken)
    {
        return Ok(await consultation.SearchMedicineAsync(request, cancellationToken));
    }
}

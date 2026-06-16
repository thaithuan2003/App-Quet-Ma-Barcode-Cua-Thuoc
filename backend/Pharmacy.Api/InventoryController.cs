using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmacy.Application;

namespace Pharmacy.Api;

[ApiController]
[Authorize]
[Route("api/inventory")]
public sealed class InventoryController(IInventoryService inventory) : ControllerBase
{
    [HttpGet("batches")]
    public async Task<ActionResult<IReadOnlyList<BatchDto>>> Batches(CancellationToken cancellationToken)
    {
        return Ok(await inventory.GetBatchesAsync(cancellationToken));
    }

    [HttpPost("batches")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<BatchDto>> CreateBatch(CreateBatchRequest request, CancellationToken cancellationToken)
    {
        return Ok(await inventory.CreateBatchAsync(request, User.GetUserId(), cancellationToken));
    }

    [HttpPut("batches/{batchId:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<BatchDto>> UpdateBatch(int batchId, UpdateBatchRequest request, CancellationToken cancellationToken)
    {
        return Ok(await inventory.UpdateBatchAsync(batchId, request, User.GetUserId(), cancellationToken));
    }

    [HttpDelete("batches/{batchId:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteBatch(int batchId, CancellationToken cancellationToken)
    {
        await inventory.DeleteBatchAsync(batchId, cancellationToken);
        return NoContent();
    }

    [HttpPost("import")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<InventoryTransactionDto>> Import(InventoryChangeRequest request, CancellationToken cancellationToken)
    {
        return Ok(await inventory.ImportAsync(request, User.GetUserId(), cancellationToken));
    }

    [HttpPost("export")]
    public async Task<ActionResult<InventoryTransactionDto>> Export(InventoryChangeRequest request, CancellationToken cancellationToken)
    {
        return Ok(await inventory.ExportAsync(request, User.GetUserId(), cancellationToken));
    }

    [HttpPost("adjust")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<InventoryTransactionDto>> Adjust(InventoryAdjustmentRequest request, CancellationToken cancellationToken)
    {
        return Ok(await inventory.AdjustAsync(request, User.GetUserId(), cancellationToken));
    }

    [HttpGet("transactions")]
    public async Task<ActionResult<IReadOnlyList<InventoryTransactionDto>>> Transactions(CancellationToken cancellationToken)
    {
        return Ok(await inventory.GetTransactionsAsync(cancellationToken));
    }
}

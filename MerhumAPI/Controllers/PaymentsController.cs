using MerhumAPI.Common;
using MerhumAPI.DTOs.Payment;
using MerhumAPI.Services.Payment;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MerhumAPI.Controllers;

[ApiController]
[Route("api/payments")]
[Authorize]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentService _paymentService;

    public PaymentsController(IPaymentService paymentService) => _paymentService = paymentService;

    [HttpPost("initiate")]
    public async Task<ActionResult<ApiResponse<PaymentResponseDto>>> Initiate([FromBody] CreatePaymentDto request)
    {
        if (request == null || request.ServiceOrderId <= 0)
            return BadRequest(ApiResponse<PaymentResponseDto>.Fail("Neispravan zahtjev za plaćanje."));

        var result = await _paymentService.InitiatePaymentAsync(request.ServiceOrderId);
        return Ok(ApiResponse<PaymentResponseDto>.Ok(result));
    }

    [HttpPost("capture")]
    public async Task<ActionResult<ApiResponse<string>>> Capture([FromBody] CapturePaymentDto request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.PaypalOrderId))
            return BadRequest(ApiResponse<string>.Fail("Nedostaje identifikator plaćanja."));

        var success = await _paymentService.CompletePaymentAsync(request.PaypalOrderId);
        if (!success)
            return BadRequest(ApiResponse<string>.Fail("Plaćanje nije uspjelo. Molimo pokušajte ponovo."));

        return Ok(ApiResponse<string>.Ok("Plaćanje uspješno izvršeno."));
    }

    [HttpGet("order/{serviceOrderId:int}")]
    public async Task<ActionResult<ApiResponse<PaymentStatusDto>>> GetStatus(int serviceOrderId)
    {
        var status = await _paymentService.GetStatusAsync(serviceOrderId);
        return Ok(ApiResponse<PaymentStatusDto>.Ok(status));
    }

    [HttpPost("refund/{serviceOrderId:int}")]
    public async Task<ActionResult<ApiResponse<PaymentStatusDto>>> Refund(int serviceOrderId)
    {
        var result = await _paymentService.RefundPaymentAsync(serviceOrderId);
        return Ok(ApiResponse<PaymentStatusDto>.Ok(result, "Povrat sredstava uspješno izvršen."));
    }
}

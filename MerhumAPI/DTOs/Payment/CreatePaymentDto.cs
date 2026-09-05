using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.Payment;

public class CreatePaymentDto
{
    [Range(1, int.MaxValue, ErrorMessage = "Odaberite ispravnu stavku.")]
    public int ServiceOrderId { get; set; }
}

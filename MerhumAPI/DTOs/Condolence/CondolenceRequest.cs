using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.Condolence;

public class CondolenceRequest
{
    [Required]
    public int ObituaryId { get; set; }

    [Required, MaxLength(150)]
    public string AuthorName { get; set; } = string.Empty;

    [Required, MaxLength(1000)]
    public string Text { get; set; } = string.Empty;
}

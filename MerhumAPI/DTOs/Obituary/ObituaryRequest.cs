using System.ComponentModel.DataAnnotations;

namespace MerhumAPI.DTOs.Obituary;

public class ObituaryRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Odaberite ispravnu stavku.")]
    public int DeceasedId { get; set; }
    public bool IsPublic { get; set; } = true;
}

public class ObituaryUpdateRequest
{
    public bool IsPublic { get; set; }
    public bool IsActive { get; set; }
}

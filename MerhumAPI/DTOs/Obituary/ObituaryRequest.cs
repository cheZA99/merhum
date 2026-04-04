namespace MerhumAPI.DTOs.Obituary;

public class ObituaryRequest
{
    public int DeceasedId { get; set; }
    public bool IsPublic { get; set; } = true;
}

public class ObituaryUpdateRequest
{
    public bool IsPublic { get; set; }
    public bool IsActive { get; set; }
}

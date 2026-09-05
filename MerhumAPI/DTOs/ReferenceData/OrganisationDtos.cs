namespace MerhumAPI.DTOs.ReferenceData;

public class MuftiateResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

public class MajlisResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int MuftiateId { get; set; }
    public string MuftiateName { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

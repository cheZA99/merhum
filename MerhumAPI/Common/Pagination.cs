namespace MerhumAPI.Common;

public static class Pagination
{
    public const int MaxPageSize = 100;

    public static (int pageNumber, int pageSize) Normalize(int pageNumber, int pageSize)
    {
        if (pageNumber < 1)
            pageNumber = 1;
        if (pageSize < 1)
            pageSize = 20;
        if (pageSize > MaxPageSize)
            pageSize = MaxPageSize;
        return (pageNumber, pageSize);
    }
}

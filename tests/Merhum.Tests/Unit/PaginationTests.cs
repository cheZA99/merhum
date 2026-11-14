using MerhumAPI.Common;

namespace Merhum.Tests.Unit;

public class PaginationTests
{
    [Theory]
    [InlineData(1, 10, 1, 10)]
    [InlineData(0, 10, 1, 10)]
    [InlineData(-5, 10, 1, 10)]
    [InlineData(2, 0, 2, 20)]
    [InlineData(2, -1, 2, 20)]
    [InlineData(3, 500, 3, Pagination.MaxPageSize)]
    [InlineData(1, Pagination.MaxPageSize, 1, Pagination.MaxPageSize)]
    public void Normalize_clamps_page_and_size(int page, int size, int expectedPage, int expectedSize)
    {
        var (pageNumber, pageSize) = Pagination.Normalize(page, size);

        Assert.Equal(expectedPage, pageNumber);
        Assert.Equal(expectedSize, pageSize);
    }
}

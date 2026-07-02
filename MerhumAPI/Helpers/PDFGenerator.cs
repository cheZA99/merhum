using MerhumAPI.Models;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace MerhumAPI.Helpers;

public static class PDFGenerator
{
    static PDFGenerator()
    {
        QuestPDF.Settings.License = LicenseType.Community;
    }

    public static byte[] GenerateDeceasedReport(Deceased deceased)
    {
        var document = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(2, Unit.Centimetre);
                page.DefaultTextStyle(x => x.FontSize(11));

                page.Header().Text("Funeral Procedure Report")
                    .SemiBold().FontSize(20).FontColor(Colors.Blue.Medium);

                page.Content().Column(col =>
                {
                    col.Spacing(10);

                    col.Item().Text($"Name: {deceased.FirstName} {deceased.LastName}").Bold();
                    col.Item().Text($"Date of Birth: {deceased.DateOfBirth:d}");
                    col.Item().Text($"Date of Death: {deceased.DateOfDeath:d}");
                    col.Item().Text($"Place of Death: {deceased.PlaceOfDeath}");
                    col.Item().Text($"City: {deceased.City?.Name ?? "-"}");
                    col.Item().Text($"Status: {deceased.ProcedureStatus?.Name ?? "-"}");
                    col.Item().Text($"Contact Person: {deceased.ContactPersonName}");
                    col.Item().Text($"Contact Phone: {deceased.ContactPersonPhone}");

                    if (deceased.Appointments.Any())
                    {
                        col.Item().PaddingTop(10).Text("Funeral Appointments").Bold().FontSize(14);
                        foreach (var apt in deceased.Appointments)
                        {
                            col.Item().Text($"- {apt.FuneralDateTime:g} | {apt.Mosque?.Name} | {apt.Cemetery?.Name} | {apt.Status}");
                        }
                    }

                    if (deceased.ServiceOrders.Any())
                    {
                        col.Item().PaddingTop(10).Text("Service Orders").Bold().FontSize(14);
                        foreach (var order in deceased.ServiceOrders)
                        {
                            col.Item().Text($"- {order.ServiceType?.Name} | {order.FuneralHome?.Name} | {order.Price:C} | {order.Status}");
                        }
                    }
                });

                page.Footer().AlignCenter().Text(x =>
                {
                    x.Span("Merhum System - Generated: ");
                    x.Span(DateTime.Now.ToString("g"));
                });
            });
        });

        return document.GeneratePdf();
    }

    public static byte[] GenerateObituaryDocument(Obituary obituary)
    {
        var deceased = obituary.Deceased;

        var document = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(2, Unit.Centimetre);
                page.DefaultTextStyle(x => x.FontSize(11));

                page.Header().Text("Obituary - Merhum")
                    .SemiBold().FontSize(20).FontColor(Colors.Grey.Darken3);

                page.Content().Column(col =>
                {
                    col.Spacing(10);

                    col.Item().Text($"{deceased?.FirstName} {deceased?.LastName}")
                        .Bold().FontSize(18);

                    col.Item().Text($"{deceased?.DateOfBirth:d} - {deceased?.DateOfDeath:d}");
                    col.Item().Text($"City: {deceased?.City?.Name ?? "-"}");

                    if (obituary.Condolences.Any())
                    {
                        col.Item().PaddingTop(15).Text("Condolences").Bold().FontSize(14);
                        foreach (var c in obituary.Condolences.Where(x => x.IsApproved))
                        {
                            col.Item().BorderLeft(2).PaddingLeft(8).Column(inner =>
                            {
                                inner.Item().Text(c.AuthorName).SemiBold();
                                inner.Item().Text(c.Text);
                                inner.Item().Text(c.CreatedAt.ToString("d")).FontColor(Colors.Grey.Medium);
                            });
                        }
                    }
                });

                page.Footer().AlignCenter().Text(x =>
                {
                    x.Span("merhum.ba - ");
                    x.Span(obituary.UniqueSlug);
                });
            });
        });

        return document.GeneratePdf();
    }
}

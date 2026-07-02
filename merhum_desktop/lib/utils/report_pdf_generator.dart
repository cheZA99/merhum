import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const _months = [
  '', 'Januar', 'Februar', 'Mart', 'April', 'Maj', 'Juni',
  'Juli', 'August', 'Septembar', 'Oktobar', 'Novembar', 'Decembar'
];

class ReportPdfGenerator {
  static Future<File> generateAndOpen(
    String title,
    List<pw.Widget> content,
    String fileName,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _buildHeader(title, now),
        footer: (ctx) => _buildFooter(ctx),
        build: (_) => content,
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}\\$fileName.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open with system default PDF viewer on Windows
    await Process.run('cmd', ['/c', 'start', '', file.path], runInShell: true);
    return file;
  }

  static pw.Widget _buildHeader(String title, DateTime date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text(
              'Generirano: ${DateFormat('dd.MM.yyyy HH:mm').format(date)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Divider(thickness: 1, color: PdfColors.grey400),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text('Stranica ${ctx.pageNumber} od ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    List<String>? totalsRow,
    List<double>? columnWidths,
  }) {
    final colCount = headers.length;
    final flexList = columnWidths ??
        List.generate(colCount, (_) => 1.0 / colCount);

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      columnWidths: {
        for (var i = 0; i < colCount; i++)
          i: pw.FlexColumnWidth(flexList[i]),
      },
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
    );
  }

  static pw.Widget _summaryCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal700)),
          pw.SizedBox(height: 2),
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  static Future<File> burialReport(Map<String, dynamic> data, int year) {
    final byMonth = (data['byMonth'] as List? ?? []).cast<Map<String, dynamic>>();
    final byCemetery = (data['byCemetery'] as List? ?? []).cast<Map<String, dynamic>>();
    final total = byMonth.fold<int>(0, (s, m) => s + (m['count'] as int? ?? 0));

    return generateAndOpen(
      'Izvještaj o ukopima - $year',
      [
        pw.Row(children: [
          _summaryCard('Ukupno ukopa', total.toString()),
        ]),
        pw.SizedBox(height: 16),
        pw.Text('Ukopi po mjesecima',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 6),
        _table(
          headers: ['Mjesec', 'Broj ukopa'],
          rows: byMonth
              .map((r) => [
                    _months[r['month'] as int? ?? 0],
                    (r['count'] as int? ?? 0).toString(),
                  ])
              .toList(),
          columnWidths: [0.7, 0.3],
        ),
        pw.SizedBox(height: 16),
        pw.Text('Ukopi po groblju',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 6),
        _table(
          headers: ['Groblje', 'Broj ukopa'],
          rows: byCemetery
              .map((r) => [
                    r['cemeteryName'] as String? ?? '-',
                    (r['count'] as int? ?? 0).toString(),
                  ])
              .toList(),
          columnWidths: [0.7, 0.3],
        ),
      ],
      'ukopi_$year',
    );
  }

  static Future<File> cemeteryCapacityReport(Map<String, dynamic> data) {
    final cemeteries = (data['cemeteries'] as List? ?? []).cast<Map<String, dynamic>>();

    return generateAndOpen(
      'Popunjenost groblja',
      [
        _table(
          headers: ['Groblje', 'Grad', 'Ukupno', 'Zauzeto', 'Slobodno', 'Rezervisano', 'Popunjenost'],
          rows: cemeteries.map((c) {
            final fill = (c['fillPercentage'] as num? ?? 0).toDouble();
            return [
              c['name'] as String? ?? '-',
              c['city'] as String? ?? '-',
              (c['totalSites'] as int? ?? 0).toString(),
              (c['occupiedSites'] as int? ?? 0).toString(),
              (c['freeSites'] as int? ?? 0).toString(),
              (c['reservedSites'] as int? ?? 0).toString(),
              '${fill.toStringAsFixed(1)}%',
            ];
          }).toList(),
          columnWidths: [0.22, 0.14, 0.1, 0.1, 0.1, 0.14, 0.2],
        ),
      ],
      'popunjenost_groblja_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  static Future<File> servicesReport(Map<String, dynamic> data, int year) {
    final byType = (data['byServiceType'] as List? ?? []).cast<Map<String, dynamic>>();
    final byHome = (data['byFuneralHome'] as List? ?? []).cast<Map<String, dynamic>>();

    final totalRevenue = byType.fold<double>(
        0, (s, r) => s + ((r['totalRevenue'] as num?)?.toDouble() ?? 0));
    final totalOrders = byType.fold<int>(0, (s, r) => s + (r['count'] as int? ?? 0));

    return generateAndOpen(
      'Izvještaj o pogrebnim uslugama - $year',
      [
        pw.Row(children: [
          _summaryCard('Ukupno naloga', totalOrders.toString()),
          pw.SizedBox(width: 12),
          _summaryCard('Ukupan prihod', '${totalRevenue.toStringAsFixed(2)} KM'),
        ]),
        pw.SizedBox(height: 16),
        pw.Text('Po vrsti usluge',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 6),
        _table(
          headers: ['Vrsta usluge', 'Broj naloga', 'Prihod (KM)'],
          rows: byType.map((r) => [
            r['serviceTypeName'] as String? ?? '-',
            (r['count'] as int? ?? 0).toString(),
            ((r['totalRevenue'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
          ]).toList(),
          columnWidths: [0.5, 0.2, 0.3],
        ),
        pw.SizedBox(height: 16),
        pw.Text('Po pogrebnom preduzeću',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 6),
        _table(
          headers: ['Pogrebno preduzeće', 'Broj naloga', 'Prihod (KM)'],
          rows: byHome.map((r) => [
            r['funeralHomeName'] as String? ?? '-',
            (r['count'] as int? ?? 0).toString(),
            ((r['totalRevenue'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
          ]).toList(),
          columnWidths: [0.5, 0.2, 0.3],
        ),
      ],
      'usluge_$year',
    );
  }

  static Future<File> obituariesStatsReport(Map<String, dynamic> data) {
    final topViewed = (data['topViewed'] as List? ?? []).cast<Map<String, dynamic>>();

    return generateAndOpen(
      'Statistika smrtovnica',
      [
        pw.Wrap(spacing: 10, runSpacing: 10, children: [
          _summaryCard('Ukupno', (data['total'] as int? ?? 0).toString()),
          _summaryCard('Aktivne', (data['active'] as int? ?? 0).toString()),
          _summaryCard('Javne', (data['public'] as int? ?? 0).toString()),
          _summaryCard('Ukupno pregleda', (data['totalViews'] as int? ?? 0).toString()),
          _summaryCard('Saučešća', (data['totalCondolences'] as int? ?? 0).toString()),
          _summaryCard('Odobrena saučešća', (data['approvedCondolences'] as int? ?? 0).toString()),
          _summaryCard('Na čekanju', (data['pendingCondolences'] as int? ?? 0).toString()),
        ]),
        pw.SizedBox(height: 16),
        if (topViewed.isNotEmpty) ...[
          pw.Text('Top 10 najgledanijih smrtovnica',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 6),
          _table(
            headers: ['#', 'Preminuli', 'Pregledi', 'Saučešća'],
            rows: topViewed.asMap().entries.map((e) => [
              (e.key + 1).toString(),
              e.value['deceasedFullName'] as String? ?? '-',
              (e.value['viewCount'] as int? ?? 0).toString(),
              (e.value['condolenceCount'] as int? ?? 0).toString(),
            ]).toList(),
            columnWidths: [0.08, 0.6, 0.16, 0.16],
          ),
        ],
      ],
      'smrtovnice_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  static Future<File> financialReport(Map<String, dynamic> data, int year) {
    final byMonth = (data['byMonth'] as List? ?? []).cast<Map<String, dynamic>>();
    final totalRevenue = (data['totalRevenue'] as num?)?.toDouble() ?? 0;
    final completedRevenue = (data['completedRevenue'] as num?)?.toDouble() ?? 0;
    final totalOrders = data['totalOrders'] as int? ?? 0;

    return generateAndOpen(
      'Finansijski izvještaj - $year',
      [
        pw.Row(children: [
          _summaryCard('Ukupan prihod', '${totalRevenue.toStringAsFixed(2)} KM'),
          pw.SizedBox(width: 12),
          _summaryCard('Završeni nalozi', '${completedRevenue.toStringAsFixed(2)} KM'),
          pw.SizedBox(width: 12),
          _summaryCard('Broj naloga', totalOrders.toString()),
        ]),
        pw.SizedBox(height: 16),
        pw.Text('Prihod po mjesecima',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 6),
        _table(
          headers: ['Mjesec', 'Broj naloga', 'Prihod (KM)'],
          rows: [
            ...byMonth.map((r) => [
              _months[r['month'] as int? ?? 0],
              (r['orderCount'] as int? ?? 0).toString(),
              ((r['totalRevenue'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
            ]),
            ['Ukupno', totalOrders.toString(), totalRevenue.toStringAsFixed(2)],
          ],
          columnWidths: [0.5, 0.2, 0.3],
        ),
      ],
      'finansije_$year',
    );
  }
}

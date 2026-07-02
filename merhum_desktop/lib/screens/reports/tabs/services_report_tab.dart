import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/report_provider.dart';
import '../../../utils/constants.dart';
import '../widgets/report_empty.dart';
import '../widgets/report_error.dart';

class ServicesReportTab extends StatelessWidget {
  const ServicesReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, p, _) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator());
        if (p.errorMessage != null) {
          return ReportError(message: p.errorMessage!, onRetry: p.loadServicesReport);
        }
        if (p.servicesData == null) {
          return const ReportEmpty(message: 'Nema podataka o pogrebnim uslugama.');
        }

        final data = p.servicesData!;
        final byType = (data['byServiceType'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final byHome = (data['byFuneralHome'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTable('Po vrsti usluge', byType, 'Vrsta usluge')),
              const SizedBox(width: 24),
              Expanded(child: _buildTable('Po pogrebnom preduzeću', byHome, 'Pogrebno preduzeće')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTable(String title, List<Map<String, dynamic>> rows, String nameLabel) {
    final totalRevenue = rows.fold<double>(
        0.0, (s, r) => s + ((r['totalRevenue'] as num?)?.toDouble() ?? 0.0));
    final totalCount =
        rows.fold<int>(0, (s, r) => s + (r['count'] as int? ?? 0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Table(
              border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.5),
              },
              children: [
                _header(nameLabel),
                ...rows.map(_row),
                _totalsRow(totalCount, totalRevenue),
              ],
            ),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Nema podataka.', style: AppTextStyles.body),
              ),
          ],
        ),
      ),
    );
  }

  TableRow _header(String nameLabel) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade100),
      children: [
        _cell(nameLabel, style: style),
        _cell('Nalozi', style: style),
        _cell('Prihod (KM)', style: style),
      ],
    );
  }

  TableRow _row(Map<String, dynamic> r) {
    final revenue = (r['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    return TableRow(children: [
      _cell(r.containsKey('serviceTypeName')
          ? r['serviceTypeName'] as String? ?? '-'
          : r['funeralHomeName'] as String? ?? '-'),
      _cell((r['count'] as int? ?? 0).toString()),
      _cell(revenue.toStringAsFixed(2)),
    ]);
  }

  TableRow _totalsRow(int count, double revenue) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        _cell('Ukupno', style: style),
        _cell(count.toString(), style: style),
        _cell(revenue.toStringAsFixed(2), style: style),
      ],
    );
  }

  Widget _cell(String text, {TextStyle? style}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(text, style: style ?? AppTextStyles.body),
      );
}

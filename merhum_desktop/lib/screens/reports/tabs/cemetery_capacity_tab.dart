import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/report_provider.dart';
import '../../../utils/constants.dart';
import '../widgets/report_empty.dart';
import '../widgets/report_error.dart';

class CemeteryCapacityTab extends StatelessWidget {
  const CemeteryCapacityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, p, _) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator());
        if (p.errorMessage != null) {
          return ReportError(message: p.errorMessage!, onRetry: p.loadCemeteryCapacityReport);
        }
        if (p.cemeteryCapacityData == null) {
          return const ReportEmpty(message: 'Nema podataka o popunjenosti groblja.');
        }

        final data = p.cemeteryCapacityData!;
        final cemeteries = (data['cemeteries'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        if (cemeteries.isEmpty) {
          return const ReportEmpty(message: 'Nema groblja u sistemu.');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Popunjenost groblja',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(color: Colors.grey.shade200),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                      4: FlexColumnWidth(1),
                      5: FlexColumnWidth(1.5),
                    },
                    children: [
                      _header(),
                      ...cemeteries.map(_row),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TableRow _header() {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade100),
      children: [
        _cell('Groblje', style: style),
        _cell('Ukupno', style: style),
        _cell('Zauzeto', style: style),
        _cell('Slobodno', style: style),
        _cell('Rezervisano', style: style),
        _cell('Popunjenost', style: style),
      ],
    );
  }

  TableRow _row(Map<String, dynamic> r) {
    final fill = (r['fillPercentage'] as num? ?? 0).toDouble();
    final fillColor = fill >= 90
        ? Colors.red
        : fill >= 70
            ? Colors.orange
            : Colors.green;

    return TableRow(
      children: [
        _cell(r['name'] as String? ?? '-'),
        _cell((r['totalSites'] as int? ?? 0).toString()),
        _cell((r['occupiedSites'] as int? ?? 0).toString()),
        _cell((r['freeSites'] as int? ?? 0).toString()),
        _cell((r['reservedSites'] as int? ?? 0).toString()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fill / 100,
                    backgroundColor: fillColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(fillColor),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${fill.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: fillColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(String text, {TextStyle? style}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(text, style: style ?? AppTextStyles.body),
      );
}

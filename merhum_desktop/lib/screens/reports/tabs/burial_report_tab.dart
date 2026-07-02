import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/report_provider.dart';
import '../../../utils/constants.dart';
import '../widgets/report_empty.dart';
import '../widgets/report_error.dart';

const _monthNames = [
  '', 'Januar', 'Februar', 'Mart', 'April', 'Maj', 'Juni',
  'Juli', 'August', 'Septembar', 'Oktobar', 'Novembar', 'Decembar'
];

class BurialReportTab extends StatelessWidget {
  const BurialReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, p, _) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator());
        if (p.errorMessage != null) return ReportError(message: p.errorMessage!, onRetry: p.loadBurialReport);
        if (p.burialData == null) return const ReportEmpty(message: 'Nema podataka za ukope.');

        final data = p.burialData!;
        final byMonth = (data['byMonth'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final byCemetery = (data['byCemetery'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final total = byMonth.fold<int>(0, (sum, m) => sum + (m['count'] as int? ?? 0));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCards(items: [
                _SummaryItem('Ukupno ukopa', total.toString(), Icons.people, AppColors.primary),
              ]),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildMonthTable(byMonth)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildCemeteryTable(byCemetery)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthTable(List<Map<String, dynamic>> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Po mjesecima', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Table(
              border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
              children: [
                _tableHeader(['Mjesec', 'Broj ukopa']),
                ...rows.map((r) => TableRow(children: [
                  _cell(_monthNames[r['month'] as int? ?? 0]),
                  _cell((r['count'] as int? ?? 0).toString()),
                ])),
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

  Widget _buildCemeteryTable(List<Map<String, dynamic>> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Po groblju', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Table(
              border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
              children: [
                _tableHeader(['Groblje', 'Broj ukopa']),
                ...rows.map((r) => TableRow(children: [
                  _cell(r['cemeteryName'] as String? ?? '-'),
                  _cell((r['count'] as int? ?? 0).toString()),
                ])),
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
}

TableRow _tableHeader(List<String> labels) {
  return TableRow(
    decoration: BoxDecoration(color: Colors.grey.shade100),
    children: labels.map((l) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    )).toList(),
  );
}

Widget _cell(String text) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
  child: Text(text, style: AppTextStyles.body),
);

class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryItem(this.label, this.value, this.icon, this.color);
}

class _SummaryCards extends StatelessWidget {
  final List<_SummaryItem> items;
  const _SummaryCards({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items.map((item) => SizedBox(
        width: 200,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: item.color.withValues(alpha: 0.12),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: item.color)),
                    Text(item.label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }
}

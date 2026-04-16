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

class FinancialReportTab extends StatelessWidget {
  const FinancialReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, p, _) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator());
        if (p.errorMessage != null) {
          return ReportError(message: p.errorMessage!, onRetry: p.loadFinancialReport);
        }
        if (p.financialData == null) {
          return const ReportEmpty(message: 'Nema finansijskih podataka.');
        }

        final d = p.financialData!;
        final byMonth = (d['byMonth'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final totalRevenue = (d['totalRevenue'] as num?)?.toDouble() ?? 0.0;
        final completedRevenue = (d['completedRevenue'] as num?)?.toDouble() ?? 0.0;
        final totalOrders = d['totalOrders'] as int? ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _card('Ukupan prihod', '${totalRevenue.toStringAsFixed(2)} KM',
                      Icons.payments, AppColors.primary),
                  _card('Završeni nalozi', '${completedRevenue.toStringAsFixed(2)} KM',
                      Icons.check_circle, Colors.green),
                  _card('Broj naloga', totalOrders.toString(),
                      Icons.shopping_cart, Colors.blue),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prihod po mjesecima',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      Table(
                        border: TableBorder(
                            horizontalInside: BorderSide(color: Colors.grey.shade200)),
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1.5),
                        },
                        children: [
                          _header(),
                          ...byMonth.map(_row),
                          if (byMonth.isNotEmpty) _totalsRow(totalOrders, totalRevenue),
                        ],
                      ),
                      if (byMonth.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text('Nema podataka.', style: AppTextStyles.body),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                    Text(label,
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _header() {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade100),
      children: [
        _cell('Mjesec', style: style),
        _cell('Nalozi', style: style),
        _cell('Prihod (KM)', style: style),
      ],
    );
  }

  TableRow _row(Map<String, dynamic> r) {
    final month = r['month'] as int? ?? 0;
    final revenue = (r['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    return TableRow(children: [
      _cell(_monthNames[month]),
      _cell((r['orderCount'] as int? ?? 0).toString()),
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

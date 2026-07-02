import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/report_provider.dart';
import '../../../utils/constants.dart';
import '../widgets/report_empty.dart';
import '../widgets/report_error.dart';

class ObituariesStatsTab extends StatelessWidget {
  const ObituariesStatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, p, _) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator());
        if (p.errorMessage != null) {
          return ReportError(message: p.errorMessage!, onRetry: p.loadObituariesStatsReport);
        }
        if (p.obituariesStatsData == null) {
          return const ReportEmpty(message: 'Nema podataka o smrtovnicama.');
        }

        final d = p.obituariesStatsData!;
        final topViewed = (d['topViewed'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _statCard('Ukupno', (d['total'] as int? ?? 0).toString(),
                      Icons.article, AppColors.primary),
                  _statCard('Aktivne', (d['active'] as int? ?? 0).toString(),
                      Icons.check_circle, Colors.green),
                  _statCard('Neaktivne', (d['inactive'] as int? ?? 0).toString(),
                      Icons.cancel, Colors.grey),
                  _statCard('Javne', (d['public'] as int? ?? 0).toString(),
                      Icons.public, Colors.blue),
                  _statCard('Privatne', (d['private'] as int? ?? 0).toString(),
                      Icons.lock, Colors.orange),
                  _statCard('Ukupno pregleda', (d['totalViews'] as int? ?? 0).toString(),
                      Icons.visibility, AppColors.secondary),
                  _statCard('Saučešća ukupno', (d['totalCondolences'] as int? ?? 0).toString(),
                      Icons.favorite, Colors.red),
                  _statCard('Odobrena saučešća', (d['approvedCondolences'] as int? ?? 0).toString(),
                      Icons.thumb_up, Colors.green),
                  _statCard('Na čekanju', (d['pendingCondolences'] as int? ?? 0).toString(),
                      Icons.pending, Colors.orange),
                ],
              ),
              const SizedBox(height: 24),
              if (topViewed.isNotEmpty) ...[
                const Text('Top 10 najgledanijih smrtovnica',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Table(
                      border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey.shade200)),
                      columnWidths: const {
                        0: FixedColumnWidth(40),
                        1: FlexColumnWidth(2.5),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey.shade100),
                          children: ['#', 'Preminuli', 'Slug', 'Pregledi', 'Saučešća']
                              .map((h) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Text(h,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 13)),
                                  ))
                              .toList(),
                        ),
                        ...topViewed.asMap().entries.map((entry) {
                          final i = entry.key + 1;
                          final r = entry.value;
                          return TableRow(children: [
                            _cell(i.toString()),
                            _cell(r['deceasedFullName'] as String? ?? '-'),
                            _cell(r['uniqueSlug'] as String? ?? '-'),
                            _cell((r['viewCount'] as int? ?? 0).toString()),
                            _cell((r['condolenceCount'] as int? ?? 0).toString()),
                          ]);
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 190,
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
                            fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                    Text(label,
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(text, style: AppTextStyles.body),
      );
}

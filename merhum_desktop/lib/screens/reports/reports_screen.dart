import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/report_provider.dart';
import '../../utils/constants.dart';
import '../../utils/report_pdf_generator.dart';
import '../../widgets/sidebar_widget.dart';
import 'tabs/burial_report_tab.dart';
import 'tabs/cemetery_capacity_tab.dart';
import 'tabs/financial_report_tab.dart';
import 'tabs/obituaries_stats_tab.dart';
import 'tabs/services_report_tab.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isPdfGenerating = false;
  int _currentTabIndex = 0;

  // Tabs that don't depend on a year (all-time / current-state)
  static const _yearIndependentTabs = {1, 3};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentTab();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    setState(() => _currentTabIndex = _tabController.index);
    _loadCurrentTab();
  }

  void _loadCurrentTab() {
    final p = context.read<ReportProvider>();
    switch (_tabController.index) {
      case 0:
        p.loadBurialReport();
        break;
      case 1:
        p.loadCemeteryCapacityReport();
        break;
      case 2:
        p.loadServicesReport();
        break;
      case 3:
        p.loadObituariesStatsReport();
        break;
      case 4:
        p.loadFinancialReport();
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: 10,
            onItemSelected: (i) => navigateByIndex(context, i),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Text('Izvještaji', style: AppTextStyles.heading1),
                      const Spacer(),
                      if (!_yearIndependentTabs.contains(_currentTabIndex)) ...[
                        _buildYearSelector(),
                        const SizedBox(width: 12),
                      ],
                      _buildDownloadButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textLight,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Ukopi'),
                    Tab(text: 'Popunjenost groblja'),
                    Tab(text: 'Pogrebne usluge'),
                    Tab(text: 'Smrtovnice'),
                    Tab(text: 'Finansijski'),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      BurialReportTab(),
                      CemeteryCapacityTab(),
                      ServicesReportTab(),
                      ObituariesStatsTab(),
                      FinancialReportTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Consumer<ReportProvider>(
      builder: (context, p, _) {
        final currentYear = DateTime.now().year;
        final years = List.generate(5, (i) => currentYear - i);
        return Row(
          children: [
            const Text('Godina: ', style: AppTextStyles.body),
            DropdownButton<int>(
              value: p.selectedYear,
              items: years
                  .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                  .toList(),
              onChanged: (y) {
                if (y == null) return;
                p.setYear(y);
                _loadCurrentTab();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDownloadButton() {
    return Consumer<ReportProvider>(
      builder: (context, p, _) {
        final hasData = _currentTabHasData(p);
        return ElevatedButton.icon(
          onPressed: (!hasData || _isPdfGenerating) ? null : () => _downloadPdf(p),
          icon: _isPdfGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.picture_as_pdf, size: 18),
          label: Text(_isPdfGenerating ? 'Generišem...' : 'Preuzmi PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
        );
      },
    );
  }

  bool _currentTabHasData(ReportProvider p) {
    switch (_tabController.index) {
      case 0: return p.burialData != null;
      case 1: return p.cemeteryCapacityData != null;
      case 2: return p.servicesData != null;
      case 3: return p.obituariesStatsData != null;
      case 4: return p.financialData != null;
      default: return false;
    }
  }

  Future<void> _downloadPdf(ReportProvider p) async {
    setState(() => _isPdfGenerating = true);
    try {
      switch (_tabController.index) {
        case 0:
          await ReportPdfGenerator.burialReport(p.burialData!, p.selectedYear);
          break;
        case 1:
          await ReportPdfGenerator.cemeteryCapacityReport(p.cemeteryCapacityData!);
          break;
        case 2:
          await ReportPdfGenerator.servicesReport(p.servicesData!, p.selectedYear);
          break;
        case 3:
          await ReportPdfGenerator.obituariesStatsReport(p.obituariesStatsData!);
          break;
        case 4:
          await ReportPdfGenerator.financialReport(p.financialData!, p.selectedYear);
          break;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF je generisan i otvoren.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri generisanju PDF-a: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPdfGenerating = false);
    }
  }
}

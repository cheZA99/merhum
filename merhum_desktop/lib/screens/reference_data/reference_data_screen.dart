import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/reference_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/sidebar_widget.dart';
import 'cemetery_sectors_tab.dart';
import 'cities_tab.dart';
import 'countries_tab.dart';
import 'service_types_tab.dart';

class ReferenceDataScreen extends StatefulWidget {
  const ReferenceDataScreen({super.key});

  @override
  State<ReferenceDataScreen> createState() => _ReferenceDataScreenState();
}

class _ReferenceDataScreenState extends State<ReferenceDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ReferenceProvider>();
      p.loadCountries();
      p.loadCities();
      p.loadServiceTypes();
      p.loadCemeteries().then((_) => p.loadSectors());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarWidget(
            selectedIndex: 11,
            onItemSelected: (i) => navigateByIndex(context, i),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Šifarnici', style: AppTextStyles.heading1),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Države'),
              Tab(text: 'Gradovi'),
              Tab(text: 'Vrste usluga'),
              Tab(text: 'Sektori groblja'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                CountriesTab(),
                CitiesTab(),
                ServiceTypesTab(),
                CemeterySectorsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/obituary_provider.dart';
import '../../providers/deceased_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/funeral_card_widget.dart';
import '../../widgets/loading_widget.dart';

class UpcomingFuneralsScreen extends StatefulWidget {
  const UpcomingFuneralsScreen({super.key});

  @override
  State<UpcomingFuneralsScreen> createState() => _UpcomingFuneralsScreenState();
}

class _UpcomingFuneralsScreenState extends State<UpcomingFuneralsScreen> {
  int? _selectedCityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObituaryProvider>().loadUpcomingFunerals();
      context.read<DeceasedProvider>().loadCities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nadolazeće dženaze')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Consumer<DeceasedProvider>(
              builder: (_, dp, __) {
                if (dp.cities.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<int>(
                  value: _selectedCityId,
                  decoration: const InputDecoration(labelText: 'Grad', isDense: true),
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('Svi gradovi')),
                    ...dp.cities.map((c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['name'] as String? ?? ''),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedCityId = v);
                    context.read<ObituaryProvider>().loadUpcomingFunerals(cityId: v);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<ObituaryProvider>(
              builder: (_, p, __) {
                if (p.isLoading) return const LoadingWidget();
                if (p.upcomingFunerals.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.textLight),
                        SizedBox(height: 12),
                        Text('Nema nadolazećih dženaza', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => p.loadUpcomingFunerals(cityId: _selectedCityId),
                  child: ListView.builder(
                    itemCount: p.upcomingFunerals.length,
                    itemBuilder: (_, i) => FuneralCardWidget(data: p.upcomingFunerals[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_order_model.dart';
import '../../providers/service_order_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/bottom_nav_widget.dart';
import '../profile/profile_screen.dart';

class FuneralHomeOrdersScreen extends StatefulWidget {
  const FuneralHomeOrdersScreen({super.key});

  @override
  State<FuneralHomeOrdersScreen> createState() => _FuneralHomeOrdersScreenState();
}

class _FuneralHomeOrdersScreenState extends State<FuneralHomeOrdersScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _navIndex == 0 ? const _OrdersTab() : const ProfileScreen(),
      bottomNavigationBar: BottomNavWidget(
        currentIndex: _navIndex,
        role: NavRole.funeralHome,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  String _filter = 'Sve';
  static const _statuses = ['Sve', 'Naručeno', 'U toku', 'Završeno'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceOrderProvider>().loadMyOrders();
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Naručeno':
        return AppColors.warning;
      case 'U toku':
        return AppColors.primary;
      case 'Završeno':
        return AppColors.success;
      case 'Otkazano':
        return AppColors.error;
      default:
        return AppColors.textMedium;
    }
  }

  Future<void> _showUpdateDialog(ServiceOrderModel o) async {
    String selected = o.status;
    const opts = ['Naručeno', 'U toku', 'Završeno', 'Otkazano'];
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (_, setLocal) {
        return AlertDialog(
          title: Text(o.deceasedFullName ?? 'Narudžba'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(o.serviceTypeName ?? 'Usluga', style: AppTextStyles.body),
              Text(DateFormatter.money(o.price), style: AppTextStyles.bodyMedium),
              const SizedBox(height: 12),
              const Text('Status:', style: AppTextStyles.captionBold),
              DropdownButton<String>(
                isExpanded: true,
                value: selected,
                items: opts.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
                onChanged: (v) => setLocal(() => selected = v ?? selected),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Otkaži')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('Spremi')),
          ],
        );
      }),
    );
    if (result != null && result != o.status) {
      final ok = await context.read<ServiceOrderProvider>().updateStatus(o.id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Status ažuriran' : 'Greška pri ažuriranju'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ServiceOrderProvider>();
    final filtered = _filter == 'Sve' ? p.orders : p.orders.where((o) => o.status == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Narudžbe')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _statuses.map((s) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(s),
                  selected: _filter == s,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: _filter == s ? Colors.white : AppColors.textDark),
                  onSelected: (_) => setState(() => _filter = s),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<ServiceOrderProvider>().loadMyOrders(),
              child: p.isLoading && p.orders.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : filtered.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 100),
                          Center(child: Text('Nema narudžbi.', style: AppTextStyles.bodyMedium)),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final o = filtered[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showUpdateDialog(o),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: Text(o.deceasedFullName ?? '—', style: AppTextStyles.heading3)),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _statusColor(o.status).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(o.status, style: TextStyle(fontSize: 12, color: _statusColor(o.status), fontWeight: FontWeight.w600)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(o.serviceTypeName ?? '', style: AppTextStyles.bodyMedium),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 12, color: AppColors.textLight),
                                            const SizedBox(width: 4),
                                            Text(DateFormatter.dateTime(o.orderedAt), style: AppTextStyles.caption),
                                            const SizedBox(width: 12),
                                            Text(DateFormatter.money(o.price), style: AppTextStyles.captionBold),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

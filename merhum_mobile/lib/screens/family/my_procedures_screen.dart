import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/deceased_provider.dart';
import '../../models/procedure_status_model.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import 'procedure_status_screen.dart';
import 'register_deceased_screen.dart';

class MyProceduresScreen extends StatefulWidget {
  const MyProceduresScreen({super.key});

  @override
  State<MyProceduresScreen> createState() => _MyProceduresScreenState();
}

class _MyProceduresScreenState extends State<MyProceduresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeceasedProvider>().loadMyDeceased();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DeceasedProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Moje procedure')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RegisterDeceasedScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Prijavi preminulog'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<DeceasedProvider>().loadMyDeceased(),
        child: _buildBody(p),
      ),
    );
  }

  Widget _buildBody(DeceasedProvider p) {
    if (p.isLoading && p.myDeceased.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (p.myDeceased.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Icon(Icons.folder_open, size: 80, color: AppColors.textLight),
          SizedBox(height: 16),
          Center(child: Text('Nemate prijavljenih procedura.', style: AppTextStyles.bodyMedium)),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: p.myDeceased.length,
      itemBuilder: (_, i) {
        final d = p.myDeceased[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProcedureStatusScreen(deceasedId: d.id)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.fullName, style: AppTextStyles.heading3),
                          const SizedBox(height: 4),
                          Text(
                              d.procedureStatusName != null
                                  ? ProcedureStatusModel.labelFor(d.procedureStatusName!)
                                  : 'Status nepoznat',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${d.cityName ?? ''} • ${DateFormatter.date(d.dateOfDeath)}', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textLight),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

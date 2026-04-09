import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../models/deceased_model.dart';
import '../../models/procedure_status_model.dart';
import '../../models/status_history_model.dart';
import '../../navigation/app_navigation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deceased_provider.dart';
import '../../utils/constants.dart';
import 'deceased_form_screen.dart';
import 'widgets/status_chip_widget.dart';
import 'widgets/status_timeline_widget.dart';

class DeceasedDetailsScreen extends StatefulWidget {
  final DeceasedModel deceased;

  const DeceasedDetailsScreen({super.key, required this.deceased});

  @override
  State<DeceasedDetailsScreen> createState() => _DeceasedDetailsScreenState();
}

class _DeceasedDetailsScreenState extends State<DeceasedDetailsScreen> {
  late DeceasedModel _deceased;
  List<StatusHistoryModel>? _history;

  @override
  void initState() {
    super.initState();
    _deceased = widget.deceased;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<DeceasedProvider>();
      final history = await provider.getHistory(_deceased.id);
      if (mounted) {
        setState(() => _history = history);
      }
    });
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  String _formatDateTime(DateTime d) {
    final date = _formatDate(d);
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateStatusDialog(BuildContext context) async {
    final provider = context.read<DeceasedProvider>();
    final currentStatus = provider.statuses
        .cast<ProcedureStatusModel?>()
        .firstWhere(
          (s) => s!.id == _deceased.procedureStatusId,
          orElse: () => null,
        );
    final currentOrder = currentStatus?.order ?? 0;

    final availableStatuses = provider.statuses
        .where((s) => s.order > currentOrder)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (availableStatuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nema dostupnih statusa za ažuriranje.'),
      ));
      return;
    }

    int? selectedStatusId;
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Ažuriraj status'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedStatusId,
                  decoration: const InputDecoration(
                    labelText: 'Novi status',
                    border: OutlineInputBorder(),
                  ),
                  items: availableStatuses
                      .map((s) => DropdownMenuItem<int>(
                            value: s.id,
                            child: Text(StatusChipWidget.labelFor(s.name)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedStatusId = v),
                  validator: (v) =>
                      v == null ? 'Status je obavezan.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Napomena',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Odustani'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final note = noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim();
                      final success = await provider.updateStatus(
                        _deceased.id,
                        selectedStatusId!,
                        note,
                      );

                      if (!ctx.mounted) return;

                      if (success) {
                        final newHistory =
                            await provider.getHistory(_deceased.id);
                        final refreshed =
                            await provider.getDetails(_deceased.id);
                        if (mounted) {
                          setState(() {
                            _history = newHistory;
                            if (refreshed != null) _deceased = refreshed;
                          });
                        }
                        Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Status je uspješno ažuriran.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              provider.errorMessage ?? 'Greška pri ažuriranju.'),
                          backgroundColor: AppColors.error,
                        ));
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Ažuriraj status'),
            ),
          ],
        ),
      ),
    );

    noteCtrl.dispose();
  }

  Future<void> _openEditForm(BuildContext context) async {
    final provider = context.read<DeceasedProvider>();
    provider.clearError();

    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: DeceasedFormScreen(deceased: _deceased),
        ),
      ),
    );

    if (!mounted) return;

    if (result == 'updated') {
      final refreshed = await provider.getDetails(_deceased.id);
      if (mounted && refreshed != null) {
        setState(() => _deceased = refreshed);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Zapis je uspješno ažuriran.'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<DeceasedProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši zapis'),
        content: Text(
          'Da li ste sigurni da želite obrisati zapis za ${_deceased.fullName}?\n'
          'Svi povezani podaci uključujući smrtovnicu i termine će biti obrisani.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.delete(_deceased.id);
      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Zapis je uspješno obrisan.'),
            backgroundColor: AppColors.success,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                provider.errorMessage ?? 'Greška pri brisanju.'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeceasedProvider>();
    final auth = context.watch<AuthProvider>();

    final currentStatus = provider.statuses
        .cast<ProcedureStatusModel?>()
        .firstWhere(
          (s) => s!.id == _deceased.procedureStatusId,
          orElse: () => null,
        );
    final lastStatus = provider.statuses.isNotEmpty
        ? provider.statuses.reduce((a, b) => a.order > b.order ? a : b)
        : null;
    final isLastStatus = lastStatus != null &&
        _deceased.procedureStatusId == lastStatus.id;

    final photoUrl = _deceased.photoUrl;
    final String? fullPhotoUrl = photoUrl == null
        ? null
        : (photoUrl.startsWith('/') ? '$apiBaseUrl$photoUrl' : photoUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(_deceased.fullName),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 4,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.background,
                          backgroundImage: fullPhotoUrl != null
                              ? NetworkImage(fullPhotoUrl)
                              : null,
                          child: fullPhotoUrl == null
                              ? const Icon(Icons.person,
                                  size: 60, color: AppColors.textLight)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(_deceased.fullName,
                            style: AppTextStyles.heading1),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text('${_deceased.ageAtDeath} godina',
                            style: AppTextStyles.body),
                      ),
                      const SizedBox(height: 12),
                      _infoRow('Datum rođenja:',
                          _formatDate(_deceased.dateOfBirth)),
                      _infoRow('Datum smrti:',
                          _formatDate(_deceased.dateOfDeath)),
                      _infoRow(
                          'Mjesto smrti:', _deceased.placeOfDeath),
                      _infoRow('Grad:', _deceased.cityName),
                      const Divider(height: 24),
                      const Text('Kontakt osoba',
                          style: AppTextStyles.heading2),
                      const SizedBox(height: 8),
                      _infoRow(
                          'Ime:', _deceased.contactPersonName),
                      _infoRow(
                          'Telefon:', _deceased.contactPersonPhone),
                      if (_deceased.contactPersonEmail != null)
                        _infoRow('Email:',
                            _deceased.contactPersonEmail!),
                      const Divider(height: 24),
                      _infoRow(
                          'Registrovao:', _deceased.createdByUsername),
                      _infoRow('Datum registracije:',
                          _formatDateTime(_deceased.createdAt)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () => _openEditForm(context),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Uredi'),
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary),
                          ),
                          if (auth.role == 'Administrator') ...[
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => _confirmDelete(context),
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Obriši'),
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.error),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Trenutni status',
                              style: AppTextStyles.heading2),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              StatusChipWidget(
                                  statusName:
                                      _deceased.procedureStatusName),
                              const Spacer(),
                              if (!isLastStatus)
                                FilledButton(
                                  onPressed: () =>
                                      _showUpdateStatusDialog(context),
                                  style: FilledButton.styleFrom(
                                      backgroundColor:
                                          AppColors.primary),
                                  child: const Text('Ažuriraj status'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Historija statusa',
                              style: AppTextStyles.heading2),
                          const SizedBox(height: 12),
                          if (_history == null)
                            const Center(
                                child: CircularProgressIndicator())
                          else
                            StatusTimelineWidget(
                              allStatuses: provider.statuses,
                              currentStatusOrder:
                                  currentStatus?.order ?? 1,
                              history: _history!,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Termin',
                              style: AppTextStyles.heading2),
                          const SizedBox(height: 12),
                          Text(
                            'Nema zakazanog termina.',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () =>
                                navigateByIndex(context, 3),
                            child: const Text('Zakaži termin'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Smrtovnica',
                              style: AppTextStyles.heading2),
                          const SizedBox(height: 12),
                          if (_deceased.obituarySlug != null) ...[
                            Text(
                                'Slug: ${_deceased.obituarySlug}',
                                style: AppTextStyles.body),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          'PDF nije dostupan u ovoj verziji.'),
                                    ));
                                  },
                                  child: const Text('Preuzmi PDF'),
                                ),
                              ],
                            ),
                          ] else ...[
                            Text(
                              'Nema kreirane smrtovnice.',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text(
                                      'Kreiranje smrtovnice nije implementirano u ovoj verziji.'),
                                ));
                              },
                              child: const Text('Kreiraj smrtovnicu'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

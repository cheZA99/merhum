import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/obituary_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/obituary_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/confirmation_dialog.dart';

class ObituaryDetailsScreen extends StatefulWidget {
  final int obituaryId;

  const ObituaryDetailsScreen({super.key, required this.obituaryId});

  @override
  State<ObituaryDetailsScreen> createState() => _ObituaryDetailsScreenState();
}

class _ObituaryDetailsScreenState extends State<ObituaryDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObituaryProvider>().loadById(widget.obituaryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalji smrtovnice'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ObituaryProvider>(
        builder: (context, p, _) {
          if (p.isLoading) return const Center(child: CircularProgressIndicator());
          if (p.selected == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Smrtovnica nije pronađena.',
                      style: TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => p.loadById(widget.obituaryId),
                    child: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            );
          }
          return _buildDetails(p.selected!, p);
        },
      ),
    );
  }

  Widget _buildDetails(ObituaryModel o, ObituaryProvider p) {
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.role == 'Administrator';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column — obituary info
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(o),
                const SizedBox(height: 16),
                _buildSlugCard(o),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right column — condolences
          Expanded(
            flex: 1,
            child: _buildCondolencesCard(o, p, isAdmin),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ObituaryModel o) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informacije', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            _infoRow('Preminuli', o.deceasedFullName),
            if (o.deceasedDateOfDeath != null)
              _infoRow('Datum smrti', o.deceasedDateOfDeath!),
            _infoRow('Vidljivost', o.isPublic ? 'Javna' : 'Privatna'),
            _infoRow('Status', o.isActive ? 'Aktivna' : 'Neaktivna'),
            _infoRow('Pregledi', o.viewCount.toString()),
            _infoRow('Saučešća', '${o.approvedCondolenceCount} odobrenih / ${o.condolenceCount} ukupno'),
            _infoRow('Kreirana', DateFormat('dd.MM.yyyy HH:mm').format(o.createdAt.toLocal())),
            if (o.createdByUsername != null)
              _infoRow('Kreirao/la', o.createdByUsername!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textLight)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
        ],
      ),
    );
  }

  Widget _buildSlugCard(ObituaryModel o) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Link smrtovnice', style: AppTextStyles.heading2),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    o.uniqueSlug,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: AppColors.primary),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Kopiraj slug',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: o.uniqueSlug));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Slug kopiran.'),
                          backgroundColor: AppColors.success),
                    );
                  },
                ),
              ],
            ),
            if (o.qrCodeUrl != null) ...[
              const SizedBox(height: 12),
              Text('QR kod URL:',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textLight)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(o.qrCodeUrl!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    tooltip: 'Kopiraj QR URL',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: o.qrCodeUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('QR URL kopiran.'),
                            backgroundColor: AppColors.success),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCondolencesCard(ObituaryModel o, ObituaryProvider p, bool isAdmin) {
    final pending = o.condolences.where((c) => !c.isApproved).toList();
    final approved = o.condolences.where((c) => c.isApproved).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Saučešća', style: AppTextStyles.heading2),
                const Spacer(),
                if (pending.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${pending.length} na čekanju',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (o.condolences.isEmpty)
              const Text('Nema saučešća.', style: AppTextStyles.body)
            else ...[
              if (pending.isNotEmpty) ...[
                const Text('Na čekanju:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                ...pending.map((c) => _condolenceCard(c, p, isAdmin, pending: true)),
                const Divider(height: 24),
              ],
              if (approved.isNotEmpty) ...[
                const Text('Odobrena:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                ...approved.map((c) => _condolenceCard(c, p, isAdmin, pending: false)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _condolenceCard(CondolenceModel c, ObituaryProvider p, bool isAdmin,
      {required bool pending}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pending
            ? Colors.orange.withValues(alpha: 0.06)
            : Colors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: pending
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(c.authorName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Text(DateFormat('dd.MM.yyyy').format(c.createdAt.toLocal()),
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              if (pending) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check_circle, size: 18, color: Colors.green),
                  tooltip: 'Odobri',
                  onPressed: () async {
                    final ok = await p.approveCondolence(c.id);
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Saučešće odobreno.'),
                            backgroundColor: AppColors.success),
                      );
                    }
                  },
                ),
              ],
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete, size: 16, color: AppColors.error),
                  tooltip: 'Obriši',
                  onPressed: () => _confirmDeleteCondolence(c, p),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(c.text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmDeleteCondolence(CondolenceModel c, ObituaryProvider p) {
    ConfirmationDialog.show(
      context,
      title: 'Brisanje saučešća',
      content: 'Jeste li sigurni da želite obrisati saučešće od "${c.authorName}"?',
      onConfirm: () async {
        final ok = await p.deleteCondolence(c.id);
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Saučešće obrisano.'),
                backgroundColor: AppColors.success),
          );
        }
      },
    );
  }
}

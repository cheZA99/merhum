import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/obituary_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_widget.dart';

class ObituaryDetailScreen extends StatefulWidget {
  final String slug;
  const ObituaryDetailScreen({super.key, required this.slug});

  @override
  State<ObituaryDetailScreen> createState() => _ObituaryDetailScreenState();
}

class _ObituaryDetailScreenState extends State<ObituaryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObituaryProvider>().loadDetail(widget.slug);
    });
  }

  void _showCondolenceSheet() {
    final nameCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dodaj kondolenciju', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Vaše ime'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: textCtrl,
                  decoration: const InputDecoration(labelText: 'Kondolencija'),
                  maxLines: 4,
                  maxLength: 1000,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obavezno polje' : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: sending
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => sending = true);
                            final ok = await context.read<ObituaryProvider>().addCondolence(
                                  widget.slug,
                                  nameCtrl.text.trim(),
                                  textCtrl.text.trim(),
                                );
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok
                                  ? 'Kondolencija poslana, čeka odobrenje.'
                                  : 'Greška. Pokušajte ponovo.'),
                              backgroundColor: ok ? AppColors.success : AppColors.error,
                            ));
                          },
                    child: sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Pošalji'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smrtovnica'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final o = context.read<ObituaryProvider>().detail;
              if (o == null) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _SharePlaceholder(slug: o.uniqueSlug, name: o.deceasedFullName),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ObituaryProvider>(
        builder: (context, p, _) {
          if (p.isLoadingDetail) return const LoadingWidget();
          final o = p.detail;
          if (o == null) return LoadingWidget.error('Smrtovnica nije pronađena.', () => p.loadDetail(widget.slug));

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => p.loadDetail(widget.slug),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.primary,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                    child: Column(
                      children: [
                        _buildPhoto(o.photoUrl, 50),
                        const SizedBox(height: 12),
                        const Text('Rahmetli/Rahmetlija', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(o.deceasedFullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormatter.date(o.dateOfBirth)} — ${DateFormatter.date(o.dateOfDeath)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (o.dateOfBirth != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormatter.age(o.dateOfBirth!, o.dateOfDeath)} godina',
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (o.inMemoriam != null && o.inMemoriam!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            o.inMemoriam!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textMedium),
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_outlined, size: 16, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text('${o.viewCount} pregleda', style: AppTextStyles.caption),
                        const SizedBox(width: 16),
                        const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text('${o.condolenceCount} kondolencija', style: AppTextStyles.caption),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kondolencije (${p.condolences.length})', style: AppTextStyles.heading2),
                        const SizedBox(height: 12),
                        if (p.condolences.isEmpty) ...[
                          const Text('Još nema kondolencija.', style: AppTextStyles.bodyMedium),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _showCondolenceSheet,
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
                            child: const Text('Budite prvi'),
                          ),
                        ] else ...[
                          ...p.condolences.map((c) => Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(c.authorName, style: AppTextStyles.heading3),
                                          Text(DateFormatter.date(c.submittedAt), style: AppTextStyles.caption),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(c.text, style: AppTextStyles.body),
                                    ],
                                  ),
                                ),
                              )),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showCondolenceSheet,
                              icon: const Icon(Icons.add, color: AppColors.primary),
                              label: const Text('Dodaj kondolenciju', style: TextStyle(color: AppColors.primary)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoto(String? url, double radius) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(url),
        backgroundColor: Colors.white24,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      child: Icon(Icons.person, size: radius, color: Colors.white60),
    );
  }
}

class _SharePlaceholder extends StatelessWidget {
  final String slug;
  final String name;
  const _SharePlaceholder({required this.slug, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Podijeli smrtovnicu')),
      body: Center(child: Text('merhum.ba/$slug')),
    );
  }
}

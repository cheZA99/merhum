import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/obituary_model.dart';
import '../../utils/constants.dart';

class ShareObituaryScreen extends StatelessWidget {
  final ObituaryModel obituary;
  const ShareObituaryScreen({super.key, required this.obituary});

  String get _shareUrl => 'https://merhum.ba/smrtovnica/${obituary.uniqueSlug}';

  String get _shareText => 'Smrtovnica: ${obituary.deceasedFullName}\n$_shareUrl';

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aplikacija nije dostupna'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Podijeli smrtovnicu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(obituary.deceasedFullName, textAlign: TextAlign.center, style: AppTextStyles.heading1),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: QrImageView(
                      data: _shareUrl,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Link smrtovnice', style: AppTextStyles.captionBold),
                      const SizedBox(height: 6),
                      SelectableText(_shareUrl, style: AppTextStyles.body),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Podijeli putem:', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              _ShareBtn(
                icon: Icons.chat,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _launch(context, Uri.parse('whatsapp://send?text=${Uri.encodeComponent(_shareText)}')),
              ),
              _ShareBtn(
                icon: Icons.phone_in_talk,
                label: 'Viber',
                color: const Color(0xFF7360F2),
                onTap: () => _launch(context, Uri.parse('viber://forward?text=${Uri.encodeComponent(_shareText)}')),
              ),
              _ShareBtn(
                icon: Icons.email_outlined,
                label: 'Email',
                color: AppColors.primary,
                onTap: () => Share.share(_shareText, subject: 'Smrtovnica: ${obituary.deceasedFullName}'),
              ),
              _ShareBtn(
                icon: Icons.copy,
                label: 'Kopiraj link',
                color: AppColors.textMedium,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: _shareUrl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link kopiran'), backgroundColor: AppColors.success),
                    );
                  }
                },
              ),
              _ShareBtn(
                icon: Icons.share,
                label: 'Podijeli',
                color: AppColors.primary,
                onTap: () => Share.share(_shareText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ShareBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: color),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

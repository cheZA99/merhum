import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/constants.dart';
import 'grave_site_detail_screen.dart';
import 'obituary_detail_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    _handled = true;

    // the system generates two formats, an obituary link and a grave site link
    if (raw.contains('/smrtovnica/')) {
      final slug = raw.split('/smrtovnica/').last.split('?').first;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ObituaryDetailScreen(slug: slug)),
      );
      return;
    }

    final graveSiteId = _graveSiteIdFrom(raw);
    if (graveSiteId != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GraveSiteDetailScreen(graveSiteId: graveSiteId)),
      );
      return;
    }

    setState(() => _handled = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nepoznat QR kod'), backgroundColor: AppColors.warning),
    );
  }

  int? _graveSiteIdFrom(String raw) {
    final match = RegExp(r'/api/gravesite/(\d+)', caseSensitive: false).firstMatch(raw);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(controller: _ctrl, onDetect: _onDetect),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Skeniraj QR kod',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryLight, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/grave_site_model.dart';
import '../../services/grave_site_service.dart';
import '../../utils/api_error.dart';
import '../../utils/constants.dart';

class GraveSiteDetailScreen extends StatefulWidget {
  final int graveSiteId;

  const GraveSiteDetailScreen({super.key, required this.graveSiteId});

  @override
  State<GraveSiteDetailScreen> createState() => _GraveSiteDetailScreenState();
}

class _GraveSiteDetailScreenState extends State<GraveSiteDetailScreen> {
  GraveSiteModel? _site;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final site = await GraveSiteService.getById(widget.graveSiteId);
      if (!mounted) return;
      setState(() {
        _site = site;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = parseApiError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mezarsko mjesto')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Pokušaj ponovo')),
            ],
          ),
        ),
      );
    }

    final site = _site!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (site.deceasedFullName != null) ...[
            Text(site.deceasedFullName!, style: AppTextStyles.heading1),
            const SizedBox(height: 20),
          ],
          _row('Mezarje', site.cemeteryName),
          _row('Broj mjesta', site.plotNumber),
          if (site.sectionName != null) _row('Sektor', site.sectionName!),
          if (site.row != null) _row('Red', site.row.toString()),
          if (site.latitude != null && site.longitude != null)
            _row('Koordinate', '${site.latitude!.toStringAsFixed(5)}, ${site.longitude!.toStringAsFixed(5)}'),
          if (site.deceasedFullName == null) ...[
            const SizedBox(height: 20),
            const Text('Na ovom mjestu nema evidentiranog ukopa.', style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(label, style: AppTextStyles.captionBold)),
            Expanded(child: Text(value, style: AppTextStyles.body)),
          ],
        ),
      );
}

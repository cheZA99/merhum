import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/cemetery_model.dart';
import '../models/grave_site_model.dart';
import '../utils/constants.dart';
import '../utils/status_helper.dart';

class CemeteryMapWidget extends StatefulWidget {
  final CemeteryModel? cemetery;
  final List<GraveSiteModel> sites;
  final void Function(GraveSiteModel)? onMarkerTap;

  const CemeteryMapWidget({
    super.key,
    required this.cemetery,
    required this.sites,
    this.onMarkerTap,
  });

  @override
  State<CemeteryMapWidget> createState() => _CemeteryMapWidgetState();
}

class _CemeteryMapWidgetState extends State<CemeteryMapWidget> {
  final MapController _mapController = MapController();
  GraveSiteModel? _selected;

  @override
  void didUpdateWidget(CemeteryMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-centre the map when the selected cemetery changes
    if (widget.cemetery?.id != oldWidget.cemetery?.id) {
      _selected = null;
      final center = _getCenter();
      if (center != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(center, 17);
        });
      }
    }
  }

  LatLng? _getCenter() {
    final g = widget.cemetery;
    final lat = g?.latitude;
    final lng = g?.longitude;
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    // Fallback: centre of Bosnia
    return const LatLng(44.0, 17.5);
  }

  @override
  Widget build(BuildContext context) {
    final center = _getCenter() ?? const LatLng(44.0, 17.5);
    final hasCemeteryCoords = widget.cemetery?.latitude != null;

    // Keep only sites that have coordinates
    final mapSites = widget.sites
        .where((m) => m.latitude != null && m.longitude != null)
        .toList();

    return Column(
      children: [
        if (!hasCemeteryCoords)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.amber.shade100,
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Groblje nema unesene GPS koordinate. '
                  'Dodajte ih u formi za uređivanje groblja.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: hasCemeteryCoords ? 17 : 8,
              maxZoom: 20,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ba.merhum.desktop',
              ),
              if (hasCemeteryCoords)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: const Tooltip(
                        message: 'Centar groblja',
                        child: Icon(Icons.location_on,
                            color: AppColors.primary, size: 36),
                      ),
                    ),
                  ],
                ),
              if (mapSites.isNotEmpty)
                MarkerLayer(
                  markers: mapSites.map((m) {
                    final color = GraveSiteStatus.color(m.status);
                    final isSelected = _selected?.id == m.id;
                    return Marker(
                      point: LatLng(m.latitude!, m.longitude!),
                      width: isSelected ? 36 : 24,
                      height: isSelected ? 36 : 24,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selected = m);
                          widget.onMarkerTap?.call(m);
                        },
                        child: Tooltip(
                          message: m.deceasedName != null
                              ? '${m.plotNumber} - ${m.deceasedName}'
                              : m.plotNumber,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        if (_selected != null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _statusDot(_selected!.status),
                const SizedBox(width: 8),
                Text('Mjesto: ${_selected!.plotNumber}',
                    style: AppTextStyles.body),
                if (_selected!.deceasedName != null) ...[
                  const SizedBox(width: 16),
                  Text('Preminuli: ${_selected!.deceasedName}',
                      style: AppTextStyles.body),
                ],
                if (_selected!.sectorName != null) ...[
                  const SizedBox(width: 16),
                  Text('Sektor: ${_selected!.sectorName}',
                      style: AppTextStyles.caption),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _selected = null),
                  child: const Text('Zatvori'),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(AppColors.success, 'Slobodno'),
              const SizedBox(width: 24),
              _legendItem(AppColors.error, 'Zauzeto'),
              const SizedBox(width: 24),
              _legendItem(Colors.orange, 'Rezervisano'),
              const SizedBox(width: 24),
              const Icon(Icons.info_outline, size: 12,
                  color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                mapSites.isEmpty
                    ? 'Mezarska mjesta nemaju GPS koordinate'
                    : '${mapSites.length} mjesta prikazano na mapi',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusDot(String apiStatus) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: GraveSiteStatus.color(apiStatus),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

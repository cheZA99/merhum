import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';

/// Lets the user place a pin on a map instead of typing coordinates by hand.
class LocationPickerField extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final void Function(double latitude, double longitude) onChanged;
  final String label;

  const LocationPickerField({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onChanged,
    this.label = 'Lokacija',
  });

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  final MapController _mapController = MapController();

  // roughly the centre of Bosnia and Herzegovina, used until a pin is placed
  static const LatLng _fallbackCentre = LatLng(43.9159, 17.6791);

  LatLng? get _pin {
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  void _onTap(TapPosition _, LatLng point) {
    widget.onChanged(point.latitude, point.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final pin = _pin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.body),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 260,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: pin ?? _fallbackCentre,
                initialZoom: pin != null ? 16 : 7,
                maxZoom: 20,
                onTap: _onTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ba.merhum.desktop',
                ),
                if (pin != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pin,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.place, color: AppColors.error, size: 40),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.touch_app_outlined, size: 16, color: AppColors.textLight),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                pin == null
                    ? 'Kliknite na mapu da označite lokaciju.'
                    : 'Označeno: ${pin.latitude.toStringAsFixed(6)}, ${pin.longitude.toStringAsFixed(6)}',
                style: AppTextStyles.caption,
              ),
            ),
            if (pin != null)
              TextButton(
                onPressed: () => _mapController.move(pin, 17),
                child: const Text('Centriraj'),
              ),
          ],
        ),
      ],
    );
  }
}

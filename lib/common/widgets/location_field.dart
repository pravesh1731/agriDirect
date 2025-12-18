import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../utils/google_keys.dart';

// A location field that allows using current device location or searching via Google Places Autocomplete.
class LocationField extends StatefulWidget {
  const LocationField({super.key, required this.controller, this.onSelected});

  final TextEditingController controller;
  final void Function(String address, double? lat, double? lng)? onSelected;

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  final Dio _dio = Dio();
  bool _locating = false;

  Future<void> _useCurrentLocation() async {
    try {
      setState(() => _locating = true);
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied')));
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final placemarks = await geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final rawParts = [place?.name, place?.locality, place?.administrativeArea, place?.country];
      final parts = rawParts.where((e) => (e ?? '').toString().isNotEmpty).map((e) => (e ?? '').toString()).toList();
      final address = parts.join(', ');
      widget.controller.text = address;
      widget.onSelected?.call(address, position.latitude, position.longitude);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openSearch() async {
    final prediction = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PlacesSearchSheet(dio: _dio),
    );

    if (prediction != null) {
      final placeId = prediction['place_id'] as String?;
      final description = prediction['description'] as String? ?? '';
      double? lat, lng;
      if (placeId != null && placeId.isNotEmpty) {
        try {
          final res = await _dio.get('https://maps.googleapis.com/maps/api/place/details/json', queryParameters: {
            'place_id': placeId,
            'key': kGoogleApiKey,
            'fields': 'formatted_address,geometry',
          });
          final data = res.data;
          final result = data['result'];
          final formatted = result['formatted_address'] as String?;
          final loc = result['geometry']?['location'];
          lat = loc?['lat'] != null ? (loc['lat'] as num).toDouble() : null;
          lng = loc?['lng'] != null ? (loc['lng'] as num).toDouble() : null;
          final address = formatted ?? description;
          widget.controller.text = address;
          widget.onSelected?.call(address, lat, lng);
        } catch (e) {
          // fallback to description only
          widget.controller.text = description;
          widget.onSelected?.call(description, null, null);
        }
      } else {
        widget.controller.text = description;
        widget.onSelected?.call(description, null, null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      readOnly: true,
      onTap: _openSearch,
      decoration: InputDecoration(
        hintText: 'Enter your location',
        prefixIcon: const Icon(Icons.location_on_outlined),
        suffixIcon: _locating
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : IconButton(
                icon: const Icon(Icons.gps_fixed),
                onPressed: _useCurrentLocation,
              ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _PlacesSearchSheet extends StatefulWidget {
  const _PlacesSearchSheet({required this.dio});
  final Dio dio;

  @override
  State<_PlacesSearchSheet> createState() => _PlacesSearchSheetState();
}

class _PlacesSearchSheetState extends State<_PlacesSearchSheet> {
  final TextEditingController _search = TextEditingController();
  List<Map<String, dynamic>> _predictions = [];
  bool _loading = false;

  Future<void> _onQueryChanged(String q) async {
    if (q.isEmpty) {
      setState(() { _predictions = []; });
      return;
    }
    setState(() { _loading = true; });
    try {
      final res = await widget.dio.get('https://maps.googleapis.com/maps/api/place/autocomplete/json', queryParameters: {
        'input': q,
        'key': kGoogleApiKey,
        'language': 'en',
        'types': '(regions)'
      });
      final data = res.data;
      final preds = (data['predictions'] as List<dynamic>?)?.map((p) => Map<String, dynamic>.from(p as Map)).toList() ?? [];
      setState(() { _predictions = preds; _loading = false; });
    } catch (e) {
      setState(() { _predictions = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(hintText: 'Search location', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                onChanged: (v) => _onQueryChanged(v),
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final p = _predictions[index];
                  return ListTile(
                    title: Text(p['description'] ?? ''),
                    onTap: () => Navigator.of(context).pop(p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/nearby/screens/nearby_screen.dart
//
// Features:
//  ✅ Real Google Map with custom-hue markers
//  ✅ GPS distance calculated live from user location
//  ✅ Loads artisans from Supabase (artisans table)
//  ✅ Search bar (name + region)
//  ✅ Directions button (opens Google Maps)
//  ✅ Shows profile photo + heritage story in detail card

import 'dart:math' show sqrt, sin, cos, atan2, pi;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Colours ───────────────────────────────────────────────────────────────────

const _kCream    = Color(0xFFF5F0E8);
const _kPin      = Color(0xFF8B3A2A);
const _kText     = Color(0xFF2C1A0E);
const _kSubText  = Color(0xFF7A6651);
const _kTag      = Color(0xFFEDE3D0);
const _kSelected = Color(0xFF8B3A2A);

// ─── Data Model ────────────────────────────────────────────────────────────────

class ArtisanLocation {
  final String id;
  final String name;
  final String? region;       // used as "city" label
  final String? heritageStory;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final double lat;
  final double lng;

  double? distanceKm; // computed after GPS fix

  ArtisanLocation({
    required this.id,
    required this.name,
    this.region,
    this.heritageStory,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    required this.lat,
    required this.lng,
    this.distanceKm,
  });

  LatLng get latLng => LatLng(lat, lng);

  factory ArtisanLocation.fromMap(Map<String, dynamic> m) => ArtisanLocation(
        id: m['id'].toString(),
        name: m['name'] as String? ?? '',
        region: m['region'] as String?,
        heritageStory: m['heritage_story'] as String?,
        profilePhotoUrl: m['profile_photo_url'] as String?,
        coverPhotoUrl: m['cover_photo_url'] as String?,
        lat: (m['latitude'] as num?)?.toDouble() ?? 0,
        lng: (m['longitude'] as num?)?.toDouble() ?? 0,
      );
}

// ─── Fallback data (shown while loading or on error) ──────────────────────────

final _kFallback = <ArtisanLocation>[
  ArtisanLocation(
    id: 'f1', name: 'Srey Neang Silk Weaving',
    region: 'Preah Dak, Siem Reap',
    heritageStory: 'Practicing the ancient art of Khmer silk weaving.',
    lat: 13.3633, lng: 103.8564,
  ),
  ArtisanLocation(
    id: 'f2', name: 'Sopheap Clay Ceramics',
    region: 'Kampong Chhnang',
    heritageStory: 'Molding traditional unglazed pottery by hand.',
    lat: 12.2500, lng: 104.6667,
  ),
];

// ─── Haversine distance ────────────────────────────────────────────────────────

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// ─── Riverpod providers ────────────────────────────────────────────────────────

/// Fetches all artisans that have GPS coordinates set.
final _artisansProvider = FutureProvider<List<ArtisanLocation>>((ref) async {
  try {
    final rows = await Supabase.instance.client
        .from('artisans')
        .select('id, name, region, heritage_story, profile_photo_url, cover_photo_url, latitude, longitude')
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)
        .order('name');
    return (rows as List).map((r) => ArtisanLocation.fromMap(r)).toList();
  } catch (e) {
    // Fall back to seed data so the screen is never blank
    return _kFallback;
  }
});

/// Current GPS position of the user.
class _UserLocationNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;

  void set(LatLng latLng) => state = latLng;
}

final _userLocationProvider =
    NotifierProvider<_UserLocationNotifier, LatLng?>(_UserLocationNotifier.new);

// ─── Screen ────────────────────────────────────────────────────────────────────

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  int _selectedIndex = 0;
  GoogleMapController? _mapController;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _defaultCamera = CameraPosition(
    target: LatLng(12.5657, 104.9910),
    zoom: 6.5,
  );

  @override
  void initState() {
    super.initState();
    _initLocation();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
        _selectedIndex = 0;
      });
    });
  }

  // ── Location ────────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final latLng = LatLng(pos.latitude, pos.longitude);
    ref.read(_userLocationProvider.notifier).set(latLng);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 7.0));
  }

  // ── Filter + sort ────────────────────────────────────────────────────────────

  List<ArtisanLocation> _process(List<ArtisanLocation> raw, LatLng? userPos) {
    // Compute distances
    for (final a in raw) {
      if (userPos != null) {
        a.distanceKm = _haversineKm(
            userPos.latitude, userPos.longitude, a.lat, a.lng);
      }
    }

    var list = raw.where((a) {
      if (_searchQuery.isEmpty) return true;
      final hay = '${a.name} ${a.region ?? ''}'.toLowerCase();
      return hay.contains(_searchQuery);
    }).toList();

    list.sort((a, b) => userPos != null
        ? (a.distanceKm ?? 9999).compareTo(b.distanceKm ?? 9999)
        : a.name.compareTo(b.name));

    return list;
  }

  // ── Markers ──────────────────────────────────────────────────────────────────

  Set<Marker> _buildMarkers(List<ArtisanLocation> list, LatLng? userPos) {
    return {
      if (userPos != null)
        Marker(
          markerId: const MarkerId('user'),
          position: userPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      ...list.asMap().entries.map((e) {
        final i = e.key;
        final a = e.value;
        return Marker(
          markerId: MarkerId('artisan_${a.id}'),
          position: a.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: a.name, snippet: a.region),
          onTap: () {
            setState(() => _selectedIndex = i);
            _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(a.latLng, 13.0));
          },
        );
      }),
    };
  }

  void _selectArtisan(int i, ArtisanLocation a) {
    setState(() => _selectedIndex = i);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(a.latLng, 13.0));
  }

  Future<void> _openDirections(ArtisanLocation a) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${a.lat},${a.lng}&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final async   = ref.watch(_artisansProvider);
    final userPos = ref.watch(_userLocationProvider);

    return async.when(
      loading: () => const Scaffold(
        backgroundColor: _kCream,
        body: Center(child: CircularProgressIndicator(color: _kPin)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _kCream,
        body: Center(child: Text('Error: $e')),
      ),
      data: (raw) {
        final artisans = _process(raw, userPos);
        final safeIdx  = _selectedIndex.clamp(0, (artisans.length - 1).clamp(0, 9999));
        final selected = artisans.isNotEmpty ? artisans[safeIdx] : null;

        return Scaffold(
          backgroundColor: _kCream,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DISCOVER',
                            style: TextStyle(
                                fontSize: 11, letterSpacing: 2.5, color: _kSubText)),
                        const SizedBox(height: 4),
                        Text('Nearby artisans',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w700,
                                color: _kText, fontFamily: 'Georgia')),
                        const SizedBox(height: 4),
                        Text('Tap a pin or card to explore.',
                            style: TextStyle(fontSize: 13, color: _kSubText)),
                      ],
                    ),
                  ),

                  // ── Search bar ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: _kText, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by name or region…',
                        hintStyle: TextStyle(color: _kSubText, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: _kSubText, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, color: _kSubText, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Google Map (mobile only) ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 280,
                        child: kIsWeb
                            ? _WebMapPlaceholder(artisans: artisans)
                            : GoogleMap(
                                initialCameraPosition: _defaultCamera,
                                markers: _buildMarkers(artisans, userPos),
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: false,
                                mapToolbarEnabled: false,
                                onMapCreated: (c) {
                                  _mapController = c;
                                  if (userPos != null) {
                                    c.animateCamera(
                                        CameraUpdate.newLatLngZoom(userPos, 7.0));
                                  }
                                },
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Detail card ───────────────────────────────────────────
                  if (selected != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _DetailCard(
                        artisan: selected,
                        onDirections: () => _openDirections(selected),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── List header ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          userPos != null
                              ? 'SORTED BY DISTANCE'
                              : 'SORTED BY NAME',
                          style: TextStyle(
                              fontSize: 11, letterSpacing: 2.2, color: _kSubText),
                        ),
                        const Spacer(),
                        Text('${artisans.length} artisans',
                            style: TextStyle(fontSize: 11, color: _kSubText)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── List ──────────────────────────────────────────────────
                  if (artisans.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('No artisans match your search.',
                            style: TextStyle(color: _kSubText)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: artisans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ArtisanListTile(
                        artisan: artisans[i],
                        isSelected: i == safeIdx,
                        onTap: () => _selectArtisan(i, artisans[i]),
                      ),
                    ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// ─── Detail Card ───────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final ArtisanLocation artisan;
  final VoidCallback onDirections;

  const _DetailCard({required this.artisan, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover photo or placeholder
          if (artisan.coverPhotoUrl != null)
            Image.network(
              artisan.coverPhotoUrl!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            )
          else
            Container(
              height: 80,
              color: _kTag,
              child: Center(
                child: Icon(Icons.store_outlined, color: _kPin, size: 36),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + name row
                Row(
                  children: [
                    if (artisan.profilePhotoUrl != null)
                      ClipOval(
                        child: Image.network(
                          artisan.profilePhotoUrl!,
                          width: 44, height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                        ),
                      )
                    else
                      _avatarPlaceholder(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artisan.name,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _kText,
                                fontFamily: 'Georgia'),
                          ),
                          if (artisan.region != null)
                            Text(artisan.region!,
                                style: TextStyle(
                                    fontSize: 12, color: _kPin,
                                    fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (artisan.distanceKm != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kTag,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${artisan.distanceKm!.toStringAsFixed(1)} km',
                          style: TextStyle(
                              fontSize: 12,
                              color: _kPin,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),

                // Heritage story
                if (artisan.heritageStory != null &&
                    artisan.heritageStory!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    artisan.heritageStory!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: _kSubText,
                        height: 1.5),
                  ),
                ],

                const SizedBox(height: 16),

                // Directions button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions_outlined, size: 18),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPin,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() => Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
            color: _kTag, shape: BoxShape.circle),
        child: Icon(Icons.person_outline, color: _kPin, size: 22),
      );
}

// ─── List Tile ─────────────────────────────────────────────────────────────────

class _ArtisanListTile extends StatelessWidget {
  final ArtisanLocation artisan;
  final bool isSelected;
  final VoidCallback onTap;

  const _ArtisanListTile({
    required this.artisan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _kSelected : Colors.transparent,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            ClipOval(
              child: artisan.profilePhotoUrl != null
                  ? Image.network(
                      artisan.profilePhotoUrl!,
                      width: 40, height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(artisan.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  const SizedBox(height: 2),
                  Text(artisan.region ?? '—',
                      style: TextStyle(fontSize: 12, color: _kSubText)),
                ],
              ),
            ),
            if (artisan.distanceKm != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kTag,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${artisan.distanceKm!.toStringAsFixed(1)} km',
                  style: TextStyle(
                      fontSize: 12, color: _kPin, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 40, height: 40,
        color: _kTag,
        child: Icon(Icons.person_outline, color: _kPin, size: 20),
      );
}

// ─── Web Map Placeholder ───────────────────────────────────────────────────────
// google_maps_flutter doesn't support web. On web we show a styled card
// with quick-links to open each artisan in Google Maps.

class _WebMapPlaceholder extends StatelessWidget {
  final List<ArtisanLocation> artisans;
  const _WebMapPlaceholder({required this.artisans});

  Future<void> _openMap(ArtisanLocation a) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${a.lat},${a.lng}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kTag,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 36, color: _kPin),
          const SizedBox(height: 8),
          Text(
            'Interactive map available on mobile',
            style: TextStyle(
                fontSize: 13, color: _kText, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Open an artisan directly in Google Maps:',
            style: TextStyle(fontSize: 12, color: _kSubText),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: artisans.take(5).map((a) {
              return GestureDetector(
                onTap: () => _openMap(a),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kPin.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new, size: 12, color: _kPin),
                      const SizedBox(width: 4),
                      Text(a.name,
                          style: TextStyle(
                              fontSize: 12,
                              color: _kPin,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
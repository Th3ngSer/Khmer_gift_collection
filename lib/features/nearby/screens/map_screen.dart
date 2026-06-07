// lib/features/nearby/screens/map_screen.dart
//
// Screen 6 — Unified Map + Nearby
// ✅ Full-screen Google Map: all artisan pins (red) + pickup points (green)
// ✅ Tap pin → bottom sheet (photo, story, distance, directions, view profile)
// ✅ Filter chips: All / Workshops / Pickup Points
// ✅ "Nearby" toggle → shows only pins within 50 km + zooms in
// ✅ Recenter FAB + Legend overlay
// ✅ Nearby list panel slides up when toggle is active
// ✅ Web fallback

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:khmer_gift_collection/features/nearby/providers/artisan_location_providers.dart';

const _kNearbyRadiusKm = 50.0;

// ─── Screen ────────────────────────────────────────────────────────────────────

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapCtrl;
  PinType? _filter;        // null = All
  bool _nearbyMode = false; // 50 km toggle

  late final AnimationController _panelCtrl;
  late final Animation<Offset> _panelSlide;

  static const _cambodiaCamera = CameraPosition(
    target: LatLng(12.5657, 104.9910),
    zoom: 6.8,
  );

  @override
  void initState() {
    super.initState();
    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOut));
    _initLocation();
  }

  // ── GPS ─────────────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return;
    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final ll = LatLng(pos.latitude, pos.longitude);
    ref.read(userLocationProvider.notifier).set(ll);
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 8.0));
  }

  void _recenter() {
    final pos = ref.read(userLocationProvider);
    if (pos != null) {
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(
          pos, _nearbyMode ? 11.0 : 9.0));
    } else {
      _mapCtrl
          ?.animateCamera(CameraUpdate.newCameraPosition(_cambodiaCamera));
    }
  }

  // ── Nearby toggle ────────────────────────────────────────────────────────────

  void _toggleNearby(List<ArtisanLocation> all, LatLng? userPos) {
    setState(() => _nearbyMode = !_nearbyMode);
    if (_nearbyMode) {
      _panelCtrl.forward();
      if (userPos != null) {
        _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(userPos, 11.0));
      }
    } else {
      _panelCtrl.reverse();
      _mapCtrl?.animateCamera(
          CameraUpdate.newCameraPosition(_cambodiaCamera));
    }
  }

  // ── Filtering ────────────────────────────────────────────────────────────────

  List<ArtisanLocation> _visibleLocations(
      List<ArtisanLocation> all, LatLng? userPos) {
    // Compute distances for all
    for (final a in all) {
      if (userPos != null) {
        a.distanceKm =
            haversineKm(userPos.latitude, userPos.longitude, a.lat, a.lng);
      }
    }

    var list = all.where((a) {
      if (_filter != null && a.pinType != _filter) return false;
      if (_nearbyMode && (a.distanceKm == null || a.distanceKm! > _kNearbyRadiusKm)) {
        return false;
      }
      return true;
    }).toList();

    if (_nearbyMode) {
      list.sort((a, b) =>
          (a.distanceKm ?? 9999).compareTo(b.distanceKm ?? 9999));
    }
    return list;
  }

  // ── Pin tap ──────────────────────────────────────────────────────────────────

  void _onPinTapped(ArtisanLocation a) {
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(a.latLng, 13.0));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ArtisanBottomSheet(artisan: a),
    );
  }

  // ── Markers ──────────────────────────────────────────────────────────────────

  Set<Marker> _markers(List<ArtisanLocation> visible, LatLng? userPos) =>
      buildMapMarkers(
        locations: visible,
        userPos: userPos,
        onTap: _onPinTapped,
      );

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final async   = ref.watch(artisansProvider);
    final userPos = ref.watch(userLocationProvider);

    if (kIsWeb) {
      return async.when(
        loading: () => const Scaffold(
            backgroundColor: kMapCream,
            body: Center(child: CircularProgressIndicator(color: kMapPin))),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        data: (list) => _WebFallback(locations: list),
      );
    }

    return Scaffold(
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kMapPin)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final visible = _visibleLocations(all, userPos);
          final nearbyList = _nearbyMode ? visible : [];

          return Stack(
            children: [

              // ── Full-screen map ──────────────────────────────────────────
              GoogleMap(
                initialCameraPosition: _cambodiaCamera,
                markers: _markers(visible, userPos),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (c) {
                  _mapCtrl = c;
                  if (userPos != null) {
                    c.animateCamera(CameraUpdate.newLatLngZoom(userPos, 8.0));
                  }
                },
              ),

              // ── Top overlay ──────────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Title bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.map_outlined,
                                color: kMapPin, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nearbyMode
                                    ? 'Nearby (${_kNearbyRadiusKm.toInt()} km)'
                                    : 'Artisan Map',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: kMapText,
                                    fontFamily: 'Georgia'),
                              ),
                            ),
                            Text(
                              '${visible.length} shown',
                              style: TextStyle(
                                  fontSize: 12, color: kMapSubText),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Filter chips + Nearby toggle
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Type filters
                            _Chip(
                              label: 'All',
                              active: _filter == null,
                              color: kMapPin,
                              onTap: () =>
                                  setState(() => _filter = null),
                            ),
                            const SizedBox(width: 8),
                            _Chip(
                              label: 'Workshops',
                              icon: Icons.store_outlined,
                              active: _filter == PinType.artisan,
                              color: kMapPin,
                              onTap: () => setState(() => _filter =
                                  _filter == PinType.artisan
                                      ? null
                                      : PinType.artisan),
                            ),
                            const SizedBox(width: 8),
                            _Chip(
                              label: 'Pickup',
                              icon: Icons.local_shipping_outlined,
                              active: _filter == PinType.pickup,
                              color: kMapPickup,
                              onTap: () => setState(() => _filter =
                                  _filter == PinType.pickup
                                      ? null
                                      : PinType.pickup),
                            ),

                            // Divider
                            Container(
                              height: 24,
                              width: 1,
                              color: Colors.white.withOpacity(0.6),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10),
                            ),

                            // Nearby toggle
                            _NearbyToggle(
                              active: _nearbyMode,
                              hasGps: userPos != null,
                              onTap: userPos != null
                                  ? () => _toggleNearby(all, userPos)
                                  : () => ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Enable location to use Nearby'),
                                        duration: Duration(seconds: 2),
                                      )),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Legend ────────────────────────────────────────────────────
              Positioned(
                bottom: _nearbyMode ? 320 : 100,
                left: 16,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _LegendRow(
                          color: kMapPin, label: 'Artisan Workshop'),
                      SizedBox(height: 4),
                      _LegendRow(
                          color: kMapPickup, label: 'Pickup Point'),
                    ],
                  ),
                ),
              ),

              // ── Recenter FAB ──────────────────────────────────────────────
              Positioned(
                bottom: _nearbyMode ? 320 : 100,
                right: 16,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: FloatingActionButton.small(
                    heroTag: 'recenter',
                    backgroundColor: Colors.white,
                    foregroundColor: kMapPin,
                    elevation: 4,
                    onPressed: _recenter,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ),

              // ── Nearby panel (slides up from bottom) ──────────────────────
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: SlideTransition(
                  position: _panelSlide,
                  child: _NearbyPanel(
                    locations: nearbyList as List<ArtisanLocation>,
                    onTap: (a) {
                      _mapCtrl?.animateCamera(
                          CameraUpdate.newLatLngZoom(a.latLng, 14.0));
                      _onPinTapped(a);
                    },
                    onClose: () => _toggleNearby(all, userPos),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    _panelCtrl.dispose();
    super.dispose();
  }
}

// ─── Nearby toggle button ───────────────────────────────────────────────────────

class _NearbyToggle extends StatelessWidget {
  final bool active;
  final bool hasGps;
  final VoidCallback onTap;

  const _NearbyToggle({
    required this.active,
    required this.hasGps,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? kMapGold : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.near_me,
              size: 14,
              color: active
                  ? Colors.white
                  : (hasGps ? kMapGold : kMapSubText),
            ),
            const SizedBox(width: 5),
            Text(
              'Nearby 50km',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active
                    ? Colors.white
                    : (hasGps ? kMapText : kMapSubText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nearby panel ───────────────────────────────────────────────────────────────

class _NearbyPanel extends StatelessWidget {
  final List<ArtisanLocation> locations;
  final void Function(ArtisanLocation) onTap;
  final VoidCallback onClose;

  const _NearbyPanel({
    required this.locations,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 16,
              offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
                Expanded(
                  child: Text(
                    locations.isEmpty
                        ? 'No locations within 50 km'
                        : '${locations.length} within 50 km',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kMapText),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: kMapSubText, size: 20),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: locations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_outlined,
                            color: kMapSubText, size: 36),
                        const SizedBox(height: 8),
                        Text('No artisans or pickup points nearby.',
                            style:
                                TextStyle(color: kMapSubText, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: locations.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final a = locations[i];
                      final isPickup = a.pinType == PinType.pickup;
                      final accent =
                          isPickup ? kMapPickup : kMapPin;
                      return GestureDetector(
                        onTap: () => onTap(a),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: kMapCream,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              ClipOval(
                                child: a.profilePhotoUrl != null
                                    ? Image.network(
                                        a.profilePhotoUrl!,
                                        width: 40, height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _avatar(accent, isPickup),
                                      )
                                    : _avatar(accent, isPickup),
                              ),
                              const SizedBox(width: 10),
                              // Name + region
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(a.name,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: kMapText)),
                                    Text(
                                      a.region ?? '',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: kMapSubText),
                                    ),
                                  ],
                                ),
                              ),
                              // Distance badge
                              if (a.distanceKm != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${a.distanceKm!.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: accent,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right,
                                  color: kMapSubText, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(Color color, bool isPickup) => Container(
        width: 40, height: 40,
        color: kMapTag,
        child: Icon(
          isPickup ? Icons.local_shipping_outlined : Icons.store_outlined,
          color: color, size: 18,
        ),
      );
}

// ─── Filter chip ────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14,
                  color: active ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : kMapText)),
          ],
        ),
      ),
    );
  }
}

// ─── Legend row ─────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10, height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: kMapText,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Bottom sheet ───────────────────────────────────────────────────────────────

class _ArtisanBottomSheet extends StatelessWidget {
  final ArtisanLocation artisan;
  const _ArtisanBottomSheet({required this.artisan});

  Future<void> _openDirections() async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${artisan.lat},${artisan.lng}&travelmode=driving');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = artisan.pinType == PinType.pickup;
    final accent   = isPickup ? kMapPickup : kMapPin;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),

            if (artisan.coverPhotoUrl != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    artisan.coverPhotoUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPickup
                              ? Icons.local_shipping_outlined
                              : Icons.store_outlined,
                          size: 12, color: accent),
                        const SizedBox(width: 4),
                        Text(artisan.typeLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color: accent,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      if (artisan.profilePhotoUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipOval(
                            child: Image.network(
                              artisan.profilePhotoUrl!,
                              width: 50, height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarWidget(accent),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _avatarWidget(accent),
                        ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(artisan.name,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: kMapText,
                                    fontFamily: 'Georgia')),
                            if (artisan.region != null)
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 13, color: accent),
                                  const SizedBox(width: 2),
                                  Text(artisan.region!,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: accent,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                          ],
                        ),
                      ),

                      if (artisan.distanceKm != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              artisan.distanceKm!.toStringAsFixed(1),
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: accent),
                            ),
                            Text('km away',
                                style: TextStyle(
                                    fontSize: 11, color: kMapSubText)),
                          ],
                        ),
                    ],
                  ),

                  if (artisan.heritageStory != null &&
                      artisan.heritageStory!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      artisan.heritageStory!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          color: kMapSubText,
                          height: 1.6),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openDirections,
                          icon: const Icon(Icons.directions_outlined,
                              size: 16),
                          label: const Text('Directions'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            side: BorderSide(color: accent),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (!isPickup) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // context.push('/artisans/${artisan.id}');
                            },
                            icon: const Icon(Icons.person_outline,
                                size: 16),
                            label: const Text('View Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kMapPin,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarWidget(Color color) => Container(
        width: 50, height: 50,
        decoration:
            BoxDecoration(color: kMapTag, shape: BoxShape.circle),
        child:
            Icon(Icons.store_outlined, color: color, size: 24),
      );
}

// ─── Web fallback ───────────────────────────────────────────────────────────────

class _WebFallback extends StatelessWidget {
  final List<ArtisanLocation> locations;
  const _WebFallback({required this.locations});

  Future<void> _open(ArtisanLocation a) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${a.lat},${a.lng}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMapCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text('Artisan Map',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: kMapText,
                      fontFamily: 'Georgia')),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: locations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final a = locations[i];
                  final isPickup = a.pinType == PinType.pickup;
                  return ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    leading: Icon(
                      isPickup
                          ? Icons.local_shipping_outlined
                          : Icons.store_outlined,
                      color: isPickup ? kMapPickup : kMapPin,
                    ),
                    title: Text(a.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: kMapText)),
                    subtitle: Text(a.region ?? '',
                        style: TextStyle(color: kMapSubText)),
                    trailing: const Icon(Icons.open_in_new,
                        size: 16, color: kMapSubText),
                    onTap: () => _open(a),
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
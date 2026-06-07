import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:khmer_gift_collection/features/nearby/providers/artisan_location_providers.dart';

// ─── Screen ────────────────────────────────────────────────────────────────────

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  int _selectedIndex = 0;
  GoogleMapController? _mapCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';
  PinType? _filter; // null = all

  static const _defaultCamera = CameraPosition(
    target: LatLng(12.5657, 104.9910),
    zoom: 6.5,
  );

  @override
  void initState() {
    super.initState();
    _initLocation();
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text.toLowerCase().trim();
        _selectedIndex = 0;
      });
    });
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
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 7.0));
  }

  // ── Filter + sort ────────────────────────────────────────────────────────────

  List<ArtisanLocation> _process(
      List<ArtisanLocation> raw, LatLng? userPos) {
    for (final a in raw) {
      if (userPos != null) {
        a.distanceKm = haversineKm(
            userPos.latitude, userPos.longitude, a.lat, a.lng);
      }
    }
    var list = raw.where((a) {
      if (_filter != null && a.pinType != _filter) return false;
      if (_query.isEmpty) return true;
      return '${a.name} ${a.region ?? ''}'.toLowerCase().contains(_query);
    }).toList();

    list.sort((a, b) => userPos != null
        ? (a.distanceKm ?? 9999).compareTo(b.distanceKm ?? 9999)
        : a.name.compareTo(b.name));
    return list;
  }

  void _selectLocation(int i, ArtisanLocation a) {
    setState(() => _selectedIndex = i);
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(a.latLng, 13.0));
  }

  Future<void> _openDirections(ArtisanLocation a) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${a.lat},${a.lng}&travelmode=driving');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final async   = ref.watch(artisansProvider);
    final userPos = ref.watch(userLocationProvider);

    return async.when(
      loading: () => const Scaffold(
          backgroundColor: kMapCream,
          body: Center(child: CircularProgressIndicator(color: kMapPin))),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
      data: (raw) {
        final list     = _process(raw, userPos);
        final safeIdx  = _selectedIndex.clamp(0, (list.length - 1).clamp(0, 9999));
        final selected = list.isNotEmpty ? list[safeIdx] : null;

        return Scaffold(
          backgroundColor: kMapCream,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DISCOVER',
                            style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 2.5,
                                color: kMapSubText)),
                        const SizedBox(height: 4),
                        Text('Nearby',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: kMapText,
                                fontFamily: 'Georgia')),
                        const SizedBox(height: 4),
                        Text('Artisan workshops & pickup points near you.',
                            style:
                                TextStyle(fontSize: 13, color: kMapSubText)),
                      ],
                    ),
                  ),

                  // ── Search bar ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchCtrl,
                      style:
                          TextStyle(color: kMapText, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by name or region…',
                        hintStyle: TextStyle(
                            color: kMapSubText, fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: kMapSubText, size: 20),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close,
                                    color: kMapSubText, size: 18),
                                onPressed: () => _searchCtrl.clear(),
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

                  const SizedBox(height: 10),

                  // ── Filter chips ─────────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _Chip(
                          label: 'All',
                          active: _filter == null,
                          color: kMapPin,
                          onTap: () =>
                              setState(() { _filter = null; _selectedIndex = 0; }),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: 'Workshops',
                          icon: Icons.store_outlined,
                          active: _filter == PinType.artisan,
                          color: kMapPin,
                          onTap: () => setState(() {
                            _filter = _filter == PinType.artisan
                                ? null
                                : PinType.artisan;
                            _selectedIndex = 0;
                          }),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: 'Pickup Points',
                          icon: Icons.local_shipping_outlined,
                          active: _filter == PinType.pickup,
                          color: kMapPickup,
                          onTap: () => setState(() {
                            _filter = _filter == PinType.pickup
                                ? null
                                : PinType.pickup;
                            _selectedIndex = 0;
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Mini-map (mobile only) ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 220,
                        child: kIsWeb
                            ? _WebMapNote(locations: list)
                            : GoogleMap(
                                initialCameraPosition: _defaultCamera,
                                markers: buildMapMarkers(
                                  locations: list,
                                  userPos: userPos,
                                  onTap: (a) {
                                    final i = list.indexOf(a);
                                    if (i >= 0) _selectLocation(i, a);
                                  },
                                ),
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: false,
                                mapToolbarEnabled: false,
                                onMapCreated: (c) {
                                  _mapCtrl = c;
                                  if (userPos != null) {
                                    c.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                            userPos, 7.0));
                                  }
                                },
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Detail card ──────────────────────────────────────────
                  if (selected != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _DetailCard(
                        location: selected,
                        onDirections: () => _openDirections(selected),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── List header ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          userPos != null
                              ? 'SORTED BY DISTANCE'
                              : 'SORTED BY NAME',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 2.2,
                              color: kMapSubText),
                        ),
                        const Spacer(),
                        Text('${list.length} found',
                            style: TextStyle(
                                fontSize: 11, color: kMapSubText)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── List ─────────────────────────────────────────────────
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('Nothing matches your search.',
                            style:
                                TextStyle(color: kMapSubText)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) => _LocationTile(
                        location: list[i],
                        isSelected: i == safeIdx,
                        onTap: () => _selectLocation(i, list[i]),
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
    _mapCtrl?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
}

// ─── Filter chip ───────────────────────────────────────────────────────────────

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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
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

// ─── Detail card ───────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final ArtisanLocation location;
  final VoidCallback onDirections;

  const _DetailCard({required this.location, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    final isPickup = location.pinType == PinType.pickup;
    final accent   = isPickup ? kMapPickup : kMapPin;

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
          // Cover photo
          if (location.coverPhotoUrl != null)
            Image.network(
              location.coverPhotoUrl!,
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            )
          else
            Container(
              height: 56,
              color: isPickup
                  ? kMapPickup.withOpacity(0.15)
                  : kMapTag,
              child: Center(
                child: Icon(
                  isPickup
                      ? Icons.local_shipping_outlined
                      : Icons.store_outlined,
                  color: accent,
                  size: 28,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    location.typeLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                ),

                const SizedBox(height: 8),

                // Name + distance
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (location.profilePhotoUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ClipOval(
                          child: Image.network(
                            location.profilePhotoUrl!,
                            width: 42, height: 42,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _avatar(accent),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(location.name,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: kMapText,
                                  fontFamily: 'Georgia')),
                          if (location.region != null)
                            Text(location.region!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: accent,
                                    fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (location.distanceKm != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kMapTag,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${location.distanceKm!.toStringAsFixed(1)} km',
                          style: TextStyle(
                              fontSize: 12,
                              color: accent,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),

                if (location.heritageStory != null &&
                    location.heritageStory!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    location.heritageStory!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: kMapSubText,
                        height: 1.5),
                  ),
                ],

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions_outlined, size: 16),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 11),
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

  Widget _avatar(Color color) => Container(
        width: 42, height: 42,
        decoration:
            BoxDecoration(color: kMapTag, shape: BoxShape.circle),
        child: Icon(Icons.store_outlined, color: color, size: 20),
      );
}

// ─── Location list tile ────────────────────────────────────────────────────────

class _LocationTile extends StatelessWidget {
  final ArtisanLocation location;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationTile({
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPickup = location.pinType == PinType.pickup;
    final accent   = isPickup ? kMapPickup : kMapPin;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accent : Colors.transparent,
            width: 1.5,
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
            // Avatar or icon
            ClipOval(
              child: location.profilePhotoUrl != null
                  ? Image.network(
                      location.profilePhotoUrl!,
                      width: 44, height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _iconAvatar(accent, isPickup),
                    )
                  : _iconAvatar(accent, isPickup),
            ),
            const SizedBox(width: 12),

            // Name + region
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(location.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kMapText)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isPickup ? 'Pickup' : 'Workshop',
                          style: TextStyle(
                              fontSize: 10,
                              color: accent,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(location.region ?? '',
                            style: TextStyle(
                                fontSize: 12, color: kMapSubText),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Distance badge
            if (location.distanceKm != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kMapTag,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${location.distanceKm!.toStringAsFixed(1)} km',
                  style: TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconAvatar(Color color, bool isPickup) => Container(
        width: 44, height: 44,
        color: kMapTag,
        child: Icon(
          isPickup
              ? Icons.local_shipping_outlined
              : Icons.store_outlined,
          color: color,
          size: 20,
        ),
      );
}

// ─── Web mini-map note ────────────────────────────────────────────────────────

class _WebMapNote extends StatelessWidget {
  final List<ArtisanLocation> locations;
  const _WebMapNote({required this.locations});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kMapTag,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: kMapPin, size: 32),
            const SizedBox(height: 6),
            Text('Map available on Android / iOS',
                style: TextStyle(
                    fontSize: 13,
                    color: kMapText,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${locations.length} locations listed below',
                style: TextStyle(fontSize: 12, color: kMapSubText)),
          ],
        ),
      ),
    );
  }
}
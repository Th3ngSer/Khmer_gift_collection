import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:khmer_gift_collection/features/map/providers/artisan_location_providers.dart';

// ─── Constants ─────────────────────────────────────────────────────────────────

const _kNearbyRadiusKm = 50.0;
const _cambodiaCamera  = CameraPosition(
  target: LatLng(12.5657, 104.9910),
  zoom: 6.8,
);

// ══════════════════════════════════════════════════════════════════════════════
// MapScreen
// ══════════════════════════════════════════════════════════════════════════════

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapCtrl;
  bool _nearbyMode = false;

  late final AnimationController _panelCtrl;
  late final Animation<Offset>   _panelSlide;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

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

  @override
  void dispose() {
    _mapCtrl?.dispose();
    _panelCtrl.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }
    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final ll = LatLng(pos.latitude, pos.longitude);
    ref.read(userLocationProvider.notifier).set(ll);
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 8.0));
  }

  void _recenter() {
    final pos = ref.read(userLocationProvider);
    if (pos != null) {
      _mapCtrl?.animateCamera(
          CameraUpdate.newLatLngZoom(pos, _nearbyMode ? 11.0 : 9.0));
    } else {
      _mapCtrl
          ?.animateCamera(CameraUpdate.newCameraPosition(_cambodiaCamera));
    }
  }

  // ── Nearby toggle ────────────────────────────────────────────────────────────

  void _toggleNearby(LatLng? userPos) {
    setState(() => _nearbyMode = !_nearbyMode);
    if (_nearbyMode) {
      _panelCtrl.forward();
      if (userPos != null) {
        _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(userPos, 11.0));
      }
    } else {
      _panelCtrl.reverse();
      _mapCtrl?.animateCamera(CameraUpdate.newCameraPosition(_cambodiaCamera));
    }
  }

  // ── Compute distances + filter for nearby ────────────────────────────────────

  List<ArtisanLocation> _withDistances(
      List<ArtisanLocation> all, LatLng? userPos) {
    for (final a in all) {
      a.distanceKm = userPos == null
          ? null
          : haversineKm(userPos.latitude, userPos.longitude, a.lat, a.lng);
    }
    return all;
  }

  List<ArtisanLocation> _nearbyOnly(List<ArtisanLocation> all) => all
      .where((a) => a.distanceKm != null && a.distanceKm! <= _kNearbyRadiusKm)
      .toList()
    ..sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));

  // ── Pin tap ──────────────────────────────────────────────────────────────────

  void _onPinTapped(ArtisanLocation a) {
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(a.latLng, 14.0));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShopDetailSheet(artisan: a),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(artisansProvider);
    final userPos   = ref.watch(userLocationProvider);

    if (kIsWeb) {
      return asyncData.when(
        loading: () => const Scaffold(
            backgroundColor: kMapCream,
            body: Center(child: CircularProgressIndicator(color: kMapPin))),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        data: (list) => _WebFallback(locations: list),
      );
    }

    return Scaffold(
      body: asyncData.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: kMapPin)),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (all) {
          final located     = _withDistances(all, userPos);
          final nearbyList  = _nearbyMode ? _nearbyOnly(located) : <ArtisanLocation>[];
          final mapMarkers  = buildMapMarkers(
            locations: located,
            userPos: userPos,
            onTap: _onPinTapped,
          );

          return Stack(
            children: [

              // ── Full-screen Google Map ─────────────────────────────────────
              GoogleMap(
                initialCameraPosition: _cambodiaCamera,
                markers: mapMarkers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (ctrl) {
                  _mapCtrl = ctrl;
                  if (userPos != null) {
                    ctrl.animateCamera(
                        CameraUpdate.newLatLngZoom(userPos, 8.0));
                  }
                },
              ),

              // ── Top bar ───────────────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // Title card
                      _MapCard(
                        child: Row(
                          children: [
                            const Icon(Icons.map_outlined,
                                color: kMapPin, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nearbyMode
                                    ? 'Nearby (${_kNearbyRadiusKm.toInt()} km)'
                                    : 'Artisan Map',
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: kMapText,
                                    fontFamily: 'Georgia'),
                              ),
                            ),
                            Text(
                              '${located.length} shop${located.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                  fontSize: 12, color: kMapSubText),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Nearby Me toggle chip
                      _NearbyToggle(
                        active: _nearbyMode,
                        hasGps: userPos != null,
                        onTap: userPos != null
                            ? () => _toggleNearby(userPos)
                            : () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Enable location to use Nearby Me'),
                                    duration: Duration(seconds: 2),
                                  ),
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
                    color: Colors.white.withOpacity(0.93),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 10, height: 10,
                          decoration: const BoxDecoration(
                              color: kMapPin, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Artisan Workshop',
                          style: TextStyle(
                              fontSize: 11,
                              color: kMapText,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),

              // ── Recenter FAB ──────────────────────────────────────────────
              Positioned(
                bottom: _nearbyMode ? 320 : 100,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'recenter',
                  backgroundColor: Colors.white,
                  foregroundColor: kMapPin,
                  elevation: 4,
                  onPressed: _recenter,
                  child: const Icon(Icons.my_location),
                ),
              ),

              // ── Nearby slide-up panel ─────────────────────────────────────
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: SlideTransition(
                  position: _panelSlide,
                  child: _NearbyPanel(
                    locations: nearbyList,
                    onTap: (a) {
                      _mapCtrl?.animateCamera(
                          CameraUpdate.newLatLngZoom(a.latLng, 14.0));
                      _onPinTapped(a);
                    },
                    onClose: () => _toggleNearby(userPos),
                  ),
                ),
              ),

            ],
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shop Detail Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════

class _ShopDetailSheet extends StatelessWidget {
  final ArtisanLocation artisan;
  const _ShopDetailSheet({required this.artisan});

  Future<void> _openDirections() async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${artisan.lat},${artisan.lng}&travelmode=driving');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),

            // Cover photo
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

                  // "Artisan Workshop" badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kMapPin.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.store_outlined, size: 12, color: kMapPin),
                        SizedBox(width: 4),
                        Text('Artisan Workshop',
                            style: TextStyle(
                                fontSize: 11,
                                color: kMapPin,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Avatar + name + location + distance
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Profile avatar
                      ClipOval(
                        child: artisan.profilePhotoUrl != null
                            ? Image.network(
                                artisan.profilePhotoUrl!,
                                width: 54, height: 54,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _AvatarFallback(),
                              )
                            : _AvatarFallback(),
                      ),
                      const SizedBox(width: 12),

                      // Name + region
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(artisan.name,
                                style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: kMapText,
                                    fontFamily: 'Georgia')),
                            if (artisan.region != null) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 13, color: kMapPin),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(artisan.region!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: kMapPin,
                                            fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Distance badge
                      if (artisan.distanceKm != null) ...[
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              artisan.distanceKm!.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: kMapPin),
                            ),
                            const Text('km away',
                                style: TextStyle(
                                    fontSize: 11, color: kMapSubText)),
                          ],
                        ),
                      ],
                    ],
                  ),

                  // Heritage story
                  if (artisan.heritageStory != null &&
                      artisan.heritageStory!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      artisan.heritageStory!,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          color: kMapSubText,
                          height: 1.6),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openDirections,
                          icon: const Icon(Icons.directions_outlined,
                              size: 16),
                          label: const Text('Directions'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kMapPin,
                            side: const BorderSide(color: kMapPin),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // Pass the full artisan data map to the profile screen
                            context.push('/artisans/${artisan.id}', extra: {
                              'id': artisan.id,
                              'name': artisan.name,
                              'region': artisan.region ?? '',
                              'heritage_story': artisan.heritageStory ?? '',
                              'profile_photo_url':
                                  artisan.profilePhotoUrl ?? '',
                              'cover_photo_url': artisan.coverPhotoUrl ?? '',
                              'latest_story_url':
                                  artisan.latestStoryUrl ?? '',
                              'latitude': artisan.lat,
                              'longitude': artisan.lng,
                            });
                          },
                          icon: const Icon(Icons.person_outline, size: 16),
                          label: const Text('View Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kMapPin,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ),
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
}

// ══════════════════════════════════════════════════════════════════════════════
// Nearby Slide-Up Panel
// ══════════════════════════════════════════════════════════════════════════════

class _NearbyPanel extends StatelessWidget {
  final List<ArtisanLocation>      locations;
  final void Function(ArtisanLocation) onTap;
  final VoidCallback               onClose;

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
          BoxShadow(
              color: Color(0x22000000),
              blurRadius: 20,
              offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.near_me, color: kMapGold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locations.isEmpty
                        ? 'No shops within 50 km'
                        : '${locations.length} shop${locations.length == 1 ? '' : 's'} within 50 km',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kMapText),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  color: kMapSubText,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: locations.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No artisan workshops found within 50 km of your location.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kMapSubText, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    itemCount: locations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final a = locations[i];
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
                                        width: 38, height: 38,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _SmallAvatar(),
                                      )
                                    : _SmallAvatar(),
                              ),
                              const SizedBox(width: 10),

                              // Name + region
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(a.name,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: kMapText),
                                        overflow: TextOverflow.ellipsis),
                                    if (a.region != null)
                                      Text(a.region!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: kMapSubText),
                                          overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),

                              // Distance
                              if (a.distanceKm != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: kMapPin.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${a.distanceKm!.toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: kMapPin,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),

                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right,
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
}

// ══════════════════════════════════════════════════════════════════════════════
// Small reusable widgets
// ══════════════════════════════════════════════════════════════════════════════

class _AvatarFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 54, height: 54,
        color: kMapTag,
        child: const Icon(Icons.store_outlined, color: kMapPin, size: 26));
}

class _SmallAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 38, height: 38,
        color: kMapTag,
        child: const Icon(Icons.store_outlined, color: kMapPin, size: 18));
}

class _MapCard extends StatelessWidget {
  final Widget child;
  const _MapCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        child: child,
      );
}

class _NearbyToggle extends StatelessWidget {
  final bool         active;
  final bool         hasGps;
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
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              size: 15,
              color: active
                  ? Colors.white
                  : (hasGps ? kMapGold : kMapSubText),
            ),
            const SizedBox(width: 6),
            Text(
              'Nearby Me  •  50 km',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Colors.white
                      : (hasGps ? kMapText : kMapSubText)),
            ),
            if (!hasGps) ...[
              const SizedBox(width: 4),
              const Icon(Icons.lock_outline, size: 12, color: kMapSubText),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: kMapSubText, size: 48),
              const SizedBox(height: 16),
              const Text('Could not load shops',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: kMapText)),
              const SizedBox(height: 8),
              Text(message,
                  style: const TextStyle(fontSize: 12, color: kMapSubText),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Web fallback
// ══════════════════════════════════════════════════════════════════════════════

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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
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
                  return ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    leading: const Icon(Icons.store_outlined, color: kMapPin),
                    title: Text(a.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: kMapText)),
                    subtitle: Text(a.region ?? '',
                        style: const TextStyle(color: kMapSubText)),
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
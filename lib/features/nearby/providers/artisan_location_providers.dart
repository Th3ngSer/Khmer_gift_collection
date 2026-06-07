import 'dart:math' show sqrt, sin, cos, atan2, pi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kMapCream    = Color(0xFFF5F0E8);
const kMapPin      = Color(0xFF8B3A2A);
const kMapGold     = Color(0xFFC8A84B);
const kMapText     = Color(0xFF2C1A0E);
const kMapSubText  = Color(0xFF7A6651);
const kMapTag      = Color(0xFFEDE3D0);
const kMapSelected = Color(0xFF8B3A2A);
const kMapPickup   = Color(0xFF2E6B4F); 


enum PinType { artisan, pickup }

// ─── Data Model ────────────────────────────────────────────────────────────────

class ArtisanLocation {
  final String id;
  final String name;
  final String? region;
  final String? heritageStory;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final double lat;
  final double lng;
  final PinType pinType;

  // Computed after GPS fix
  double? distanceKm;

  ArtisanLocation({
    required this.id,
    required this.name,
    this.region,
    this.heritageStory,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    required this.lat,
    required this.lng,
    this.pinType = PinType.artisan,
    this.distanceKm,
  });

  LatLng get latLng => LatLng(lat, lng);

  String get typeLabel =>
      pinType == PinType.pickup ? 'Pickup Point' : 'Artisan Workshop';

  factory ArtisanLocation.fromMap(Map<String, dynamic> m,
      {PinType type = PinType.artisan}) =>
      ArtisanLocation(
        id: m['id'].toString(),
        name: m['name'] as String? ?? '',
        region: m['region'] as String?,
        heritageStory: m['heritage_story'] as String?,
        profilePhotoUrl: m['profile_photo_url'] as String?,
        coverPhotoUrl: m['cover_photo_url'] as String?,
        lat: (m['latitude'] as num?)?.toDouble() ?? 0,
        lng: (m['longitude'] as num?)?.toDouble() ?? 0,
        pinType: type,
      );
}

// ─── Fallback seed data ────────────────────────────────────────────────────────

final kFallbackArtisans = <ArtisanLocation>[
  ArtisanLocation(
    id: 'f1', name: 'Srey Neang Silk Weaving',
    region: 'Preah Dak, Siem Reap',
    heritageStory: 'Practicing the ancient art of Khmer silk weaving.',
    lat: 13.3633, lng: 103.8564,
    pinType: PinType.artisan,
  ),
  ArtisanLocation(
    id: 'f2', name: 'Sopheap Clay Ceramics',
    region: 'Kampong Chhnang',
    heritageStory: 'Molding traditional unglazed pottery by hand.',
    lat: 12.2500, lng: 104.6667,
    pinType: PinType.artisan,
  ),
  // Pickup points (hardcoded until you add a pickup_points table)
  ArtisanLocation(
    id: 'p1', name: 'Phnom Penh Central Pickup',
    region: 'Phnom Penh',
    heritageStory: 'Central collection point for all orders in the capital.',
    lat: 11.5679, lng: 104.9220,
    pinType: PinType.pickup,
  ),
  ArtisanLocation(
    id: 'p2', name: 'Siem Reap Old Market Pickup',
    region: 'Siem Reap',
    heritageStory: 'Collect your order near Psar Chas.',
    lat: 13.3621, lng: 103.8601,
    pinType: PinType.pickup,
  ),
];

// ─── Haversine distance ────────────────────────────────────────────────────────

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// ─── Providers ─────────────────────────────────────────────────────────────────

/// All artisans with GPS coordinates from Supabase.
final artisansProvider = FutureProvider<List<ArtisanLocation>>((ref) async {
  try {
    final rows = await Supabase.instance.client
        .from('artisans')
        .select(
            'id, name, region, heritage_story, profile_photo_url, cover_photo_url, latitude, longitude')
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)
        .order('name');
    final artisans = (rows as List)
        .map((r) => ArtisanLocation.fromMap(r, type: PinType.artisan))
        .toList();

    // Merge in hardcoded pickup points
    // (replace with Supabase query once you add a pickup_points table)
    final pickups = kFallbackArtisans.where((a) => a.pinType == PinType.pickup).toList();
    return [...artisans, ...pickups];
  } catch (_) {
    return kFallbackArtisans;
  }
});

/// User GPS position.
class UserLocationNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;
  void set(LatLng v) => state = v;
}

final userLocationProvider =
    NotifierProvider<UserLocationNotifier, LatLng?>(UserLocationNotifier.new);

/// Active category/type filter on the map.
class MapFilterNotifier extends Notifier<PinType?> {
  @override
  PinType? build() => null; // null = show all
  void toggle(PinType t) => state = (state == t) ? null : t;
  void clear() => state = null;
}

final mapFilterProvider =
    NotifierProvider<MapFilterNotifier, PinType?>(MapFilterNotifier.new);

// ─── Shared marker builder ─────────────────────────────────────────────────────

Set<Marker> buildMapMarkers({
  required List<ArtisanLocation> locations,
  required LatLng? userPos,
  required void Function(ArtisanLocation) onTap,
}) {
  return {
    if (userPos != null)
      Marker(
        markerId: const MarkerId('user'),
        position: userPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You are here'),
      ),
    ...locations.map((a) => Marker(
          markerId: MarkerId('loc_${a.id}'),
          position: a.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            a.pinType == PinType.pickup
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(title: a.name, snippet: a.region),
          onTap: () => onTap(a),
        )),
  };
}
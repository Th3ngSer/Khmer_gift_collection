import 'dart:math' show sqrt, sin, cos, atan2, pi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Color Palette ─────────────────────────────────────────────────────────────

const kMapCream   = Color(0xFFF5F0E8);
const kMapPin     = Color(0xFF8B3A2A);
const kMapGold    = Color(0xFFC8A84B);
const kMapText    = Color(0xFF2C1A0E);
const kMapSubText = Color(0xFF7A6651);
const kMapTag     = Color(0xFFEDE3D0);

// ─── Data Model ────────────────────────────────────────────────────────────────
//
// Matches public.artisans exactly:
//   id, name, profile_photo_url, region, heritage_story,
//   latitude, longitude, cover_photo_url, latest_story_url

class ArtisanLocation {
  final String  id;
  final String  name;
  final String? region;
  final String? heritageStory;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final String? latestStoryUrl;
  final double  lat;
  final double  lng;

  /// Computed after GPS fix — mutable so _visibleLocations can update in-place.
  double? distanceKm;

  ArtisanLocation({
    required this.id,
    required this.name,
    this.region,
    this.heritageStory,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    this.latestStoryUrl,
    required this.lat,
    required this.lng,
    this.distanceKm,
  });

  LatLng get latLng => LatLng(lat, lng);

  /// Build from a Supabase `artisans` row.
  factory ArtisanLocation.fromRow(Map<String, dynamic> m) => ArtisanLocation(
        id: m['id'].toString(),
        name: m['name'] as String? ?? '',
        region: m['region'] as String?,
        heritageStory: m['heritage_story'] as String?,
        profilePhotoUrl: m['profile_photo_url'] as String?,
        coverPhotoUrl: m['cover_photo_url'] as String?,
        latestStoryUrl: m['latest_story_url'] as String?,
        lat: (m['latitude'] as num?)?.toDouble() ?? 0,
        lng: (m['longitude'] as num?)?.toDouble() ?? 0,
      );
}

// ─── Haversine Distance ────────────────────────────────────────────────────────

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// ─── Artisans Provider ─────────────────────────────────────────────────────────
//
// Fetches all artisans that have GPS coordinates set.
// Throws on network/auth failure so the UI can display the error.

final artisansProvider = FutureProvider<List<ArtisanLocation>>((ref) async {
  final rows = await Supabase.instance.client
      .from('artisans')
      .select(
          'id, name, region, heritage_story, '
          'profile_photo_url, cover_photo_url, latest_story_url, '
          'latitude, longitude')
      .not('latitude', 'is', null)
      .not('longitude', 'is', null)
      .order('name');

  return (rows as List)
      .map((r) => ArtisanLocation.fromRow(r as Map<String, dynamic>))
      .toList();
});

// ─── User Location ─────────────────────────────────────────────────────────────

class UserLocationNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;
  void set(LatLng v) => state = v;
}

final userLocationProvider =
    NotifierProvider<UserLocationNotifier, LatLng?>(UserLocationNotifier.new);

// ─── Shared Marker Builder ─────────────────────────────────────────────────────

Set<Marker> buildMapMarkers({
  required List<ArtisanLocation> locations,
  required LatLng? userPos,
  required void Function(ArtisanLocation) onTap,
}) {
  return {
    if (userPos != null)
      Marker(
        markerId: const MarkerId('_user'),
        position: userPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You are here'),
      ),
    ...locations.map(
      (a) => Marker(
        markerId: MarkerId('artisan_${a.id}'),
        position: a.latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: a.name, snippet: a.region),
        onTap: () => onTap(a),
      ),
    ),
  };
}
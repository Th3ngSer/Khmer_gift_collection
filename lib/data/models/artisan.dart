class Artisan {
  final String id;
  final String name;
  final String craft;
  final String region;
  final String avatar;
  final String cover;
  final String? story;
  final double? latitude;
  final double? longitude;

  Artisan({
    required this.id,
    required this.name,
    required this.craft,
    required this.region,
    required this.avatar,
    required this.cover,
    this.story,
    this.latitude,
    this.longitude,
  });

  factory Artisan.fromJson(Map<String, dynamic> json) {
    return Artisan(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      craft: json['craft'] ?? '',
      region: json['region'] ?? '',
      avatar: json['profile_photo_url'] ?? json['avatar'] ?? '',
      cover: json['cover_photo_url'] ?? json['cover'] ?? '',
      story: json['heritage_story'] ?? json['story'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'craft': craft,
      'region': region,
      'avatar': avatar,
      'cover': cover,
      'story': story,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Artisan {
  final String id;
  final String name;
  final String craft;
  final String region;
  final String avatar;
  final String cover;
  final String? story;

  Artisan({
    required this.id,
    required this.name,
    required this.craft,
    required this.region,
    required this.avatar,
    required this.cover,
    this.story,
  });

  factory Artisan.fromJson(Map<String, dynamic> json) {
    return Artisan(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      craft: json['craft'] ?? '',
      region: json['region'] ?? '',
      avatar: json['avatar'] ?? '',
      cover: json['cover'] ?? '',
      story: json['story'],
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
    };
  }
}

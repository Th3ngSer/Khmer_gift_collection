class Reel {
  final String id;
  final String artisanId;
  final String artisanName;
  final String artisanAvatar;
  final String videoUrl;
  final String? caption;
  final String? location;
  final int likes;
  final bool isLiked;

  Reel({
    required this.id,
    required this.artisanId,
    required this.artisanName,
    required this.artisanAvatar,
    required this.videoUrl,
    this.caption,
    this.location,
    this.likes = 0,
    this.isLiked = false,
  });

  factory Reel.fromJson(Map<String, dynamic> json) {
    return Reel(
      id: json['id'].toString(),
      artisanId: json['artisan_id'].toString(),
      artisanName: json['artisan_name'] ?? '',
      artisanAvatar: json['artisan_avatar'] ?? '',
      videoUrl: json['video_url'] ?? '',
      caption: json['caption'],
      location: json['location'],
      likes: json['likes'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }
}

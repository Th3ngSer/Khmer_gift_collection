class Review {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String productId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isVerified;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isVerified = false,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'].toString(),
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'Anonymous',
      userAvatar: json['user_avatar'],
      productId: json['product_id'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'product_id': productId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'is_verified': isVerified,
    };
  }
}

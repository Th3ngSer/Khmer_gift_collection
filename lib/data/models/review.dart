class Review {
  final String id;
  final String customerId;
  final String productId;
  final int rating;
  final String reviewText;
  final String? photoUrl;
  final DateTime createdAt;
  
  // These fields might come from a join with a 'profiles' or 'customers' table
  final String userName;
  final String? userAvatar;
  final bool isVerified;

  Review({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.rating,
    required this.reviewText,
    this.photoUrl,
    required this.createdAt,
    this.userName = 'Anonymous',
    this.userAvatar,
    this.isVerified = false,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      rating: json['rating'] ?? 0,
      reviewText: json['review_text'] ?? '',
      photoUrl: json['photo_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      // Handling potential joins or default values
      userName: json['customers']?['full_name'] ?? json['user_name'] ?? 'Khmer Guest',
      userAvatar: json['customers']?['avatar_url'] ?? json['user_avatar'],
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'product_id': productId,
      'rating': rating,
      'review_text': reviewText,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

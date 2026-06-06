class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String cover;
  final String? story;
  final double rating;
  final int reviewsCount;
  final List<String> tags;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.cover,
    this.story,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.tags = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      cover: json['cover'] ?? '',
      story: json['story'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['reviews_count'] ?? 0,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'cover': cover,
      'story': story,
      'rating': rating,
      'reviews_count': reviewsCount,
      'tags': tags,
    };
  }
}

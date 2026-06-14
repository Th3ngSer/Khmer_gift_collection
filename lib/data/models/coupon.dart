class Coupon {
  final String id;
  final String code;
  final String title;
  final String description;
  final double discountPercentage;
  final DateTime validFrom;
  final DateTime validUntil;
  final String? bannerImage;

  Coupon({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountPercentage,
    required this.validFrom,
    required this.validUntil,
    this.bannerImage,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      title: json['title'] ?? json['description'] ?? 'Special Discount',
      description: json['description'] ?? '',
      discountPercentage: (json['discount_percentage'] ?? 0).toDouble(),
      validFrom: json['valid_from'] != null 
          ? DateTime.parse(json['valid_from']) 
          : DateTime.now(),
      validUntil: json['valid_until'] != null 
          ? DateTime.parse(json['valid_until']) 
          : DateTime.now().add(const Duration(days: 30)),
      bannerImage: json['banner_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'discount_percentage': discountPercentage,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'banner_image': bannerImage,
    };
  }
}

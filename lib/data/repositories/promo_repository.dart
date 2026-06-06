import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coupon.dart';

class PromoRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Coupon>> fetchActivePromotions() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('coupons')
          .select('*')
          .lte('valid_from', now)
          .gte('valid_until', now);
      
      return (response as List).map((json) => Coupon.fromJson(json)).toList();
    } catch (e) {
      // Fallback mock data for development
      return [
        Coupon(
          id: '1',
          code: 'KNY2026',
          title: 'Khmer New Year Special',
          description: '15% off on all traditional artisan crafts to celebrate the festive season.',
          discountPercentage: 15,
          validFrom: DateTime.now(),
          validUntil: DateTime.now().add(const Duration(days: 30)),
          bannerImage: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQzeEqUnnuR62JZ8GFvqnkymYSwm_h16DW-1A&s',
        ),
        Coupon(
          id: '2',
          code: 'PCHUMBEN',
          title: 'Pchum Ben Remembrance',
          description: '10% discount on silver sets and ceremonial gifts.',
          discountPercentage: 10,
          validFrom: DateTime.now(),
          validUntil: DateTime.now().add(const Duration(days: 15)),
          bannerImage: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSFfTj_H7Q4s2hJ1BM97bUb1IXHjfAJ0zg9-g&s',
        ),
        Coupon(
          id: '3',
          code: 'WELCOME24',
          title: 'New Member Voucher',
          description: 'Get 5% off your first purchase as a new member of our collection.',
          discountPercentage: 5,
          validFrom: DateTime.now(),
          validUntil: DateTime.now().add(const Duration(days: 365)),
        ),
      ];
    }
  }
}

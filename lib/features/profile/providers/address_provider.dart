import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedAddress {
  final String id;
  final String label; // e.g. "Home", "Office"
  final String fullAddress;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.isDefault,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
        id: json['id'].toString(),
        label: json['label'] ?? 'Address',
        fullAddress: json['full_address'] ?? '',
        isDefault: json['is_default'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'full_address': fullAddress,
        'is_default': isDefault,
      };

  SavedAddress copyWith({
    String? id,
    String? label,
    String? fullAddress,
    bool? isDefault,
  }) =>
      SavedAddress(
        id: id ?? this.id,
        label: label ?? this.label,
        fullAddress: fullAddress ?? this.fullAddress,
        isDefault: isDefault ?? this.isDefault,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AddressNotifier extends AsyncNotifier<List<SavedAddress>> {
  @override
  Future<List<SavedAddress>> build() => _fetch();

  Future<List<SavedAddress>> _fetch() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    try {
      final rows = await Supabase.instance.client
          .from('user_addresses')
          .select()
          .eq('user_id', user.id)
          .order('is_default', ascending: false);

      return (rows as List).map((r) => SavedAddress.fromJson(r)).toList();
    } catch (e) {
      // If table doesn't exist, return empty list to allow manual address entry
      // (user can still place order by entering address manually)
      print('Address table error (expected if not created yet): $e');
      return [];
    }
  }

  /// Add a new address and persist it to Supabase.
  Future<void> addAddress(String label, String fullAddress,
      {bool makeDefault = false}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // If the new address is default, clear existing default first.
      if (makeDefault) await _clearDefault(user.id);

      final row = await Supabase.instance.client
          .from('user_addresses')
          .insert({
            'user_id': user.id,
            'label': label,
            'full_address': fullAddress,
            'is_default': makeDefault,
          })
          .select()
          .single();

      final newAddr = SavedAddress.fromJson(row);

      state = AsyncData([
        if (makeDefault)
          ...((state.value ?? []).map((a) => a.copyWith(isDefault: false)))
        else
          ...(state.value ?? []),
        newAddr,
      ]);
    } catch (e) {
      print('Error adding address (expected if table not created): $e');
      // Silently fail - address table might not be created yet
    }
  }

  /// Set an existing address as the default.
  Future<void> setDefault(String addressId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await _clearDefault(user.id);
      await Supabase.instance.client
          .from('user_addresses')
          .update({'is_default': true})
          .eq('id', addressId);

      state = AsyncData((state.value ?? []).map((a) {
        return a.copyWith(isDefault: a.id == addressId);
      }).toList());
    } catch (e) {
      print('Error setting default address: $e');
    }
  }

  /// Delete an address.
  Future<void> deleteAddress(String addressId) async {
    try {
      await Supabase.instance.client
          .from('user_addresses')
          .delete()
          .eq('id', addressId);

      state = AsyncData(
          (state.value ?? []).where((a) => a.id != addressId).toList());
    } catch (e) {
      print('Error deleting address: $e');
    }
  }

  Future<void> _clearDefault(String userId) async {
    try {
      await Supabase.instance.client
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', userId);
    } catch (e) {
      print('Error clearing default address: $e');
    }
  }

  /// Refresh from Supabase.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final addressProvider =
    AsyncNotifierProvider<AddressNotifier, List<SavedAddress>>(
        AddressNotifier.new);
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';

// ---------------------------------------------------------------------------
// Address model
// ---------------------------------------------------------------------------

class SavedAddress {
  final String id;
  final String label;
  final String fullAddress;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.isDefault,
  });

  SavedAddress copyWith({String? id, String? label, String? fullAddress, bool? isDefault}) =>
      SavedAddress(
        id: id ?? this.id,
        label: label ?? this.label,
        fullAddress: fullAddress ?? this.fullAddress,
        isDefault: isDefault ?? this.isDefault,
      );
}

// ---------------------------------------------------------------------------
// Address notifier — CRUD against Supabase user_addresses
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
      return (rows as List)
          .map((r) => SavedAddress(
                id: r['id'].toString(),
                label: r['label'] ?? 'Address',
                fullAddress: r['full_address'] ?? '',
                isDefault: r['is_default'] ?? false,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<SavedAddress> addAddress(String label, String fullAddress,
      {bool makeDefault = false}) async {
    final user = Supabase.instance.client.auth.currentUser!;
    if (makeDefault) {
      await Supabase.instance.client
          .from('user_addresses')
          .update({'is_default': false}).eq('user_id', user.id);
    }
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
    final addr = SavedAddress(
      id: row['id'].toString(),
      label: row['label'] ?? label,
      fullAddress: row['full_address'] ?? fullAddress,
      isDefault: row['is_default'] ?? makeDefault,
    );
    state = AsyncData([
      if (makeDefault)
        ...(state.value ?? []).map((a) => a.copyWith(isDefault: false))
      else
        ...(state.value ?? []),
      addr,
    ]);
    return addr;
  }

  Future<void> setDefault(String id) async {
    final user = Supabase.instance.client.auth.currentUser!;
    await Supabase.instance.client
        .from('user_addresses')
        .update({'is_default': false}).eq('user_id', user.id);
    await Supabase.instance.client
        .from('user_addresses')
        .update({'is_default': true}).eq('id', id);
    state = AsyncData(
        (state.value ?? []).map((a) => a.copyWith(isDefault: a.id == id)).toList());
  }

  Future<void> deleteAddress(String id) async {
    await Supabase.instance.client.from('user_addresses').delete().eq('id', id);
    state = AsyncData((state.value ?? []).where((a) => a.id != id).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final _addressProvider =
    AsyncNotifierProvider<AddressNotifier, List<SavedAddress>>(AddressNotifier.new);

// ---------------------------------------------------------------------------
// Checkout Screen
// ---------------------------------------------------------------------------

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _selectedAddressId;
  bool _isPlacingOrder = false;
  bool _initialized = false;

  static const _gold = Color(0xFFD4AF37);
  static const _terracotta = Color(0xFF8C2D19);

  String _resolveAddress(List<SavedAddress> addresses) {
    if (_selectedAddressId != null) {
      final match = addresses.where((a) => a.id == _selectedAddressId);
      if (match.isNotEmpty) return match.first.fullAddress;
    }
    return '';
  }

  void _initDefault(List<SavedAddress> addresses) {
    if (_initialized) return;
    _initialized = true;
    if (addresses.isEmpty) return;
    final def = addresses.firstWhere((a) => a.isDefault,
        orElse: () => addresses.first);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _selectedAddressId = def.id);
    });
  }

  Future<void> _placeOrder(List<SavedAddress> addresses) async {
    final address = _resolveAddress(addresses);
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select or add a delivery address.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your cart is empty.')));
      return;
    }

    setState(() => _isPlacingOrder = true);
    try {
      await ref.read(placeOrderProvider.notifier).placeOrder(
            items: cart.items.values.toList(),
            totalAmount: cart.total,
            shippingAddress: address,
            couponCode: cart.appliedCouponCode,
            discountAmount: cart.discountAmount,
          );
      ref.read(cartProvider.notifier).clearCart();
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _OrderSuccessDialog(
          onDone: () { Navigator.pop(ctx); context.go('/home'); },
          onViewOrders: () { Navigator.pop(ctx); context.go('/my-orders'); },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Order failed: $e')));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final addressAsync = ref.watch(_addressProvider);
    final addresses = addressAsync.value ?? [];
    final items = cart.items.values.toList();

    // Redirect to cart if empty
    if (cart.items.isEmpty && !_isPlacingOrder) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Your cart is empty. Add items first.'),
            behavior: SnackBarBehavior.floating,
          ));
          context.go('/cart');
        }
      });
    }

    _initDefault(addresses);
    final hasAddress = _resolveAddress(addresses).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/cart');
              }
            },
          ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // ── Delivery Address ──────────────────────────────────────────────
          _sectionHeader('Delivery Address', Icons.location_on_outlined),
          const SizedBox(height: 12),
          _buildAddressSection(addressAsync, addresses),

          const SizedBox(height: 28),

          // ── Items ─────────────────────────────────────────────────────────
          _sectionHeader('Items (${items.length})', Icons.shopping_bag_outlined),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No items in cart.',
                  style: TextStyle(color: Colors.grey.shade500)),
            )
          else
            ...items.map(_buildItemRow),

          const SizedBox(height: 28),

          // ── Price Breakdown ───────────────────────────────────────────────
          _sectionHeader('Price Breakdown', Icons.receipt_long_outlined),
          const SizedBox(height: 12),
          _buildPriceBreakdown(cart),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(cart, addresses, hasAddress),
    );
  }

  // ---------------------------------------------------------------------------
  // Address section
  // ---------------------------------------------------------------------------

  Widget _buildAddressSection(
      AsyncValue<List<SavedAddress>> async, List<SavedAddress> addresses) {
    if (async.isLoading) return const LinearProgressIndicator();

    return Column(
      children: [
        if (addresses.isEmpty)
          _emptyAddressNotice()
        else
          ...addresses.map((a) => _addressTile(a, addresses)),

        const SizedBox(height: 10),

        // Add new address button
        OutlinedButton.icon(
          onPressed: () => _showAddAddressSheet(context),
          icon: const Icon(Icons.add_location_alt_outlined, color: _gold, size: 18),
          label: const Text('Add New Address',
              style: TextStyle(color: _gold, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _gold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _emptyAddressNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text('No saved addresses yet. Add one below.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _addressTile(SavedAddress addr, List<SavedAddress> all) {
    final isSelected = _selectedAddressId == addr.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressId = addr.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: isSelected ? _gold.withOpacity(0.07) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _gold : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? _gold : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(addr.label,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (addr.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Default',
                            style: TextStyle(fontSize: 10, color: _gold)),
                      ),
                    ]
                  ]),
                  const SizedBox(height: 2),
                  Text(addr.fullAddress,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            // Actions menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
              onSelected: (val) async {
                if (val == 'default') {
                  await ref.read(_addressProvider.notifier).setDefault(addr.id);
                  if (mounted) setState(() => _selectedAddressId = addr.id);
                } else if (val == 'delete') {
                  await ref.read(_addressProvider.notifier).deleteAddress(addr.id);
                  if (mounted && _selectedAddressId == addr.id) {
                    final remaining = ref.read(_addressProvider).value ?? [];
                    setState(() {
                      _selectedAddressId =
                          remaining.isNotEmpty ? remaining.first.id : null;
                    });
                  }
                }
              },
              itemBuilder: (_) => [
                if (!addr.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Row(children: [
                      Icon(Icons.star_outline, size: 16),
                      SizedBox(width: 8),
                      Text('Set as default'),
                    ]),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add address bottom sheet
  // ---------------------------------------------------------------------------

  void _showAddAddressSheet(BuildContext context) {
    final labelController = TextEditingController(text: 'Home');
    final addressController = TextEditingController();
    bool makeDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text('Add Delivery Address',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif')),
                const SizedBox(height: 20),

                // Label field
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    labelText: 'Label (e.g. Home, Office)',
                    prefixIcon: const Icon(Icons.label_outline, color: _gold),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _gold, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Address field
                TextField(
                  controller: addressController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Full Address',
                    hintText: '#12 St. 240, Daun Penh, Phnom Penh',
                    prefixIcon: const Icon(Icons.location_on_outlined, color: _gold),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _gold, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Set as default toggle
                Row(
                  children: [
                    Switch(
                      value: makeDefault,
                      activeColor: _gold,
                      onChanged: (v) => setModal(() => makeDefault = v),
                    ),
                    const SizedBox(width: 8),
                    const Text('Set as default address'),
                  ],
                ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _terracotta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () async {
                      final addr = addressController.text.trim();
                      final label = labelController.text.trim().isEmpty
                          ? 'Address'
                          : labelController.text.trim();
                      if (addr.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Please enter an address.'),
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      }
                      Navigator.pop(ctx);
                      final saved = await ref
                          .read(_addressProvider.notifier)
                          .addAddress(label, addr, makeDefault: makeDefault);
                      if (mounted) {
                        setState(() => _selectedAddressId = saved.id);
                      }
                    },
                    child: const Text('Save Address',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Item row
  // ---------------------------------------------------------------------------

  Widget _buildItemRow(item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.imageUrl.isNotEmpty
                ? Image.network(item.imageUrl,
                    width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgFallback())
                : _imgFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Qty: ${item.quantity}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('\$${(item.price * item.quantity).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Price breakdown
  // ---------------------------------------------------------------------------

  Widget _buildPriceBreakdown(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _priceRow('Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}'),
          if (cart.discountPercentage > 0) ...[
            const SizedBox(height: 8),
            _priceRow(
              'Promo "${cart.appliedCouponCode}" (${cart.discountPercentage.toInt()}%)',
              '-\$${cart.discountAmount.toStringAsFixed(2)}',
              valueColor: Colors.green,
            ),
          ],
          const SizedBox(height: 8),
          _priceRow('Shipping', 'Free', valueColor: Colors.green),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1)),
          _priceRow('Total', '\$${cart.total.toStringAsFixed(2)}',
              isBold: true, valueColor: _terracotta),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    final style = TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontSize: isBold ? 17 : 14);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child:
                Text(label, style: style, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Text(value,
            style: style.copyWith(
                color: valueColor, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar(
      CartState cart, List<SavedAddress> addresses, bool hasAddress) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border:
            Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4)),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isPlacingOrder || !hasAddress || cart.items.isEmpty)
            ? null
            : () => _placeOrder(addresses),
        style: ElevatedButton.styleFrom(
          backgroundColor: _terracotta,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isPlacingOrder
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(
                !hasAddress
                    ? 'Select a delivery address'
                    : cart.items.isEmpty
                        ? 'Cart is empty'
                        : 'Place Order — \$${cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Row(
        children: [
          Icon(icon, size: 18, color: _gold),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      );

  Widget _imgFallback() => Container(
      width: 56,
      height: 56,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported,
          color: Colors.grey, size: 22));
}

// ---------------------------------------------------------------------------
// Order Success Dialog
// ---------------------------------------------------------------------------

class _OrderSuccessDialog extends StatelessWidget {
  final VoidCallback onDone;
  final VoidCallback onViewOrders;
  const _OrderSuccessDialog({required this.onDone, required this.onViewOrders});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 52),
            ),
            const SizedBox(height: 20),
            const Text('Order Placed! 🎉',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif')),
            const SizedBox(height: 10),
            Text(
              'Thank you for supporting Khmer artisans.\nYour order is being prepared with care.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade600, height: 1.6, fontSize: 14),
            ),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDone,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Keep Shopping'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onViewOrders,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C2D19),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('View Orders',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
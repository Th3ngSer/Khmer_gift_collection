import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';

// ---------------------------------------------------------------------------
// Active coupons fetcher (lightweight – only code/discount/validity needed)
// ---------------------------------------------------------------------------

final _activeCouponsRawProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final rows = await Supabase.instance.client
        .from('coupons')
        .select('code, discount_percentage, valid_from, valid_until')
        .lte('valid_from', DateTime.now().toIso8601String())
        .gte('valid_until', DateTime.now().toIso8601String());
    return List<Map<String, dynamic>>.from(rows as List);
  },
);

// ---------------------------------------------------------------------------
// Cart Screen
// ---------------------------------------------------------------------------

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();
  String? _couponError;
  String? _couponSuccess;

  static const _gold = Color(0xFFD4AF37);
  static const _terracotta = Color(0xFF8C2D19);

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final couponsAsync = ref.read(_activeCouponsRawProvider);
    final coupons = couponsAsync.value ?? [];
    final code = _couponController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _couponError = 'Please enter a promo code.';
        _couponSuccess = null;
      });
      return;
    }

    final applied =
        ref.read(cartProvider.notifier).applyCoupon(code, coupons);

    setState(() {
      if (applied) {
        final discount =
            ref.read(cartProvider).discountPercentage.toInt();
        _couponSuccess =
            '🎉 "$code" applied! You save $discount% on this order.';
        _couponError = null;
      } else {
        _couponError = 'Invalid or expired promo code.';
        _couponSuccess = null;
      }
    });
  }

  void _removeCoupon() {
    ref.read(cartProvider.notifier).removeCoupon();
    _couponController.clear();
    setState(() {
      _couponError = null;
      _couponSuccess = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final items = cart.items.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
                _couponController.clear();
                setState(() {
                  _couponError = null;
                  _couponSuccess = null;
                });
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
        ],
      ),
      body: items.isEmpty ? _buildEmptyCart(context) : _buildCartBody(context, cart, items),
      bottomNavigationBar: items.isEmpty
          ? null
          : _buildCheckoutBar(context, cart),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore our handcrafted collection',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/explore'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Explore Products',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartBody(
      BuildContext context, CartState cart, List items) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        // --- Item list ---
        ...items.map((item) => _buildCartItem(context, item)),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),

        // --- Promo Code Section ---
        _buildPromoSection(cart),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),

        // --- Order Summary ---
        _buildOrderSummary(cart),
      ],
    );
  }

  Widget _buildCartItem(BuildContext context, item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackImage(),
                  )
                : _fallbackImage(),
          ),
          const SizedBox(width: 12),

          // Name & Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: _gold, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Quantity stepper
          Row(
            children: [
              _stepperButton(
                icon: Icons.remove,
                onTap: () => ref
                    .read(cartProvider.notifier)
                    .updateQuantity(item.productId, item.quantity - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              _stepperButton(
                icon: Icons.add,
                onTap: () => ref
                    .read(cartProvider.notifier)
                    .updateQuantity(item.productId, item.quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _gold.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 16, color: _gold),
      ),
    );
  }

  Widget _buildPromoSection(CartState cart) {
    final hasCoupon = cart.appliedCouponCode != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Promo Code',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),

        if (hasCoupon)
          // Applied coupon chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _gold.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    color: _gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${cart.appliedCouponCode} — ${cart.discountPercentage.toInt()}% OFF',
                    style: const TextStyle(
                        color: _gold, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: _removeCoupon,
                  child: const Icon(Icons.close, size: 18, color: _gold),
                ),
              ],
            ),
          )
        else ...[
          // Input + Apply button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _gold, width: 1.5),
                    ),
                    errorText: _couponError,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _applyCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _terracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_couponSuccess != null) ...[
            const SizedBox(height: 8),
            Text(
              _couponSuccess!,
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildOrderSummary(CartState cart) {
    final hasDiscount = cart.discountPercentage > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _summaryRow('Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}'),
        if (hasDiscount) ...[
          const SizedBox(height: 6),
          _summaryRow(
            'Discount (${cart.discountPercentage.toInt()}%)',
            '-\$${cart.discountAmount.toStringAsFixed(2)}',
            valueColor: Colors.green,
          ),
        ],
        const SizedBox(height: 6),
        _summaryRow('Shipping', 'Free', valueColor: Colors.green),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),
        _summaryRow(
          'Total',
          '\$${cart.total.toStringAsFixed(2)}',
          isBold: true,
          valueColor: _terracotta,
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: isBold ? 17 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value,
            style: style.copyWith(
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            )),
      ],
    );
  }

  Widget _buildCheckoutBar(BuildContext context, CartState cart) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: ElevatedButton(
        onPressed: () => context.push('/checkout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _terracotta,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          'Proceed to Checkout — \$${cart.total.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported,
          color: Colors.grey, size: 28),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../order/providers/cart_provider.dart';
import '../../home/providers/home_provider.dart'; // Import unified search state

class ProductModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final String? imageUrl;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String? fetchedImageUrl;
    if (json['product_images'] != null && (json['product_images'] as List).isNotEmpty) {
      fetchedImageUrl = json['product_images'][0]['image_url'];
    }

    return ProductModel(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      imageUrl: fetchedImageUrl,
    );
  }
}

// Renamed to avoid conflict with home_provider's selectedCategoryProvider
final exploreCategoryProvider = StateProvider<String>((ref) => 'All');

// Future Provider to fetch data from Supabase
final exploreProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase.from('products').select('''
    *,
    product_images (
      image_url,
      is_primary
    )
  ''');

  return (response as List<dynamic>).map((item) => ProductModel.fromJson(item)).toList();
});

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Initialize controller with current shared provider value
    final initialQuery = ref.read(searchQueryProvider);
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep text controller synchronized if cleared or modified on other screens
    ref.listen<String>(searchQueryProvider, (previous, next) {
      if (_searchController.text != next) {
        _searchController.text = next;
      }
    });

    final selectedCategory = ref.watch(exploreCategoryProvider);
    final productsAsyncValue = ref.watch(exploreProductsProvider);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore Gifts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Consumer(
              builder: (context, ref, child) {
                final cart = ref.watch(cartProvider);
                final itemCount = cart.values.fold<int>(0, (sum, item) => sum + item.quantity);

                if (itemCount == 0) {
                  return const Icon(Icons.shopping_cart_outlined);
                }

                return Badge(
                  label: Text(itemCount.toString()),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.shopping_cart_outlined),
                );
              },
            ),
            onPressed: () => context.push('/cart'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: productsAsyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: goldColor),
        ),
        error: (error, stack) => Center(
          child: Text('Error loading products: $error'),
        ),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products available yet.'));
          }

          final List<String> categories = ['All'];
          categories.addAll(products.map((p) => p.category).toSet().toList());

          // Unified Matrix Filtering: Apply both active Category and active Search Text
          final filteredProducts = products.where((p) {
            final matchesCategory = selectedCategory == 'All' || p.category == selectedCategory;

            final nameMatches = p.name.toLowerCase().contains(searchQuery);
            final catMatches = p.category.toLowerCase().contains(searchQuery);
            final matchesSearch = searchQuery.isEmpty || nameMatches || catMatches;

            return matchesCategory && matchesSearch;
          }).toList();

          return Column(
            children: [
              // --- UNIFIED INLINE SEARCH BAR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => ref.read(searchQueryProvider.notifier).updateQuery(value),
                  decoration: InputDecoration(
                    hintText: 'Search cultural items, crafts...',
                    prefixIcon: const Icon(Icons.search, color: goldColor),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              ref.read(searchQueryProvider.notifier).updateQuery('');
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: goldColor, width: 1.5),
                    ),
                  ),
                ),
              ),

              // --- CATEGORY FILTER SECTION ---
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: goldColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? goldColor : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? goldColor : Colors.grey.shade300,
                          ),
                        ),
                        onSelected: (bool selected) {
                          ref.read(exploreCategoryProvider.notifier).state = category;
                        },
                      ),
                    );
                  },
                ),
              ),

              // --- PRODUCT GRID SECTION ---
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(
                        child: Text('No matching products found.'),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductCard(context, product);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return GestureDetector(
      onTap: () {
        context.push('/products/${product.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => _fallbackImage(),
                      )
                    : _fallbackImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
    );
  }
}
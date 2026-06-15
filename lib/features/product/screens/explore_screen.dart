import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../order/providers/cart_provider.dart';

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

// 2. State Provider for the selected category tab
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

// 3. Future Provider to fetch data from Supabase
final exploreProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final supabase = Supabase.instance.client;
  
  // Query products and join with product_images
  final response = await supabase.from('products').select('''
    *,
    product_images (
      image_url,
      is_primary
    )
  ''');

  // Convert the JSON response into a list of ProductModels
  return (response as List<dynamic>).map((item) => ProductModel.fromJson(item)).toList();
});

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final productsAsyncValue = ref.watch(exploreProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore Gifts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final products = productsAsyncValue.asData?.value ?? [];
              if (products.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Products are still loading.')),
                );
                return;
              }

              final selectedProduct = await showSearch<ProductModel?>(
                context: context,
                delegate: ProductSearchDelegate(products),
              );

              if (selectedProduct != null) {
                context.push('/products/${selectedProduct.id}');
              }
            },
          ),

          IconButton(
          icon: Consumer(
            builder: (context, ref, child) {
              // Read the cart state
              final cart = ref.watch(cartProvider);
              // Calculate total items (sum of quantities)
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
        ],
      ),
      // Handle Loading, Error, and Data states dynamically
      body: productsAsyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
        error: (error, stack) => Center(
          child: Text('Error loading products: $error'),
        ),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products available yet.'));
          }

          // Dynamically extract unique categories from the fetched products
          final List<String> categories = ['All'];
          categories.addAll(products.map((p) => p.category).toSet().toList());

          // Filter products based on the selected category
          final filteredProducts = selectedCategory == 'All'
              ? products
              : products.where((p) => p.category == selectedCategory).toList();

          return Column(
            children: [
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
                        selectedColor: const Color(0xFFD4AF37).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFFD4AF37) : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.shade300,
                          ),
                        ),
                        onSelected: (bool selected) {
                          ref.read(selectedCategoryProvider.notifier).state = category;
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
                        child: Text('No products found in this category.'),
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
            // Product Image (Handles Network Image from Supabase URL)
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
            // Product Info
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

class ProductSearchDelegate extends SearchDelegate<ProductModel?> {
  ProductSearchDelegate(this.products);

  final List<ProductModel> products;

  @override
  String get searchFieldLabel => 'Search gifts';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultList(context);
  }

  Widget _buildResultList(BuildContext context) {
    final searchQuery = query.trim().toLowerCase();
    final filtered = searchQuery.isEmpty
        ? products
        : products.where((product) {
            final combined = '${product.name} ${product.category}'.toLowerCase();
            return combined.contains(searchQuery);
          }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No matching products found.'),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final product = filtered[index];
        return ListTile(
          title: Text(product.name),
          subtitle: Text(product.category),
          trailing: Text('\$${product.price.toStringAsFixed(2)}'),
          onTap: () => close(context, product),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'product_model.dart';
import 'product_detail_screen.dart';
import 'currency_service.dart';
import 'shop_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<ProductModel> get _wishlistedProducts =>
      mockProducts.where((p) => p.isWishlisted).toList();

  @override
  Widget build(BuildContext context) {
    final products = _wishlistedProducts;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Wishlist',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: products.isEmpty ? _buildEmptyState() : _buildGrid(products),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('Your wishlist is empty', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Text(
            'Tap the heart on any product to save it here.',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Browse the Shop', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<ProductModel> products) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) {
          return _WishlistCard(
            product: products[index],
            onChanged: () => setState(() {}),
          );
        },
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onChanged;

  const _WishlistCard({required this.product, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
        ).then((_) => onChanged());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product_${product.id}',
                    child: Image.asset(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image_outlined, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        product.isWishlisted = false;
                        onChanged();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.favorite, size: 16, color: Colors.pinkAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: CurrencyService.instance,
            builder: (context, _) {
              return Text(
                CurrencyService.instance.formatFromPriceString(product.price),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: -0.2),
              );
            },
          ),
        ],
      ),
    );
  }
}
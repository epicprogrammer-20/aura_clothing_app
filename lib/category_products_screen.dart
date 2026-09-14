import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'category_model.dart';
import 'product_model.dart';
import 'product_detail_screen.dart';

class CategoryProductsScreen extends StatelessWidget {
  final CategoryModel category;

  const CategoryProductsScreen({super.key, required this.category});

  // Matches products whose `category` field equals this category's label.
  // NOTE: mock products currently use categories like "Outerwear"/"Suits"/
  // "Knitwear", while mockCategories uses "Shirts"/"Hoodies"/"Caps"/"Shorts"
  // — so most categories will show empty right now. This is expected with
  // placeholder data; once real products are added with matching category
  // values, results will populate automatically. No code change needed
  // later, just real data.
  List<ProductModel> get _matchingProducts {
    return mockProducts
        .where((p) => p.category.toLowerCase() == category.label.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _matchingProducts;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          category.label,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: products.isEmpty
          ? _buildEmptyState()
          : MasonryGridView.count(
        padding: const EdgeInsets.all(12),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _ProductCard(product: products[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No ${category.label.toLowerCase()} yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check back soon — new items are added regularly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: 'product_${product.id}',
              child: Image.network(
                product.imageUrl,
                height: product.imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: product.imageHeight,
                    color: Colors.grey[200],
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: product.imageHeight,
                  color: Colors.grey[200],
                  child: Icon(Icons.image_outlined, color: Colors.grey[400]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              Text(
                product.price,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
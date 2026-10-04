import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'category_model.dart';
import 'product_model.dart';
import 'product_detail_screen.dart';
import 'currency_service.dart';

/// Shared screen behind every category banner on the Shop screen (Women,
/// Men, Sport, Accessories, Headwear — Promotion goes to DealsScreen
/// instead). Each category gets its own dedicated screen file
/// (women_screen.dart, men_screen.dart, ...) that just hands its
/// CategoryModel to this widget, so the banner tap genuinely opens "its
/// own screen" while the layout stays in one place to maintain.
class CategoryShowcaseScreen extends StatelessWidget {
  final CategoryModel category;

  const CategoryShowcaseScreen({super.key, required this.category});

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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                category.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    category.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: category.backgroundColor,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Shop ${category.label}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          if (products.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childCount: products.length,
                itemBuilder: (context, index) => _ProductCard(product: products[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
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
              child: Image.asset(
                product.imageUrl,
                height: product.imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: product.imageHeight,
                  color: Colors.grey[200],
                  child: Icon(Icons.image_outlined, color: Colors.grey[400]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          AnimatedBuilder(
            animation: CurrencyService.instance,
            builder: (context, _) => Text(
              CurrencyService.instance.formatFromPriceString(product.price),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

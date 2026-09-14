import 'package:flutter/material.dart';
import 'category_model.dart';

// Reusable colored category tile used on both Home (horizontal scroll)
// and the Shop screen (grid). Fills whatever width its parent gives it —
// wrap in a SizedBox(width: ...) for a fixed-width list item, or let a
// GridView cell size it automatically.
class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;
  final double height;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: category.backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: 0,
              top: 0,
              width: height * 0.9,
              child: Image.network(
                category.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 12,
              child: Text(
                category.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
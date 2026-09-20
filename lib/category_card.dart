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
    // Container can't literally size itself to double.infinity — when a
    // caller (e.g. a GridView cell) passes it, that means "fill whatever
    // bounded height the parent already gives me," not "grow forever."
    // The parent's tight constraints (from GridView/SizedBox) still apply
    // even when we pass null here.
    final bool fillParentHeight = height.isInfinite;

    // The decorative image width was previously derived from `height`.
    // When height is unbounded we don't have a number to derive from,
    // so fall back to a fixed width that matches the original proportions.
    final double imageWidth = fillParentHeight ? 100 : height * 0.9;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: fillParentHeight ? null : height,
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
              width: imageWidth,
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
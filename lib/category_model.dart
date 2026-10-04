import 'package:flutter/material.dart';

class CategoryModel {
  final String label;
  final Color backgroundColor;
  final String imageUrl;
  final IconData icon; // used only as a fallback icon in empty states

  CategoryModel({
    required this.label,
    required this.backgroundColor,
    required this.imageUrl,
    required this.icon,
  });
}

// Local pictures (no internet needed). These reuse photos you already have;
// swap each path for dedicated category photography whenever you like.
final List<CategoryModel> mockCategories = [
  CategoryModel(
    label: 'Women',
    backgroundColor: const Color(0xFFB5473A),
    imageUrl:
    'assets/images/products/pinkhoofd.png',
    icon: Icons.woman_outlined,
  ),
  CategoryModel(
    label: 'Men',
    backgroundColor: const Color(0xFF2B2B2B),
    imageUrl:
    'assets/images/models/josh1.png',
    icon: Icons.man_outlined,
  ),
  CategoryModel(
    label: 'Sport',
    backgroundColor: const Color(0xFFE39FB8),
    imageUrl:
    'assets/images/products/bluehood.png',
    icon: Icons.sports_outlined,
  ),
  CategoryModel(
    label: 'Promotion',
    backgroundColor: const Color(0xFFD9A441),
    imageUrl:
    'assets/images/products/greenhood.png',
    icon: Icons.local_offer_outlined,
  ),
  CategoryModel(
    label: 'Accessories',
    backgroundColor: const Color(0xFFB9AEDC),
    imageUrl:
    'assets/images/products/hat.png',
    icon: Icons.watch_outlined,
  ),
  CategoryModel(
    label: 'Headwear',
    backgroundColor: const Color(0xFF5A7A6D),
    imageUrl:
    'assets/images/products/hat.png',
    icon: Icons.trending_up_outlined,
  ),
];

// Looks a category up by its display label (e.g. from a tapped banner).
// Falls back to the first category if the label is somehow unknown, since
// every caller already has a valid CategoryModel.label in hand.
CategoryModel categoryByLabel(String label) {
  return mockCategories.firstWhere(
        (c) => c.label.toLowerCase() == label.toLowerCase(),
    orElse: () => mockCategories.first,
  );
}
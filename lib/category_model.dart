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

// Placeholder images — swap for real brand photography once available.
final List<CategoryModel> mockCategories = [
  CategoryModel(
    label: 'Women',
    backgroundColor: const Color(0xFFB5473A),
    imageUrl:
    'https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80&w=400',
    icon: Icons.woman_outlined,
  ),
  CategoryModel(
    label: 'Men',
    backgroundColor: const Color(0xFF2B2B2B),
    imageUrl:
    'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=400',
    icon: Icons.man_outlined,
  ),
  CategoryModel(
    label: 'Sport',
    backgroundColor: const Color(0xFFE39FB8),
    imageUrl:
    'https://images.unsplash.com/photo-1517960413843-0aee8e2b3285?q=80&w=400',
    icon: Icons.sports_outlined,
  ),
  CategoryModel(
    label: 'Promotion',
    backgroundColor: const Color(0xFFD9A441),
    imageUrl:
    'https://images.unsplash.com/photo-1445205170230-053b83016050?q=80&w=400',
    icon: Icons.local_offer_outlined,
  ),
  CategoryModel(
    label: 'Accessories',
    backgroundColor: const Color(0xFFB9AEDC),
    imageUrl:
    'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?q=80&w=400',
    icon: Icons.watch_outlined,
  ),
  CategoryModel(
    label: 'Headwear',
    backgroundColor: const Color(0xFF5A7A6D),
    imageUrl:
    'https://images.unsplash.com/photo-1490114538077-0a7f8cb49891?q=80&w=400',
    icon: Icons.trending_up_outlined,
  ),
];
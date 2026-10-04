import 'package:flutter/material.dart';

class ProductModel {
  final String id;
  final String title;
  final String price;
  final String imageUrl;
  final double imageHeight;
  final String category;
  bool isWishlisted;

  // Who posted/is wearing this look.
  final String? postedByName;
  final String? postedByAvatarUrl;
  final String? instagramHandle;
  final String? facebookUrl;

  // true only when the photo actually shows a person wearing the item.
  final bool personVisible;

  // Used by the Shop screen (filters, badges, quick add).
  final List<Color> colors;
  final List<String> sizes;
  final String? badge; // 'NEW', 'LIMITED', or null
  final bool inStock;

  // NEW — additional images for the product detail carousel.
  // The detail screen should show [imageUrl, ...imageUrls] as the full set.
  final List<String> imageUrls;

  // Placeholder engagement stats powering the Home screen's "Most Viewed"
  // and "New" tabs. Replace with real numbers from analytics/the catalog
  // API once the backend is wired up — viewCount should come from actual
  // page-view tracking, and addedAt from the product's real creation date.
  final int viewCount;
  final DateTime addedAt;

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.imageHeight,
    required this.category,
    this.isWishlisted = false,
    this.postedByName,
    this.postedByAvatarUrl,
    this.instagramHandle,
    this.facebookUrl,
    this.personVisible = false,
    this.colors = const [Colors.black, Colors.white],
    this.sizes = const ['S', 'M', 'L', 'XL'],
    this.badge,
    this.inStock = true,
    this.imageUrls = const [],
    this.viewCount = 0,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime(2026, 1, 1);

  // Parses "$189" / "$1,299.00" -> 189.0 / 1299.0, for sorting & filtering.
  double get priceValue {
    final cleaned = price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  // Convenience: all images for the detail carousel, hero first.
  List<String> get allImages => [imageUrl, ...imageUrls];
}

// ─────────────────────────────────────────────────────────
// MOCK DATA — replace with results from your real search/
// product API once the backend is wired up.
// ─────────────────────────────────────────────────────────
final List<ProductModel> mockProducts = [
  ProductModel(
    id: '1',
    title: 'Black Aura Hoodie',
    price: '\$189',
    imageUrl: 'assets/images/products/blavkhood.png',
    imageHeight: 220,
    category: 'Outerwear',
    postedByName: 'Jordan K.',
    instagramHandle: 'jordan.k',
    personVisible: false,
    badge: 'NEW',
    viewCount: 2140,
    addedAt: DateTime(2026, 8, 20),
  ),
  ProductModel(
    id: '2',
    title: 'Blue Aura Hoodie',
    price: '\$265',
    imageUrl: 'assets/images/products/bluehood.png',
    imageHeight: 300,
    category: 'Outerwear',
    postedByName: 'Mia Santos',
    instagramHandle: 'miasantos',
    facebookUrl: 'https://facebook.com/miasantos',
    personVisible: false,
    viewCount: 3510,
    addedAt: DateTime(2026, 7, 12),
  ),
  ProductModel(
    id: '3',
    title: 'Green Aura Hoodie',
    price: '\$210',
    imageUrl: 'assets/images/products/greenhood.png',
    imageHeight: 260,
    category: 'Outerwear',
    personVisible: false,
    viewCount: 980,
    addedAt: DateTime(2026, 6, 30),
  ),
  ProductModel(
    id: '4',
    title: 'Aura Cap',
    price: '\$78',
    imageUrl: 'assets/images/products/hat.png',
    imageHeight: 240,
    category: 'Accessories',
    postedByName: 'Theo Brandt',
    instagramHandle: 'theobrandt',
    personVisible: false,
    viewCount: 1420,
    addedAt: DateTime(2026, 9, 5),
  ),
  ProductModel(
    id: '5',
    title: 'Pink Aura Hoodie',
    price: '\$130',
    imageUrl: 'assets/images/products/pinkhoofd.png',
    imageHeight: 280,
    category: 'Outerwear',
    personVisible: false,
    inStock: false,
    viewCount: 640,
    addedAt: DateTime(2026, 5, 18),
  ),
  ProductModel(
    id: '6',
    title: 'Black Puffer Jacket',
    price: '\$195',
    imageUrl: 'assets/images/products/pufferblack.png',
    imageHeight: 320,
    category: 'Outerwear',
    postedByName: 'Aura Studio',
    instagramHandle: 'aura.studio',
    facebookUrl: 'https://facebook.com/aurastudio',
    personVisible: false,
    badge: 'LIMITED',
    viewCount: 4220,
    addedAt: DateTime(2026, 9, 18),
  ),
  ProductModel(
    id: '7',
    title: 'Aura Signature Tee',
    price: '\$65',
    imageUrl: 'assets/images/models/josh1.png',
    imageUrls: const [
      'assets/images/models/josh2.png',
      'assets/images/models/josh3.png',
    ],
    imageHeight: 280,
    category: 'Tops',
    postedByName: 'Josh',
    personVisible: true,
    badge: 'NEW',
    viewCount: 1875,
    addedAt: DateTime(2026, 9, 22),
  ),
];
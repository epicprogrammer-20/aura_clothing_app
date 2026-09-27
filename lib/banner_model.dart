import 'package:flutter/material.dart';

class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final String imageUrl;
  final Color backgroundColor;

  // This is the field your future admin panel will toggle on/off.
  // Filter mockBanners by isActive when building the carousel so a banner
  // disappears the moment an admin switches it off — no other code changes.
  bool isActive;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.imageUrl,
    required this.backgroundColor,
    this.isActive = true,
  });
}

// ─────────────────────────────────────────────────────────
// MOCK DATA — once the admin panel exists, this list should come
// from your backend instead (Firestore collection, REST endpoint, etc.),
// with isActive controlled by the admin toggle.
// ─────────────────────────────────────────────────────────
final List<BannerModel> mockBanners = [
  BannerModel(
    id: 'banner1',
    title: 'Get discounts on fashion day',
    subtitle: 'Up to 50%',
    buttonLabel: 'Get Now',
    imageUrl: 'assets/images/banners/banner1.png',
    backgroundColor: const Color(0xFF415A7E),
  ),
  BannerModel(
    id: 'banner2',
    title: 'New arrivals just dropped',
    subtitle: 'Shop the collection',
    buttonLabel: 'Explore',
    imageUrl: 'assets/images/banners/banner2.png',
    backgroundColor: const Color(0xFFE1E8F0),
  ),
  BannerModel(
    id: 'banner3',
    title: 'Free shipping this weekend',
    subtitle: 'On all orders over \$50',
    buttonLabel: 'Learn More',
    imageUrl: 'assets/images/banners/banner3.png',
    backgroundColor: const Color(0xFFE8E4F0),
    isActive: false, // example of a banner an admin has switched off
  ),
  BannerModel(
    id: 'banner4',
    title: "Don't miss out —",
    subtitle: 'Save up to 50% on your favorite products.',
    buttonLabel: 'Shop Now',
    imageUrl: 'assets/images/banners/banner2.png',
    backgroundColor: const Color(0xFF1B2A4A),
  ),
];
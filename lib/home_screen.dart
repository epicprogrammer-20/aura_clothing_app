import 'dart:async';

import 'package:flutter/material.dart';
import 'product_model.dart';
import 'product_detail_screen.dart';
import 'review_model.dart';
import 'deal_model.dart';
import 'search_product_preview_screen.dart';
import 'my_lab_coming_soon_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'cart_service.dart';
import 'cart_screen.dart';
import 'currency_service.dart';
import 'auth_service.dart';
import 'deals_screen.dart';
import 'notifications_screen.dart';
import 'wishlist_screen.dart';
import 'app_colors.dart';

// Photo used for the big hero at the top of Home. Swap this for your own
// lookbook image whenever you like (add it to assets/ and pubspec.yaml).
const String kHomeHeroImage = 'assets/images/models/josh1.png';

// Picture for the "My Lab" banner. Add the file to assets/images/ and list
// it under `assets:` in pubspec.yaml.
const String kMyLabBannerImage = 'assets/images/my_lab_banner.png';

// Picture behind the "Limited time" deal card. Add the file to
// assets/images/ and list it under `assets:` in pubspec.yaml.
const String kDealBannerImage = 'assets/images/deal_banner.png';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  // Live countdown for the "Limited time" deal card.
  Timer? _timer;
  DateTime? _dealEnd;
  Duration _remaining = Duration.zero;
  double _maxDiscount = 0;

  @override
  void initState() {
    super.initState();
    CurrencyService.instance.detectFromLocationOrLocale();

    if (mockDeals.isNotEmpty) {
      _dealEnd = mockDeals
          .map((d) => d.endsAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      _maxDiscount = mockDeals
          .map((d) => d.discountPercent)
          .reduce((a, b) => a > b ? a : b);
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final end = _dealEnd;
    if (end == null || !mounted) return;
    final diff = end.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _navigateAndReset(int index, Widget screen) async {
    setState(() => _navIndex = index);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() => _navIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildTopBar(context),
            _buildHero(),
            const SizedBox(height: 26),
            _buildShopTheLook(),
            const SizedBox(height: 28),
            _buildJustDropped(),
            const SizedBox(height: 28),
            _buildMyLabBanner(),
            const SizedBox(height: 28),
            _buildShopByCategory(),
            if (_dealEnd != null) ...[
              const SizedBox(height: 24),
              _buildDealCard(),
            ],
            const SizedBox(height: 28),
            _buildMostLoved(),
            const SizedBox(height: 28),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: (index) {
            if (index == 0) {
              setState(() => _navIndex = 0);
              return;
            }
            switch (index) {
              case 1:
                _navigateAndReset(1, const SearchScreen());
                break;
              case 2:
                _navigateAndReset(2, const ShopScreen());
                break;
              case 3:
                _navigateAndReset(3, const DealsScreen());
                break;
              case 4:
                _navigateAndReset(4, const ProfileScreen());
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 23),
              activeIcon: Icon(Icons.home, size: 23),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 23),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined, size: 23),
              activeIcon: Icon(Icons.storefront, size: 23),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_offer_outlined, size: 23),
              activeIcon: Icon(Icons.local_offer, size: 23),
              label: 'Deals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 23),
              activeIcon: Icon(Icons.person, size: 23),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/aura_logo.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          Row(
            children: [
              AnimatedBuilder(
                animation: CartService.instance,
                builder: (context, _) {
                  final itemCount = CartService.instance.itemCount;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.shopping_cart_outlined,
                              size: 24, color: Colors.black87),
                          if (itemCount > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  itemCount > 9 ? '9+' : '$itemCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WishlistScreen()),
                  );
                  if (mounted) setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.favorite_border, size: 24, color: Colors.black87),
                      if (mockProducts.any((p) => p.isWishlisted))
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.notifications_outlined, size: 24, color: Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ───────────────────────── Navigation helpers ─────────────────────────

  void _openShop([String? filter]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShopScreen(initialFilter: filter)),
    );
  }

  void _openProduct(ProductModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
    );
  }

  // ───────────────────────── Shared bits ─────────────────────────

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Colors.black,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Row(
                children: [
                  Text(
                    'See all',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 13, color: Colors.black54),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _photo(String path, {BoxFit fit = BoxFit.cover}) {
    return Image.asset(
      path,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[300],
        child: Icon(Icons.image_outlined, color: Colors.grey[500]),
      ),
    );
  }

  Widget _price(ProductModel p, {double size = 13, FontWeight? weight}) {
    return AnimatedBuilder(
      animation: CurrencyService.instance,
      builder: (context, _) => Text(
        CurrencyService.instance.formatFromPriceString(p.price),
        style: TextStyle(
          fontSize: size,
          fontWeight: weight ?? FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  // ───────────────────────── 1. Hero ─────────────────────────

  Widget _buildHero() {
    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _photo(kHomeHeroImage),
          // Dark fade so the white text is always readable.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xCC000000)],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEW SEASON',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DEFINED BY\nSIMPLICITY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Timeless pieces. Modern staples.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _openShop,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SHOP THE DROP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 15, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── 2. Shop the look ─────────────────────────
  // Every photo of a product that shows a person wearing it becomes a card.

  Widget _buildShopTheLook() {
    final looks = <MapEntry<ProductModel, String>>[];
    for (final p in mockProducts.where((p) => p.personVisible)) {
      for (final img in p.allImages) {
        looks.add(MapEntry(p, img));
      }
    }
    if (looks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Shop the look', onSeeAll: () => _openShop()),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: looks.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final product = looks[i].key;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchProductPreviewScreen(product: product),
                  ),
                ),
                child: SizedBox(
                  width: 128,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _photo(looks[i].value),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'MODEL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ───────────────────────── 3. Just dropped ─────────────────────────

  Widget _buildJustDropped() {
    final products = List<ProductModel>.from(mockProducts)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    final items = products.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Just dropped',
            onSeeAll: () => _openShop('New Arrivals')),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final p = items[i];
              return GestureDetector(
                onTap: () => _openProduct(p),
                child: SizedBox(
                  width: 104,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: const Color(0xFFF2F2F2),
                            child: Hero(
                              tag: 'home_new_${p.id}',
                              child: _photo(p.imageUrl),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      _price(p, size: 11.5),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  // ───────────────────────── My Lab banner ─────────────────────────

  Widget _buildMyLabBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyLabComingSoonScreen()),
      ),
      child: Container(
        height: 170,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: const Color(0xFF1A1A1A)),
              _photo(kMyLabBannerImage),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xCC000000), Color(0x22000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BUILD YOUR LOOK',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Mix. Match.\nWear it your way.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'My Lab',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward,
                              size: 15, color: Colors.black),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── 4. Shop by category ─────────────────────────

  Widget _buildShopByCategory() {
    // label shown on the tile -> filter chip opened in the Shop screen.
    const tiles = <MapEntry<String, String>>[
      MapEntry('Outerwear', 'Outerwear'),
      MapEntry('Tops', 'Tops'),
      MapEntry('Accessories', 'Accessories'),
      MapEntry('New arrivals', 'New Arrivals'),
    ];

    String? imageFor(String filter) {
      if (filter == 'New Arrivals') {
        final sorted = List<ProductModel>.from(mockProducts)
          ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
        return sorted.isEmpty ? null : sorted.first.imageUrl;
      }
      for (final p in mockProducts) {
        if (p.category == filter) return p.imageUrl;
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Shop by category', onSeeAll: () => _openShop()),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.45,
            children: [
              for (final t in tiles)
                GestureDetector(
                  onTap: () => _openShop(t.value),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: const Color(0xFF1A1A1A)),
                        if (imageFor(t.value) != null)
                          _photo(imageFor(t.value)!),
                        Container(color: Colors.black.withValues(alpha: 0.5)),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.key.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Row(
                                children: [
                                  Text(
                                    'Shop now',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward,
                                      size: 12, color: Colors.white70),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────── 5. Limited-time deal ─────────────────────────

  Widget _buildDealCard() {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = _remaining;
    final cells = <MapEntry<String, String>>[
      MapEntry(two(d.inDays), 'DAYS'),
      MapEntry(two(d.inHours.remainder(24)), 'HRS'),
      MapEntry(two(d.inMinutes.remainder(60)), 'MIN'),
      MapEntry(two(d.inSeconds.remainder(60)), 'SEC'),
    ];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DealsScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                kDealBannerImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
            // Dark tint so the white text stays easy to read.
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIMITED TIME',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'UP TO ${_maxDiscount.round()}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        'Deals end in',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      for (final c in cells) ...[
                        Column(
                          children: [
                            Container(
                              width: 34,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                c.key,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              c.value,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 8),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── 6. Most loved ─────────────────────────

  Widget _buildMostLoved() {
    final products = List<ProductModel>.from(mockProducts)
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    final items = products.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Most loved', onSeeAll: () => _openShop()),
        const SizedBox(height: 12),
        SizedBox(
          height: 218,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final p = items[i];
              final reviews = reviewsFor(p.id);
              return GestureDetector(
                onTap: () => _openProduct(p),
                child: SizedBox(
                  width: 128,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                color: const Color(0xFFF2F2F2),
                                child: Hero(
                                  tag: 'home_loved_${p.id}',
                                  child: _photo(p.imageUrl),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () {
                                    if (!requireLogin(context,
                                        message:
                                            'Log in to save items to your wishlist')) {
                                      return;
                                    }
                                    setState(
                                        () => p.isWishlisted = !p.isWishlisted);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      p.isWishlisted
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 14,
                                      color: p.isWishlisted
                                          ? Colors.pinkAccent
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      _price(p, size: 12),
                      if (reviews.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.black87),
                            const SizedBox(width: 3),
                            Text(
                              '${averageRating(reviews).toStringAsFixed(1)} (${reviews.length})',
                              style: const TextStyle(
                                  fontSize: 10.5, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'banner_model.dart';
import 'promo_banner_carousel.dart';
import 'product_model.dart';
import 'product_detail_screen.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  int _browseTabIndex = 0;
  static const List<String> _browseTabs = ['Popular', 'Most Viewed', 'Recommended', 'New'];

  @override
  void initState() {
    super.initState();
    CurrencyService.instance.detectFromLocationOrLocale();
  }

  Future<void> _navigateAndReset(int index, Widget screen) async {
    setState(() => _navIndex = index);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() => _navIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final activeBanners = mockBanners.where((b) => b.isActive).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildTopBar(context),
            const SizedBox(height: 16),
            if (activeBanners.isNotEmpty) PromoBannerCarousel(banners: activeBanners),
            const SizedBox(height: 24),
            _buildBrowseTabsRow(),
            const SizedBox(height: 20),
            _buildSectionHeader('Best Seller'),
            const SizedBox(height: 12),
            _buildBestSellerGrid(),
            const SizedBox(height: 24),
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
            height: 28,
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

  Widget _buildBrowseTabsRow() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _browseTabs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final selected = index == _browseTabIndex;
            return GestureDetector(
              onTap: () => setState(() => _browseTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  _browseTabs[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildBestSellerGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: mockProducts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) {
          return _BestSellerCard(product: mockProducts[index]);
        },
      ),
    );
  }
}

class _BestSellerCard extends StatefulWidget {
  final ProductModel product;

  const _BestSellerCard({required this.product});

  @override
  State<_BestSellerCard> createState() => _BestSellerCardState();
}

class _BestSellerCardState extends State<_BestSellerCard> {
  @override
  Widget build(BuildContext context) {
    final product = widget.product;

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
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Hero(
                tag: 'product_${product.id}',
                child: Image.asset(
                  product.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.image_outlined, color: Colors.grey[400]),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (!requireLogin(context, message: 'Log in to save items to your wishlist')) return;
                  setState(() {
                    product.isWishlisted = !product.isWishlisted;
                  });
                },
                child: Icon(
                  product.isWishlisted ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: product.isWishlisted ? Colors.pinkAccent : Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: CurrencyService.instance,
            builder: (context, _) {
              return Text(
                CurrencyService.instance.formatFromPriceString(product.price),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.2,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
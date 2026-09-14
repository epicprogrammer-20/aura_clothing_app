import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'banner_model.dart';
import 'category_model.dart';
import 'category_card.dart';
import 'product_model.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'category_products_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  final PageController _bannerController = PageController();

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
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
            if (activeBanners.isNotEmpty) _buildBannerCarousel(activeBanners),
            const SizedBox(height: 24),
            _buildSectionHeader('Categories'),
            const SizedBox(height: 12),
            _buildCategoriesRow(),
            const SizedBox(height: 24),
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
            if (index == 2) {
              // TODO: open create-post screen once the upload flow is built
              return;
            }
            setState(() => _navIndex = index);
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            }
            if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShopScreen()),
              );
            }
            if (index == 4) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationsScreen()),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
              label: 'Post',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Shop',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                child: Icon(Icons.person_outline, color: Colors.grey[600], size: 20),
              ),
            ),
            const Text(
              'AURA',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: 3,
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: open cart screen
              },
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCarousel(List<BannerModel> banners) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            padEnds: false,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: banner.backgroundColor),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 140,
                        child: Image.network(
                          banner.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 16,
                        right: 150,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner.title,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              banner.subtitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                banner.buttonLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SmoothPageIndicator(
          controller: _bannerController,
          count: banners.length,
          effect: ExpandingDotsEffect(
            dotHeight: 6,
            dotWidth: 6,
            activeDotColor: Colors.black,
            dotColor: Colors.grey[300]!,
          ),
        ),
      ],
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

  // Horizontal scroll of colored image cards — matches the Shop screen's
  // card style so Home and Shop feel consistent.
  Widget _buildCategoriesRow() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: mockCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = mockCategories[index];
          return SizedBox(
            width: 150,
            child: CategoryCard(
              category: category,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CategoryProductsScreen(category: category),
                  ),
                );
              },
            ),
          );
        },
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
          Text(
            product.price,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Hero(
                tag: 'product_${product.id}',
                child: Image.network(
                  product.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(color: Colors.grey[200]);
                  },
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
                  setState(() {
                    product.isWishlisted = !product.isWishlisted;
                  });
                },
                child: Icon(
                  product.isWishlisted ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: product.isWishlisted ? Colors.red : Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
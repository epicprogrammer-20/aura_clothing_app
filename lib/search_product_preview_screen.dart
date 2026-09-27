import 'package:flutter/material.dart';
import 'product_model.dart';
import 'product_detail_screen.dart';
import 'cart_service.dart';
import 'currency_service.dart';
import 'auth_service.dart';
import 'review_model.dart';
import 'deal_model.dart';
import 'app_colors.dart';

class SearchProductPreviewScreen extends StatefulWidget {
  final ProductModel product;

  const SearchProductPreviewScreen({super.key, required this.product});

  @override
  State<SearchProductPreviewScreen> createState() => _SearchProductPreviewScreenState();
}

class _SearchProductPreviewScreenState extends State<SearchProductPreviewScreen> {
  late final PageController _pageController;
  int _currentImageIndex = 0;
  late String _selectedSize;
  bool _showTag = false;

  ProductModel get product => widget.product;

  // Same product throughout — swiping only moves through this product's
  // own photos (imageUrl + imageUrls), never switches to a different item.
  List<String> get _images => product.allImages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _selectedSize = product.sizes.isNotEmpty ? product.sizes.first : 'M';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jumpTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _addToCart() {
    if (!requireLogin(context, message: 'Log in to add items to your cart')) return;
    CartService.instance.addItem(product, _selectedSize, product.colors.first);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} (size $_selectedSize) added to cart'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
      ),
    );
  }

  void _toggleWishlist() {
    if (!requireLogin(context, message: 'Log in to save items to your wishlist')) return;
    setState(() => product.isWishlisted = !product.isWishlisted);
  }

  void _openRealProductPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  void _openSeeDetailSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SeeDetailSheet(
        product: product,
        selectedSize: _selectedSize,
        onSizeSelected: (s) => setState(() => _selectedSize = s),
        onAddToCart: _addToCart,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final currency = CurrencyService.instance;
    final deal = dealForProduct(product.id);
    final images = _images;
    // Shared "no glow" scroll behavior — Android's default overscroll glow
    // pulls its color from the app's Material theme (blue by default),
    // which is what was showing up here. Applied to both the main photo
    // swiper and the thumbnail strip below.
    final noGlowBehavior = ScrollConfiguration.of(context).copyWith(overscroll: false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ScrollConfiguration(
            behavior: noGlowBehavior,
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) => setState(() {
                _currentImageIndex = index;
                _showTag = false;
              }),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: product.personVisible ? () => setState(() => _showTag = !_showTag) : null,
                  child: Image.asset(
                    images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey.shade900,
                      child: Icon(Icons.image_outlined, size: 60, color: Colors.grey.shade600),
                    ),
                  ),
                );
              },
            ),
          ),

          if (product.personVisible && _showTag)
            Positioned(
              left: 0,
              right: 0,
              top: size.height * 0.32,
              child: Center(
                child: GestureDetector(
                  onTap: _openRealProductPage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_offer_outlined, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: size.width * 0.6),
                          child: Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                  _circleButton(
                    icon: product.isWishlisted ? Icons.favorite : Icons.favorite_border,
                    iconColor: product.isWishlisted ? Colors.red : Colors.black,
                    onTap: _toggleWishlist,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: 16,
            top: size.height * 0.42,
            child: Column(
              children: product.sizes.map((s) {
                final selected = s == _selectedSize;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSize = s),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? AppColors.accent : Colors.white,
                        border: Border.all(color: Colors.white, width: selected ? 0 : 1.5),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.85)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (images.length > 1) ...[
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.swipe, size: 18, color: Colors.white70),
                          const SizedBox(height: 4),
                          Text(
                            'Swipe to see more photos',
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: ScrollConfiguration(
                        behavior: noGlowBehavior,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final selected = index == _currentImageIndex;
                            // Fixed size always — no growing/shrinking on
                            // selection. Only the border changes to show
                            // which photo is active, like a tab highlight.
                            return GestureDetector(
                              onTap: () => _jumpTo(index),
                              child: Container(
                                width: 48,
                                height: 48,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? AppColors.accent : Colors.white.withValues(alpha: 0.4),
                                    width: selected ? 2.5 : 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    images[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(color: Colors.grey.shade800),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    product.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: currency,
                    builder: (context, _) {
                      if (deal == null) {
                        return Text(
                          currency.format(product.priceValue),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        );
                      }
                      return Row(
                        children: [
                          Text(
                            currency.format(deal.discountedPrice),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currency.format(product.priceValue),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${deal.discountPercent.toInt()}%',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _openSeeDetailSheet,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text(
                              'See Detail',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _addToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text(
                              'Add To Cart',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap, Color iconColor = Colors.black}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _SeeDetailSheet extends StatelessWidget {
  final ProductModel product;
  final String selectedSize;
  final ValueChanged<String> onSizeSelected;
  final VoidCallback onAddToCart;

  const _SeeDetailSheet({
    required this.product,
    required this.selectedSize,
    required this.onSizeSelected,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final reviews = reviewsFor(product.id);
    final avg = averageRating(reviews);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String localSize = selectedSize;
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.category.toUpperCase(),
                    style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: CurrencyService.instance,
                    builder: (context, _) => Text(
                      CurrencyService.instance.formatFromPriceString(product.price),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Size', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
                  const SizedBox(height: 10),
                  Row(
                    children: product.sizes.map((s) {
                      final selected = s == localSize;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            setSheetState(() => localSize = s);
                            onSizeSelected(s);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? AppColors.accent : Colors.white,
                              border: Border.all(color: selected ? AppColors.accent : Colors.grey.shade300),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
                  const SizedBox(height: 8),
                  Text(
                    'Placeholder product description — replace with real copy '
                        '(materials, fit, care instructions) once your product data is wired up.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text('Reviews', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
                      if (reviews.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.star, size: 13, color: Colors.amber.shade700),
                        const SizedBox(width: 2),
                        Text('${avg.toStringAsFixed(1)} (${reviews.length})', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (reviews.isEmpty)
                    Text('No reviews yet.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500))
                  else
                    ...reviews.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.reviewerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
                          const SizedBox(height: 2),
                          Text(r.comment, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
                        ],
                      ),
                    )),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onAddToCart();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      child: const Text('ADD TO CART', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
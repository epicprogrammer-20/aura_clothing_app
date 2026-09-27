import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'product_model.dart';
import 'deal_model.dart';
import 'cart_service.dart';
import 'currency_service.dart';
import 'auth_service.dart';
import 'search_screen.dart';
import 'size_guide_screen.dart';
import 'review_model.dart';
import 'app_colors.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  // Pass the active deal when this product was opened from the Deals
  // screen, so the discounted price carries through to Add to Cart too.
  final DealModel? deal;

  const ProductDetailScreen({super.key, required this.product, this.deal});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String _selectedSize = 'M';
  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL'];

  bool _showProductTag = false;

  final PageController _imageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  void _addToCart() {
    if (!requireLogin(context, message: 'Log in to add items to your cart')) return;

    CartService.instance.addItem(
      widget.product,
      _selectedSize,
      widget.product.colors.first,
      dealPrice: widget.deal?.discountedPrice,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.title} (size $_selectedSize) added to cart'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
      ),
    );
  }

  void _toggleWishlist() {
    if (!requireLogin(context, message: 'Log in to save items to your wishlist')) return;

    setState(() {
      widget.product.isWishlisted = !widget.product.isWishlisted;
    });
  }

  Future<void> _openSocialLink(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link')),
      );
    }
  }

  void _searchForTag() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(initialQuery: widget.product.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final deal = widget.deal;
    final size = MediaQuery.sizeOf(context);
    final images = product.allImages;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: product.personVisible
                      ? () => setState(() => _showProductTag = !_showProductTag)
                      : null,
                  child: Stack(
                    children: [
                      SizedBox(
                        height: size.height * 0.55,
                        child: PageView.builder(
                          controller: _imageController,
                          itemCount: images.length,
                          onPageChanged: (index) =>
                              setState(() => _currentImageIndex = index),
                          itemBuilder: (context, index) {
                            final img = Container(
                              width: double.infinity,
                              height: size.height * 0.55,
                              color: Colors.grey[100],
                              child: Image.asset(
                                images[index],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: size.height * 0.55,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image_outlined,
                                      size: 60, color: Colors.grey[400]),
                                ),
                              ),
                            );
                            return index == 0
                                ? Hero(tag: 'product_${product.id}', child: img)
                                : img;
                          },
                        ),
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: SmoothPageIndicator(
                                controller: _imageController,
                                count: images.length,
                                effect: const WormEffect(
                                  dotHeight: 6,
                                  dotWidth: 6,
                                  spacing: 6,
                                  activeDotColor: Colors.white,
                                  dotColor: Colors.white38,
                                ),
                                onDotClicked: (index) {
                                  _imageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      if (product.personVisible && _showProductTag)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: size.height * 0.28,
                          child: Center(
                            child: GestureDetector(
                              onTap: _searchForTag,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_offer_outlined,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: size.width * 0.6,
                                      ),
                                      child: Text(
                                        product.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 1,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (deal != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${deal.discountPercent.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: CurrencyService.instance,
                        builder: (context, _) => deal != null
                            ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              CurrencyService.instance.format(product.priceValue),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyService.instance.format(deal.discountedPrice),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        )
                            : Text(
                          CurrencyService.instance.formatFromPriceString(product.price),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Size',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: _sizes.map((s) {
                          final bool isSelected = s == _selectedSize;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedSize = s),
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppColors.accent : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accent
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => SizeGuideSheet.show(context),
                        child: const Text(
                          'Size Guide',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.accent,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Placeholder product description — replace with real '
                            'copy (materials, fit, care instructions) once your '
                            'product data is wired up.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.grey[600],
                        ),
                      ),

                      if (product.postedByName != null) ...[
                        const SizedBox(height: 28),
                        _buildPostedBySection(product),
                      ],

                      const SizedBox(height: 28),
                      _buildReviewsSection(product),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  _circleIconButton(
                    icon: product.isWishlisted
                        ? Icons.favorite
                        : Icons.favorite_border,
                    iconColor: product.isWishlisted ? Colors.red : Colors.black,
                    onTap: _toggleWishlist,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _circleIconButton(
                    icon: product.isWishlisted
                        ? Icons.favorite
                        : Icons.favorite_border,
                    iconColor: product.isWishlisted ? Colors.red : Colors.black,
                    onTap: _toggleWishlist,
                    backgroundColor: Colors.grey[100],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _addToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'ADD TO CART',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Colors.white,
          boxShadow: backgroundColor == null
              ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
            ),
          ]
              : null,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildPostedBySection(ProductModel product) {
    final hasInstagram = product.instagramHandle != null;
    final hasFacebook = product.facebookUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Worn by ${product.postedByName}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),

        if (hasInstagram)
          _socialLinkRow(
            icon: const FaIcon(FontAwesomeIcons.instagram,
                size: 16, color: Colors.black87),
            label: '@${product.instagramHandle}',
            onTap: () => _openSocialLink(
              'https://instagram.com/${product.instagramHandle}',
            ),
          ),

        if (hasFacebook) ...[
          const SizedBox(height: 8),
          _socialLinkRow(
            icon: const FaIcon(FontAwesomeIcons.facebook,
                size: 16, color: Colors.black87),
            label: 'Facebook',
            onTap: () => _openSocialLink(product.facebookUrl!),
          ),
        ],

        if (!hasInstagram && !hasFacebook)
          Text(
            'No linked accounts',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
      ],
    );
  }

  Widget _socialLinkRow({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              decoration: TextDecoration.underline,
              decorationColor: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(ProductModel product) {
    final reviews = reviewsFor(product.id);
    final avg = averageRating(reviews);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Reviews',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            if (reviews.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(Icons.star, size: 14, color: Colors.amber.shade700),
              const SizedBox(width: 2),
              Text(
                '${avg.toStringAsFixed(1)} (${reviews.length})',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          Text(
            'No reviews yet.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          )
        else
          ...reviews.map((r) => _reviewTile(r)),
      ],
    );
  }

  Widget _reviewTile(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.reviewerName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                review.date,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating.round() ? Icons.star : Icons.star_border,
                size: 13,
                color: Colors.amber.shade700,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            review.comment,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
          ),
        ],
      ),
    );
  }
}
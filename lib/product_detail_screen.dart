import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'product_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String _selectedSize = 'M';
  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL'];

  // NEW: controls whether the "worn by [product]" tag is visible over
  // the hero image. Starts hidden — tapping the image toggles it, same
  // interaction pattern as TikTok's "Find Similar" reveal.
  bool _showProductTag = false;

  void _addToCart() {
    // TODO: hook up to real cart state/backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.title} (size $_selectedSize) added to cart'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
      ),
    );
  }

  void _toggleWishlist() {
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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GestureDetector(
                  // NEW: tapping the hero image toggles the tag overlay.
                  // Only meaningful when a person is actually visible in
                  // this photo — otherwise tapping does nothing.
                  onTap: product.personVisible
                      ? () => setState(() => _showProductTag = !_showProductTag)
                      : null,
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'product_${product.id}',
                        child: Image.network(
                          product.imageUrl,
                          width: double.infinity,
                          height: size.height * 0.55,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: size.height * 0.55,
                            color: Colors.grey[200],
                            child: Icon(Icons.image_outlined,
                                size: 60, color: Colors.grey[400]),
                          ),
                        ),
                      ),

                      // NEW: the tag pill itself — hovers on top of the
                      // image, only when toggled on and a person is
                      // visible in the photo.
                      if (product.personVisible && _showProductTag)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: size.height * 0.28,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
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
                      Text(
                        product.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
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
                      Text(
                        product.price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
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
                                  color: isSelected ? Colors.black : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.black
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

                      // Worn by / social links — plain text, no card
                      if (product.postedByName != null) ...[
                        const SizedBox(height: 28),
                        _buildPostedBySection(product),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Back + wishlist buttons over the image
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

          // Sticky bottom bar: Add to Cart
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
                    color: Colors.black.withOpacity(0.06),
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
                          backgroundColor: Colors.black,
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
              color: Colors.black.withOpacity(0.1),
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
}
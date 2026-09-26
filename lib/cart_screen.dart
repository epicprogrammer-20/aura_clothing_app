import 'package:flutter/material.dart';
import 'cart_service.dart';
import 'shop_screen.dart';
import 'currency_service.dart';
import 'checkout_screen.dart';
import 'app_colors.dart';

const double _kTaxRate = 0.10;

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _promoExpanded = false;
  final TextEditingController _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _removeItem(CartItem item) {
    CartService.instance.removeItem(item);
  }

  void _changeQuantity(CartItem item, int delta) {
    CartService.instance.updateQuantity(item, item.quantity + delta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([CartService.instance, CurrencyService.instance]),
        builder: (context, _) {
          final items = CartService.instance.items;

          if (items.isEmpty) {
            return const _EmptyCartView();
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              return isDesktop
                  ? _buildDesktopLayout(items)
                  : _buildMobileLayout(items);
            },
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(List<CartItem> items) {
    final subtotal = CartService.instance.subtotal;
    final tax = subtotal * _kTaxRate;
    final total = subtotal + tax;

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(items.length),
                const SizedBox(height: 32),
                ...items.map(
                      (item) => _CartItemTile(
                    item: item,
                    onRemove: () => _removeItem(item),
                    onIncrement: () => _changeQuantity(item, 1),
                    onDecrement: () => _changeQuantity(item, -1),
                  ),
                ),
                const SizedBox(height: 24),
                _ContinueShoppingLink(),
              ],
            ),
          ),
          const SizedBox(width: 56),
          SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.only(top: 88),
              child: _OrderSummaryPanel(
                subtotal: subtotal,
                tax: tax,
                total: total,
                promoExpanded: _promoExpanded,
                promoController: _promoController,
                onTogglePromo: () =>
                    setState(() => _promoExpanded = !_promoExpanded),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(List<CartItem> items) {
    final subtotal = CartService.instance.subtotal;
    final tax = subtotal * _kTaxRate;
    final total = subtotal + tax;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(items.length),
                const SizedBox(height: 20),
                ...items.map(
                      (item) => _CartItemTile(
                    item: item,
                    onRemove: () => _removeItem(item),
                    onIncrement: () => _changeQuantity(item, 1),
                    onDecrement: () => _changeQuantity(item, -1),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: _ContinueShoppingLink()),
                const SizedBox(height: 32),
                _OrderSummaryPanel(
                  subtotal: subtotal,
                  tax: tax,
                  total: total,
                  promoExpanded: _promoExpanded,
                  promoController: _promoController,
                  onTogglePromo: () =>
                      setState(() => _promoExpanded = !_promoExpanded),
                  showCheckoutButton: false,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _MobileCheckoutBar(total: total),
      ],
    );
  }

  Widget _buildHeader(int itemCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Cart',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatefulWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile> {
  bool _removing = false;

  void _handleRemove() {
    setState(() => _removing = true);
    Future.delayed(const Duration(milliseconds: 180), widget.onRemove);
  }

  String _colorName(Color color) {
    if (color.toARGB32() == Colors.black.toARGB32()) return 'Black';
    if (color.toARGB32() == Colors.white.toARGB32()) return 'White';
    if (color.toARGB32() == Colors.grey.value) return 'Grey';
    return 'Multi';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.item.product;

    return AnimatedOpacity(
      opacity: _removing ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _removing ? const Offset(0.05, 0) : Offset.zero,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: _removing
              ? const SizedBox(width: double.infinity)
              : Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 96,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.image_outlined,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          _IconTapButton(
                            icon: product.isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: product.isWishlisted
                                ? Colors.pinkAccent
                                : Colors.black,
                            onTap: () {
                              setState(() {
                                product.isWishlisted =
                                !product.isWishlisted;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.category} · ${_colorName(widget.item.color)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Size: ${widget.item.size}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        CurrencyService.instance
                            .formatFromPriceString(product.price),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _QuantitySelector(
                            quantity: widget.item.quantity,
                            onIncrement: widget.onIncrement,
                            onDecrement: widget.onDecrement,
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _handleRemove,
                            child: Text(
                              'Remove',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconTapButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconTapButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Icon(
            icon,
            key: ValueKey(icon),
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantitySelector({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyButton(icon: Icons.remove, onTap: onDecrement),
          SizedBox(
            width: 28,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  '$quantity',
                  key: ValueKey(quantity),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          _qtyButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 14, color: Colors.black),
      ),
    );
  }
}

class _OrderSummaryPanel extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double total;
  final bool promoExpanded;
  final TextEditingController promoController;
  final VoidCallback onTogglePromo;
  final bool showCheckoutButton;

  const _OrderSummaryPanel({
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.promoExpanded,
    required this.promoController,
    required this.onTogglePromo,
    this.showCheckoutButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORDER SUMMARY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _summaryRow('Subtotal', CurrencyService.instance.format(subtotal)),
          const SizedBox(height: 10),
          _summaryRow('Shipping', 'Calculated at checkout', isMuted: true),
          const SizedBox(height: 10),
          _summaryRow('Tax', CurrencyService.instance.format(tax)),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  CurrencyService.instance.format(total),
                  key: ValueKey('${CurrencyService.instance.currencyCode}_$total'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _PromoCodeSection(
            expanded: promoExpanded,
            controller: promoController,
            onToggle: onTogglePromo,
          ),
          if (showCheckoutButton) ...[
            const SizedBox(height: 24),
            _CheckoutButton(total: total),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isMuted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isMuted ? FontWeight.w400 : FontWeight.w600,
            color: isMuted ? Colors.grey.shade500 : Colors.black,
          ),
        ),
      ],
    );
  }
}

class _PromoCodeSection extends StatelessWidget {
  final bool expanded;
  final TextEditingController controller;
  final VoidCallback onToggle;

  const _PromoCodeSection({
    required this.expanded,
    required this.controller,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Have a promo code?',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down, size: 18),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
          expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Enter promo code',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppColors.accent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.black,
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'Promo code applied',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Apply',
                      style: TextStyle(fontSize: 12, color: AppColors.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckoutButton extends StatefulWidget {
  final double total;
  const _CheckoutButton({required this.total});

  @override
  State<_CheckoutButton> createState() => _CheckoutButtonState();
}

class _CheckoutButtonState extends State<_CheckoutButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              );
            },
            child: const Text(
              'CHECKOUT →',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileCheckoutBar extends StatelessWidget {
  final double total;
  const _MobileCheckoutBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    'CHECKOUT · ${CurrencyService.instance.format(total)} →',
                    key: ValueKey('${CurrencyService.instance.currencyCode}_$total'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueShoppingLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Text(
        'Continue Shopping',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade700,
          decoration: TextDecoration.underline,
          decorationColor: Colors.grey.shade400,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover the latest AURA collection.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accent),
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ShopScreen()),
                );
              },
              child: const Text(
                'SHOP COLLECTION →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
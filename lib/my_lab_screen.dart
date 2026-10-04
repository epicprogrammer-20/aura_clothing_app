import 'package:flutter/material.dart';
import 'product_model.dart';
import 'product_detail_screen.dart';
import 'cart_service.dart';
import 'currency_service.dart';
import 'auth_service.dart';
import 'fit_profile_service.dart';

/// "My Lab": build an outfit by swapping pieces from the catalogue.
///
/// Each layer (headwear / top / bottom) is a slot filled from your products:
///   • headwear: Accessories whose title contains cap, beanie or hat
///   • top:      products in the 'Tops' or 'Outerwear' categories
///   • bottom:   products in the 'Bottoms' category
/// Add products in those categories and they appear here automatically.
///
/// For the outfit to stack cleanly, product images should be PNGs with a
/// transparent background.
class MyLabScreen extends StatefulWidget {
  const MyLabScreen({super.key});

  @override
  State<MyLabScreen> createState() => _MyLabScreenState();
}

class _LabSlot {
  final String label;
  final String emptyText;
  final List<ProductModel> options;
  int? index; // null = nothing worn in this slot

  _LabSlot({
    required this.label,
    required this.emptyText,
    required this.options,
  }) : index = options.isEmpty ? null : 0;

  ProductModel? get current => index == null ? null : options[index!];
  bool get hasOptions => options.isNotEmpty;

  void next() {
    if (!hasOptions) return;
    index = ((index ?? -1) + 1) % options.length;
  }

  void previous() {
    if (!hasOptions) return;
    index = ((index ?? 0) - 1 + options.length) % options.length;
  }
}

class _MyLabScreenState extends State<MyLabScreen> {
  late final _LabSlot _head;
  late final _LabSlot _top;
  late final _LabSlot _bottom;

  List<_LabSlot> get _slots => [_head, _top, _bottom];

  static bool _isHeadwear(ProductModel p) {
    final t = p.title.toLowerCase();
    return p.category == 'Accessories' &&
        (t.contains('cap') || t.contains('beanie') || t.contains('hat'));
  }

  @override
  void initState() {
    super.initState();
    // Photos of people wearing the item can't be layered, so skip them.
    final all = mockProducts.where((p) => !p.personVisible).toList();

    _head = _LabSlot(
      label: 'Headwear',
      emptyText: 'Beanies coming soon',
      options: all.where(_isHeadwear).toList(),
    );
    _top = _LabSlot(
      label: 'Top',
      emptyText: 'Tops coming soon',
      options: all
          .where((p) => p.category == 'Tops' || p.category == 'Outerwear')
          .toList(),
    );
    _bottom = _LabSlot(
      label: 'Bottoms',
      emptyText: 'Bottoms coming soon',
      options: all.where((p) => p.category == 'Bottoms').toList(),
    );
  }

  List<ProductModel> get _outfit =>
      _slots.map((s) => s.current).whereType<ProductModel>().toList();

  double get _total => _outfit.fold(0.0, (sum, p) => sum + p.priceValue);

  void _addOutfitToCart() {
    if (!requireLogin(context, message: 'Log in to add items to your cart')) {
      return;
    }
    final outfit = _outfit;
    if (outfit.isEmpty) return;

    for (final p in outfit) {
      // Use the user's recommended size (from My Size) when they have one.
      final rec = FitProfileService.instance
          .recommend(available: const ['XS', 'S', 'M', 'L', 'XL']);
      final size = _isHeadwear(p) ? 'M' : (rec?.size ?? 'M');
      CartService.instance.addItem(p, size, p.colors.first);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${outfit.length} item${outfit.length == 1 ? '' : 's'} added to your cart'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'My Lab',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mix and match pieces to build your look. Use the arrows to swap each layer.',
                    style: TextStyle(
                        fontSize: 13, height: 1.5, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  _buildCanvas(),
                  const SizedBox(height: 20),
                  for (final slot in _slots) _slotRow(slot),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Mannequin + layered outfit ──

  Widget _buildCanvas() {
    return AspectRatio(
      aspectRatio: 0.72,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _MannequinPainter()),
                ),
                // Bottoms first so tops draw over them, then headwear.
                _layer(_bottom,
                    left: w * 0.18, top: h * 0.50, width: w * 0.64, height: h * 0.47),
                _layer(_top,
                    left: w * 0.08, top: h * 0.14, width: w * 0.84, height: h * 0.42),
                _layer(_head,
                    left: w * 0.30, top: h * 0.015, width: w * 0.40, height: h * 0.15),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _layer(
    _LabSlot slot, {
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    final product = slot.current;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: product == null
          ? const SizedBox.shrink()
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Image.asset(
                product.imageUrl,
                key: ValueKey(product.id),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_outlined,
                  color: Colors.grey[400],
                ),
              ),
            ),
    );
  }

  // ── Controls under the canvas ──

  Widget _slotRow(_LabSlot slot) {
    final product = slot.current;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _arrow(Icons.chevron_left, slot.hasOptions, () {
            setState(slot.previous);
          }),
          Expanded(
            child: GestureDetector(
              onTap: product == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: product),
                        ),
                      ),
              child: Column(
                children: [
                  Text(
                    slot.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (!slot.hasOptions)
                    Text(
                      slot.emptyText,
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    )
                  else if (product == null)
                    Text(
                      'Nothing selected',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    )
                  else ...[
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    AnimatedBuilder(
                      animation: CurrencyService.instance,
                      builder: (context, _) => Text(
                        CurrencyService.instance
                            .formatFromPriceString(product.price),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (slot.hasOptions && product != null)
            GestureDetector(
              onTap: () => setState(() => slot.index = null),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.close, size: 16, color: Colors.grey[400]),
              ),
            ),
          _arrow(Icons.chevron_right, slot.hasOptions, () {
            setState(slot.next);
          }),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, bool enabled, VoidCallback onTap) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 26),
      color: Colors.black,
      disabledColor: Colors.grey.shade300,
    );
  }

  // ── Total + add to cart ──

  Widget _buildBottomBar() {
    final count = _outfit.length;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Outfit total',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                AnimatedBuilder(
                  animation: CurrencyService.instance,
                  builder: (context, _) => Text(
                    CurrencyService.instance.format(_total),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: count == 0 ? null : _addOutfitToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    count == 0 ? 'Pick a piece' : 'Add outfit to cart ($count)',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plain light-grey mannequin drawn in code (no image needed). Proportions
/// line up with the layer boxes in [_MyLabScreenState._buildCanvas].
class _MannequinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()
      ..color = const Color(0xFFE2E2E2)
      ..style = PaintingStyle.fill;
    final limb = Paint()
      ..color = const Color(0xFFE2E2E2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Head and neck
    canvas.drawCircle(Offset(w * 0.5, h * 0.085), w * 0.075, body);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.155), width: w * 0.07, height: h * 0.05),
        const Radius.circular(6),
      ),
      body,
    );

    // Torso
    final torso = Path()
      ..moveTo(w * 0.30, h * 0.18)
      ..lineTo(w * 0.70, h * 0.18)
      ..lineTo(w * 0.64, h * 0.50)
      ..lineTo(w * 0.36, h * 0.50)
      ..close();
    canvas.drawPath(torso, body);

    // Arms
    limb.strokeWidth = w * 0.075;
    canvas.drawLine(Offset(w * 0.29, h * 0.20), Offset(w * 0.20, h * 0.46), limb);
    canvas.drawLine(Offset(w * 0.71, h * 0.20), Offset(w * 0.80, h * 0.46), limb);

    // Legs
    limb.strokeWidth = w * 0.12;
    canvas.drawLine(Offset(w * 0.42, h * 0.52), Offset(w * 0.40, h * 0.94), limb);
    canvas.drawLine(Offset(w * 0.58, h * 0.52), Offset(w * 0.60, h * 0.94), limb);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'cart_service.dart';
import 'currency_service.dart';
import 'app_colors.dart';

enum _CheckoutStage { form, loading, success }
enum _PaymentMethod { card, paypal, googlePay }

const double _kDeliveryFee = 8.0;

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  _CheckoutStage _stage = _CheckoutStage.form;
  _PaymentMethod _paymentMethod = _PaymentMethod.card;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  final _promoController = TextEditingController();
  double _discountPercent = 0;
  String? _promoMessage;
  bool _promoError = false;

  late final AnimationController _checkController;
  late final Animation<double> _checkAnimation;

  late final String _orderNumber;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    _orderNumber =
    'AURA-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _promoController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  double get _subtotal => CartService.instance.subtotal;
  double get _discountAmount => _subtotal * (_discountPercent / 100);
  double get _total => (_subtotal - _discountAmount + _kDeliveryFee)
      .clamp(0, double.infinity);

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    setState(() {
      if (code == 'AURA10') {
        _discountPercent = 10;
        _promoMessage = '10% discount applied';
        _promoError = false;
      } else if (code.isEmpty) {
        _promoMessage = 'Enter a code first';
        _promoError = true;
      } else {
        _discountPercent = 0;
        _promoMessage = 'Invalid promo code';
        _promoError = true;
      }
    });
  }

  bool get _canPlaceOrder {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      return false;
    }
    if (_paymentMethod == _PaymentMethod.card) {
      return _cardNameController.text.trim().isNotEmpty &&
          _cardNumberController.text.trim().length >= 12 &&
          _expiryController.text.trim().isNotEmpty &&
          _cvvController.text.trim().length >= 3;
    }
    // PayPal / Google Pay are treated as already-linked saved methods in
    // this mock flow, so no extra fields are required.
    return true;
  }

  Future<void> _placeOrder() async {
    if (!_canPlaceOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Please fill in all required fields',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => _stage = _CheckoutStage.loading);

    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;
    setState(() => _stage = _CheckoutStage.success);
    _checkController.forward();
    CartService.instance.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_stage) {
            _CheckoutStage.form => _buildForm(),
            _CheckoutStage.loading => _buildLoading(),
            _CheckoutStage.success => _buildSuccess(),
          },
        ),
      ),
    );
  }

  Widget _buildForm() {
    final items = CartService.instance.items;

    return Column(
      key: const ValueKey('form'),
      children: [
        _buildTopBar(),
        _buildProgressIndicator(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final maxWidth = isWide ? 560.0 : double.infinity;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderSummaryCard(items),
                        const SizedBox(height: 20),
                        _buildDeliverySection(),
                        const SizedBox(height: 20),
                        _buildPaymentMethodSection(),
                        if (_paymentMethod == _PaymentMethod.card) ...[
                          const SizedBox(height: 16),
                          _buildCardForm(),
                        ],
                        const SizedBox(height: 20),
                        _buildPromoSection(),
                        const SizedBox(height: 20),
                        _buildPriceBreakdown(),
                        const SizedBox(height: 24),
                        _buildPlaceOrderButton(),
                        const SizedBox(height: 16),
                        _buildSecurityNote(),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Text(
            'Checkout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    const steps = ['Cart', 'Details', 'Payment'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final passed = i ~/ 2 < 2;
            return Expanded(
              child: Container(
                height: 1,
                color: passed ? AppColors.accent : Colors.grey.shade300,
              ),
            );
          }
          final index = i ~/ 2;
          final isActive = index == 2;
          final isPast = index < 2;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isActive || isPast) ? AppColors.accent : Colors.white,
                  border: Border.all(
                    color: (isActive || isPast)
                        ? AppColors.accent
                        : Colors.grey.shade300,
                  ),
                ),
                child: isPast
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: (isActive || isPast) ? Colors.black : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 6),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildOrderSummaryCard(List<CartItem> items) {
    return _SectionCard(
      title: 'Order Summary',
      child: Column(
        children: [
          for (final item in items) _orderSummaryRow(item),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _orderSummaryRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 52,
              height: 64,
              color: Colors.grey.shade100,
              child: Image.network(
                item.product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty ${item.quantity} · Size ${item.size}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: CurrencyService.instance,
            builder: (context, _) => Text(
              CurrencyService.instance.format(item.total),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    return _SectionCard(
      title: 'Delivery Information',
      child: Column(
        children: [
          _textField(controller: _nameController, label: 'Full name'),
          const SizedBox(height: 12),
          _textField(
            controller: _phoneController,
            label: 'Phone number',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _textField(
            controller: _addressController,
            label: 'Delivery address',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return _SectionCard(
      title: 'Payment Method',
      child: Column(
        children: [
          _paymentOptionTile(
            method: _PaymentMethod.card,
            label: 'Credit Card',
            subtitle: '•• 6006 •••• 24',
            leading: const FaIcon(FontAwesomeIcons.ccMastercard, size: 26, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          _paymentOptionTile(
            method: _PaymentMethod.paypal,
            label: 'Paypal',
            subtitle: '5221 •••• 2465',
            leading: const FaIcon(FontAwesomeIcons.paypal, size: 22, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          _paymentOptionTile(
            method: _PaymentMethod.googlePay,
            label: 'Google Pay',
            subtitle: '4142 •••• 7667',
            leading: const FaIcon(FontAwesomeIcons.googlePay, size: 26, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _paymentOptionTile({
    required _PaymentMethod method,
    required String label,
    required String subtitle,
    required Widget leading,
  }) {
    final selected = _paymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey.shade200,
            width: selected ? 1.4 : 1,
          ),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: leading,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.black : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: selected
                  ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return _SectionCard(
      title: 'Card Details',
      child: Column(
        children: [
          _textField(controller: _cardNameController, label: 'Cardholder name'),
          const SizedBox(height: 12),
          _textField(
            controller: _cardNumberController,
            label: 'Card number',
            keyboardType: TextInputType.number,
            hint: '1234 5678 9012 3456',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _textField(
                  controller: _expiryController,
                  label: 'Expiry (MM/YY)',
                  keyboardType: TextInputType.datetime,
                  hint: '08/28',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(
                  controller: _cvvController,
                  label: 'CVV',
                  keyboardType: TextInputType.number,
                  obscure: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoSection() {
    return _SectionCard(
      title: 'Promo Code',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Enter code',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    isDense: true,
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _applyPromo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          if (_promoMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _promoMessage!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _promoError ? Colors.red.shade400 : Colors.green.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return AnimatedBuilder(
      animation: CurrencyService.instance,
      builder: (context, _) {
        final currency = CurrencyService.instance;
        return _SectionCard(
          title: 'Price Details',
          child: Column(
            children: [
              _priceRow('Subtotal', currency.format(_subtotal)),
              const SizedBox(height: 8),
              _priceRow('Delivery fee', currency.format(_kDeliveryFee)),
              const SizedBox(height: 8),
              _priceRow(
                'Discount',
                _discountAmount > 0
                    ? '-${currency.format(_discountAmount)}'
                    : currency.format(0),
                valueColor: _discountAmount > 0 ? Colors.green.shade700 : null,
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 12),
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
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Text(
                      currency.format(_total),
                      key: ValueKey('${currency.currencyCode}_$_total'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: AnimatedBuilder(
          animation: CurrencyService.instance,
          builder: (context, _) => Text(
            'PLACE ORDER · ${CurrencyService.instance.format(_total)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(
          'Your payment information is secure',
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.accent),
          ),
          const SizedBox(height: 20),
          Text(
            'Processing your payment...',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      key: const ValueKey('success'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _checkAnimation,
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 44),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Order Confirmed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order #$_orderNumber',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you — your order has been placed and is on its way.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text(
                  'CONTINUE SHOPPING',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    int maxLines = 1,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscure,
      style: const TextStyle(fontSize: 13, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
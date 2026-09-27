import 'dart:async';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'cart_service.dart';
import 'currency_service.dart';
import 'app_colors.dart';
import 'home_screen.dart';
import 'region_service.dart';
import 'virtual_card.dart';
import 'points_service.dart';
import 'receipt_pdf_builder.dart';
import 'receipt_screen.dart';

enum _CheckoutStage { form, loading, success }
enum _PaymentMethod { card, paypal, googlePay, innbucks, ecocash }

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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cvvFocusNode = FocusNode();
  bool _showCardBack = false;

  final _paypalNameController = TextEditingController();
  final _paypalEmailController = TextEditingController();
  final _paypalAmountController = TextEditingController();
  final _paypalCurrencyController = TextEditingController();
  final _paypalDescriptionController = TextEditingController();

  final _gpayEmailController = TextEditingController();
  final _gpayPasswordController = TextEditingController();
  final _gpayCardNumberController = TextEditingController();
  final _gpayCvvController = TextEditingController();

  final _promoController = TextEditingController();
  double _discountPercent = 0;
  String? _promoMessage;
  bool _promoError = false;

  bool _redeemPoints = false;
  ReceiptData? _receiptData;

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
    _cvvFocusNode.addListener(() {
      setState(() => _showCardBack = _cvvFocusNode.hasFocus);
    });
    _orderNumber =
    'AURA-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cvvFocusNode.dispose();
    _paypalNameController.dispose();
    _paypalEmailController.dispose();
    _paypalAmountController.dispose();
    _paypalCurrencyController.dispose();
    _paypalDescriptionController.dispose();
    _gpayEmailController.dispose();
    _gpayPasswordController.dispose();
    _gpayCardNumberController.dispose();
    _gpayCvvController.dispose();
    _promoController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  double get _subtotal => CartService.instance.subtotal;
  double get _discountAmount => _subtotal * (_discountPercent / 100);

  // How many points would actually be spent right now, capped by both the
  // user's balance and what's left to pay after the promo discount.
  int get _pointsToRedeem => _redeemPoints
      ? min(
    PointsService.instance.balance,
    PointsService.instance.pointsForCash(_subtotal - _discountAmount),
  )
      : 0;
  double get _pointsDiscount =>
      PointsService.instance.cashForPoints(_pointsToRedeem);

  double get _total =>
      (_subtotal - _discountAmount - _pointsDiscount + _kDeliveryFee)
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

  bool get _isMethodAvailable {
    switch (_paymentMethod) {
      case _PaymentMethod.innbucks:
      case _PaymentMethod.ecocash:
        return RegionService.instance.isZimbabwe;
      default:
        return true;
    }
  }

  String get _paymentMethodLabel {
    switch (_paymentMethod) {
      case _PaymentMethod.card:
        return 'Credit / Debit Card';
      case _PaymentMethod.paypal:
        return 'PayPal';
      case _PaymentMethod.googlePay:
        return 'Google Pay';
      case _PaymentMethod.innbucks:
        return 'InnBucks';
      case _PaymentMethod.ecocash:
        return 'EcoCash';
    }
  }

  bool get _canPlaceOrder {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      return false;
    }
    if (!_isMethodAvailable) return false;

    switch (_paymentMethod) {
      case _PaymentMethod.card:
        return _cardNameController.text.trim().isNotEmpty &&
            _cardNumberController.text.trim().length >= 12 &&
            _expiryController.text.trim().isNotEmpty &&
            _cvvController.text.trim().length >= 3;
      case _PaymentMethod.paypal:
        return _paypalNameController.text.trim().isNotEmpty &&
            _paypalEmailController.text.trim().isNotEmpty &&
            _paypalAmountController.text.trim().isNotEmpty &&
            _paypalCurrencyController.text.trim().isNotEmpty &&
            _paypalDescriptionController.text.trim().isNotEmpty;
      case _PaymentMethod.googlePay:
        return _gpayEmailController.text.trim().isNotEmpty &&
            _gpayPasswordController.text.trim().isNotEmpty &&
            _gpayCardNumberController.text.trim().length >= 12 &&
            _gpayCvvController.text.trim().length >= 3;
      case _PaymentMethod.innbucks:
      case _PaymentMethod.ecocash:
      // Treated as already-linked saved methods in this mock flow, so
      // no extra fields are required.
        return true;
    }
  }

  Future<void> _placeOrder() async {
    if (!_canPlaceOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          content: Text(
            !_isMethodAvailable
                ? 'That payment method is unavailable in your region'
                : 'Please fill in all required fields',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    // Snapshot everything the receipt needs — the cart (and _subtotal with
    // it) gets cleared once the order succeeds.
    final capturedItems = List<CartItem>.from(CartService.instance.items);
    final subtotalAtOrder = _subtotal;
    final pointsToRedeem = _pointsToRedeem;
    final pointsDiscountAtOrder = _pointsDiscount;
    final totalAtOrder = _total;
    final promoCodeAtOrder =
    _discountPercent > 0 ? _promoController.text.trim().toUpperCase() : null;
    final promoDiscountAtOrder = _discountAmount;

    setState(() => _stage = _CheckoutStage.loading);

    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    if (pointsToRedeem > 0) PointsService.instance.redeem(pointsToRedeem);
    final earnedPoints = PointsService.instance.earnedFor(totalAtOrder);
    PointsService.instance.addPoints(earnedPoints);

    _receiptData = ReceiptData(
      orderId: _orderNumber,
      paidAt: DateTime.now(),
      items: capturedItems,
      subtotal: subtotalAtOrder,
      shipping: _kDeliveryFee,
      promoCode: promoCodeAtOrder,
      promoDiscount: promoDiscountAtOrder,
      pointsDiscount: pointsDiscountAtOrder,
      total: totalAtOrder,
      pointsEarned: earnedPoints,
      paymentMethodLabel: _paymentMethodLabel,
      customerName: _nameController.text.trim(),
      customerEmail: _emailController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      shippingAddress: _addressController.text.trim(),
    );

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
                        _buildCheckoutDetailsCard(),
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

  /// Order summary is now shown as plain content — no bordered/rounded
  /// outer box — just the heading and the item rows.
  Widget _buildOrderSummaryCard(List<CartItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Order Summary'),
        const SizedBox(height: 12),
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
              child: Image.asset(
                item.product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
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

  /// Everything else — delivery details, payment method (with whichever
  /// method-specific fields apply), promo code, and price details — lives
  /// in this single unified, square-cornered card.
  Widget _buildCheckoutDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
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
          _sectionHeading('Delivery Information'),
          const SizedBox(height: 12),
          _textField(controller: _nameController, label: 'Full name'),
          const SizedBox(height: 12),
          _textField(
            controller: _emailController,
            label: 'Email address',
            keyboardType: TextInputType.emailAddress,
          ),
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
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 20),
          _sectionHeading('Payment Method'),
          const SizedBox(height: 12),
          _buildPaymentMethodSection(),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 20),
          if (_paymentMethod == _PaymentMethod.card) ...[
            _sectionHeading('Card Details'),
            const SizedBox(height: 12),
            _buildCardForm(),
          ] else if (_paymentMethod == _PaymentMethod.paypal) ...[
            _sectionHeading('PayPal Details'),
            const SizedBox(height: 12),
            _buildPaypalForm(),
          ] else if (_paymentMethod == _PaymentMethod.googlePay) ...[
            _sectionHeading('Google Pay Details'),
            const SizedBox(height: 12),
            _buildGooglePayForm(),
          ],
          if (_paymentMethod == _PaymentMethod.card ||
              _paymentMethod == _PaymentMethod.paypal ||
              _paymentMethod == _PaymentMethod.googlePay) ...[
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 20),
          ],
          _sectionHeading('Promo Code'),
          const SizedBox(height: 12),
          _buildPromoSection(),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 20),
          _sectionHeading('Aura Points'),
          const SizedBox(height: 12),
          _buildPointsSection(),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 20),
          _sectionHeading('Price Details'),
          const SizedBox(height: 12),
          _buildPriceDetails(),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: Colors.black,
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    final isZimbabwe = RegionService.instance.isZimbabwe;
    return Column(
      children: [
        _paymentOptionTile(
          method: _PaymentMethod.card,
          label: 'Credit / Debit Card',
          icon: _methodIcon(_PaymentMethod.card),
        ),
        const SizedBox(height: 10),
        _paymentOptionTile(
          method: _PaymentMethod.paypal,
          label: 'PayPal',
          icon: _methodIcon(_PaymentMethod.paypal),
        ),
        const SizedBox(height: 10),
        _paymentOptionTile(
          method: _PaymentMethod.googlePay,
          label: 'Google Pay',
          icon: _methodIcon(_PaymentMethod.googlePay),
        ),
        const SizedBox(height: 10),
        _paymentOptionTile(
          method: _PaymentMethod.innbucks,
          label: 'InnBucks',
          icon: _methodIcon(_PaymentMethod.innbucks),
          available: isZimbabwe,
        ),
        const SizedBox(height: 10),
        _paymentOptionTile(
          method: _PaymentMethod.ecocash,
          label: 'EcoCash',
          icon: _methodIcon(_PaymentMethod.ecocash),
          available: isZimbabwe,
        ),
      ],
    );
  }

  /// Loads each payment method's own image from the assets folder —
  /// vector assets via flutter_svg, raster assets via Image.asset.
  Widget _methodIcon(_PaymentMethod method) {
    switch (method) {
      case _PaymentMethod.card:
        return SvgPicture.asset(
          'assets/images/MasterCard.svg',
          width: 26,
          height: 26,
          fit: BoxFit.contain,
        );
      case _PaymentMethod.paypal:
        return SvgPicture.asset(
          'assets/images/paypal.svg',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        );
      case _PaymentMethod.googlePay:
        return SvgPicture.asset(
          'assets/images/Gpay.svg',
          width: 26,
          height: 26,
          fit: BoxFit.contain,
        );
      case _PaymentMethod.innbucks:
        return Image.asset(
          'assets/images/InnBucks.png',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        );
      case _PaymentMethod.ecocash:
        return Image.asset(
          'assets/images/eco.png',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        );
    }
  }

  Widget _paymentOptionTile({
    required _PaymentMethod method,
    required String label,
    required Widget icon,
    bool available = true,
  }) {
    final selected = available && _paymentMethod == method;
    return Opacity(
      opacity: available ? 1 : 0.45,
      child: GestureDetector(
        onTap: available
            ? () => setState(() => _paymentMethod = method)
            : () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Available in Zimbabwe only',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
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
                child: icon,
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
                    if (!available) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Unavailable in your region',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ),
              if (available)
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
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            _cardNumberController,
            _cardNameController,
            _expiryController,
          ]),
          builder: (context, _) => VirtualCard(
            cardNumber: _cardNumberController.text,
            cardHolder: _cardNameController.text,
            expiry: _expiryController.text,
            cvv: _cvvController.text,
            showBack: _showCardBack,
          ),
        ),
        const SizedBox(height: 16),
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
                focusNode: _cvvFocusNode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaypalForm() {
    return Column(
      children: [
        _textField(controller: _paypalNameController, label: 'Full name'),
        const SizedBox(height: 12),
        _textField(
          controller: _paypalEmailController,
          label: 'PayPal email address',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _textField(
                controller: _paypalAmountController,
                label: 'Amount',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _textField(
                controller: _paypalCurrencyController,
                label: 'Currency',
                hint: 'USD',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _textField(
          controller: _paypalDescriptionController,
          label: 'Payment description',
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildGooglePayForm() {
    return Column(
      children: [
        _textField(
          controller: _gpayEmailController,
          label: 'Google Pay email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _textField(
          controller: _gpayPasswordController,
          label: 'Google Pay password',
          obscure: true,
        ),
        const SizedBox(height: 12),
        _textField(
          controller: _gpayCardNumberController,
          label: 'Card number',
          keyboardType: TextInputType.number,
          hint: '1234 5678 9012 3456',
        ),
        const SizedBox(height: 12),
        _textField(
          controller: _gpayCvvController,
          label: 'CVV',
          keyboardType: TextInputType.number,
          obscure: true,
        ),
      ],
    );
  }

  Widget _buildPromoSection() {
    return Column(
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
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.accent),
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
    );
  }

  Widget _buildPointsSection() {
    return AnimatedBuilder(
      animation: PointsService.instance,
      builder: (context, _) {
        final pts = PointsService.instance;
        final maxRedeemable =
        min(pts.balance, pts.pointsForCash(_subtotal - _discountAmount));
        final maxCash = pts.cashForPoints(maxRedeemable);
        final canRedeem = maxRedeemable > 0;
        return AnimatedBuilder(
          animation: CurrencyService.instance,
          builder: (context, _) => Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.black, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pts.balance} Aura Points available',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      canRedeem
                          ? 'Use them for ${CurrencyService.instance.format(maxCash)} off this order'
                          : 'Earn points on this order to redeem next time',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _redeemPoints && canRedeem,
                activeThumbColor: Colors.black,
                onChanged: canRedeem ? (v) => setState(() => _redeemPoints = v) : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceDetails() {
    return AnimatedBuilder(
      animation: CurrencyService.instance,
      builder: (context, _) {
        final currency = CurrencyService.instance;
        return Column(
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
            if (_pointsDiscount > 0) ...[
              const SizedBox(height: 8),
              _priceRow(
                'Aura Points redeemed',
                '-${currency.format(_pointsDiscount)}',
                valueColor: AppColors.accent,
              ),
            ],
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
    return LayoutBuilder(
      key: const ValueKey('success'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
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
            if (_receiptData != null && _receiptData!.pointsEarned > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: AppColors.accent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '+${_receiptData!.pointsEarned} Aura Points earned',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (_receiptData != null) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptScreen(data: _receiptData!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined,
                      size: 18, color: AppColors.accent),
                  label: const Text(
                    'VIEW E-RECEIPT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.accent,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                ),
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
            ),
          ),
        );
      },
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    int maxLines = 1,
    bool obscure = false,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
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
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.accent, width: 1.4),
        ),
      ),
    );
  }
}
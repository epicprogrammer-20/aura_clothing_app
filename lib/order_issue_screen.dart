import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'aura_live_chat_screen.dart';
import 'currency_service.dart';
import 'order_history_screen.dart';

enum OrderIssueType {
  wrongSize('Wrong size delivered'),
  notDelivered('Item not delivered'),
  defective('Item defective / damaged'),
  returnOrder('Return this order'),
  cancelOrder('Cancel this order'),
  other('Something else');

  final String label;
  const OrderIssueType(this.label);
}

/// Reached either from the Order Tracking screen's "Cancel Order" button
/// (with `initialIssueType: OrderIssueType.cancelOrder`) or from the Order
/// Support screen after the user picks an order to report a problem with.
///
/// The order's details are attached automatically and shown read-only —
/// Order ID, product, size, quantity, price, purchase date, delivery
/// address, and payment status all come straight from the OrderModel, the
/// user never has to type them in.
class OrderIssueScreen extends StatefulWidget {
  final OrderModel order;
  final OrderIssueType? initialIssueType;

  const OrderIssueScreen({
    super.key,
    required this.order,
    this.initialIssueType,
  });

  @override
  State<OrderIssueScreen> createState() => _OrderIssueScreenState();
}

class _OrderIssueScreenState extends State<OrderIssueScreen> {
  static const Duration _returnWindow = Duration(hours: 72);

  late OrderIssueType? _selected = widget.initialIssueType;
  final TextEditingController _detailsController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  OrderModel get order => widget.order;

  // Cancel is only allowed while the order is still being packed — once it
  // has shipped there's no way to intercept it, so we point the user to a
  // return instead.
  bool get _canCancel =>
      order.status != OrderStatus.cancelled && order.trackingStage == 0;

  bool get _isDelivered => order.status == OrderStatus.delivered;

  Duration? get _timeSinceDelivery {
    final at = order.deliveredAt;
    if (at == null) return null;
    return DateTime.now().difference(at);
  }

  // Returns are only allowed within 72 hours of the order actually arriving.
  bool get _canReturn {
    if (!_isDelivered) return false;
    final since = _timeSinceDelivery;
    if (since == null) return false;
    return since <= _returnWindow;
  }

  DateTime? get _returnDeadline => order.deliveredAt?.add(_returnWindow);

  double get _orderTotal => order.subtotal + order.shippingCost + order.tax;

  void _selectType(OrderIssueType type) {
    setState(() => _selected = type);
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    if (_selected == OrderIssueType.cancelOrder && !_canCancel) return;
    if (_selected == OrderIssueType.returnOrder && !_canReturn) return;

    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _submitting = false);

    final isCancel = _selected == OrderIssueType.cancelOrder;
    final isReturn = _selected == OrderIssueType.returnOrder;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isCancel
              ? 'Cancellation requested'
              : isReturn
              ? 'Return requested'
              : 'Report submitted',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
        ),
        content: Text(
          isCancel
              ? 'We\'ve received your request to cancel order #${order.id}. You\'ll get a confirmation once it\'s processed.'
              : isReturn
              ? 'We\'ve received your return request for order #${order.id}. Follow the instructions we send you to send the item back.'
              : 'Thanks — our support team will look into order #${order.id} and get back to you within 24 hours.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Report an Issue',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOrderSummaryCard(),
          const SizedBox(height: 14),
          _buildIssueTypeCard(),
          if (_selected != null) ...[
            const SizedBox(height: 14),
            _buildDetailSection(),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AuraLiveChatScreen(order: order),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
              label: const Text(
                'Live Chat',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildOrderSummaryCard() {
    return _card(
      children: [
        Row(
          children: [
            const Icon(Icons.attach_file_rounded, size: 16, color: Colors.black54),
            const SizedBox(width: 6),
            Text(
              'AUTO-ATTACHED ORDER DETAILS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade500,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                order.itemImageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey.shade200,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.itemTitle,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Order #${order.id}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _detailRow('Size', order.size),
        _detailRow('Quantity', '${order.quantity}'),
        _detailRow(
          'Price',
          AnimatedBuilder(
            animation: CurrencyService.instance,
            builder: (context, _) => Text(
              CurrencyService.instance.format(_orderTotal),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black),
            ),
          ),
        ),
        _detailRow('Purchase Date', order.orderDate),
        _detailRow('Delivery Address', order.shippingAddress),
        _detailRow('Payment Status', order.paymentStatus),
      ],
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
          ),
          Expanded(
            child: value is Widget
                ? value
                : Text(
              '$value',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueTypeCard() {
    return _card(
      children: [
        const Text(
          "What's the issue?",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Text(
          'Select the option that best describes what happened.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        ...OrderIssueType.values.map((type) => _issueOption(type)),
      ],
    );
  }

  Widget _issueOption(OrderIssueType type) {
    final isSelected = _selected == type;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _selectType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.accent : Colors.grey.shade300,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: isSelected ? AppColors.accent : Colors.grey.shade400,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection() {
    final selected = _selected!;

    if (selected == OrderIssueType.cancelOrder && !_canCancel) {
      return _blockedCard(
        message:
        "This order has already shipped, so it can't be cancelled here. "
            "Once it arrives, you can request a return instead.",
        actionLabel: _isDelivered ? 'Request a Return' : null,
        onAction: _isDelivered ? () => _selectType(OrderIssueType.returnOrder) : null,
      );
    }

    if (selected == OrderIssueType.returnOrder && !_canReturn) {
      if (!_isDelivered) {
        return _blockedCard(
          message: 'Returns can be requested once your order has arrived.',
        );
      }
      final deadline = _returnDeadline;
      return _blockedCard(
        message: deadline == null
            ? 'This order is outside the 72-hour return window.'
            : 'The 72-hour return window for this order closed on '
            '${_formatDateTime(deadline)}.',
      );
    }

    return _card(
      children: [
        if (selected == OrderIssueType.returnOrder && _canReturn) ...[
          _eligibleBanner(
            'Eligible for return — request before ${_formatDateTime(_returnDeadline!)}.',
          ),
          const SizedBox(height: 14),
        ],
        Text(
          'Tell us more',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _detailsController,
          maxLines: 4,
          style: const TextStyle(fontSize: 13, color: Colors.black),
          decoration: InputDecoration(
            hintText: selected == OrderIssueType.cancelOrder
                ? 'Anything we should know before we cancel this order? (optional)'
                : 'Add any details that will help us resolve this faster (optional)',
            hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _submitting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Text(
              selected == OrderIssueType.cancelOrder
                  ? 'Confirm Cancellation'
                  : selected == OrderIssueType.returnOrder
                  ? 'Request Return'
                  : 'Submit Report',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _blockedCard({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return _card(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
              ),
            ),
          ],
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _eligibleBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Colors.black),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $hour12:$minute $period';
  }
}

import 'package:flutter/material.dart';
import 'currency_service.dart';
import 'order_history_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  static const List<String> _stepLabels = [
    'Packed',
    'Shipped',
    'Out for Delivery',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                children: [
                  _buildTruckIllustration(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildTrackingCard(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text(
              'Track Order',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTruckIllustration() {
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/Delivery_Van_Mockup_1.png',
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) => SizedBox(
          height: 220,
          child: Icon(Icons.local_shipping, size: 160, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildTrackingCard(BuildContext context) {
    final stage = order.trackingStage.clamp(0, _stepLabels.length - 1);
    final progress = (stage + 1) / _stepLabels.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ID', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 2),
                    Text(
                      '#${order.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.trackingLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _dashedDivider(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  order.itemImageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.colorName}  |  Qty = ${order.quantity}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: CurrencyService.instance,
                builder: (context, _) => Text(
                  CurrencyService.instance.format(order.subtotal),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Placed', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 2),
                    Text(
                      order.orderDate,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Estimated Arrival', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 2),
                    Text(
                      order.statusDate,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildStepsRow(stage),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.orderDate, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
              Text(
                order.trackingLabel,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(height: 8, color: Colors.grey.shade200),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(height: 8, color: Colors.black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _buildCancelButton(context),
        ],
      ),
    );
  }

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dashWidth + gap)).floor();
        return Row(
          children: List.generate(
            count,
                (_) => Padding(
              padding: const EdgeInsets.only(right: gap),
              child: Container(width: dashWidth, height: 1, color: Colors.grey.shade300),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepsRow(int stage) {
    return Row(
      children: List.generate(_stepLabels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final segmentIndex = i ~/ 2;
          final isDone = segmentIndex < stage;
          if (isDone) {
            return Expanded(child: Container(height: 2, color: Colors.black));
          }
          final isCurrentSegment = segmentIndex == stage;
          return Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _dashedDivider(),
                if (isCurrentSegment)
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.local_shipping, size: 14, color: Colors.black),
                  ),
              ],
            ),
          );
        }
        final index = i ~/ 2;
        final isActiveOrDone = index <= stage;
        return Column(
          children: [
            Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: isActiveOrDone ? Colors.black : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isActiveOrDone
                  ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              )
                  : null,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 64,
              child: Text(
                _stepLabels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActiveOrDone ? Colors.black : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _confirmCancel(context),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.black),
        label: const Text(
          'Cancel Order',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black),
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Cancel order?', style: TextStyle(color: Colors.black)),
        content: const Text(
          'Are you sure you want to cancel this order?',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order cancellation requested')),
              );
            },
            child: const Text(
              'Yes, cancel',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
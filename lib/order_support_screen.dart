import 'package:flutter/material.dart';

import 'currency_service.dart';
import 'order_history_screen.dart';
import 'order_issue_screen.dart';

/// Entry point for Order Support from the Profile screen (sits just below
/// Aura Points). The user doesn't arrive with a specific order in mind, so
/// this screen first has them pick which order they need help with, then
/// hands off to OrderIssueScreen for that order.
class OrderSupportScreen extends StatelessWidget {
  const OrderSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = mockOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Order Support',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: orders.isEmpty
          ? _buildEmptyState()
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'Which order needs attention?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            'Select an order to report a problem, request a return, or cancel it.',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 16),
          ...orders.map((order) => _OrderTile(order: order)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "You don't have any orders yet",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(
              'Once you place an order, you can manage issues, returns, and cancellations here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;

  const _OrderTile({required this.order});

  String get _statusLabel {
    switch (order.status) {
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderIssueScreen(order: order)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  order.itemImageUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 52,
                    height: 52,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Order #${order.id}  ·  ${order.orderDate}',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: CurrencyService.instance,
                builder: (context, _) => Text(
                  CurrencyService.instance.format(order.subtotal),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

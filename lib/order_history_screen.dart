import 'package:flutter/material.dart';
import 'order_detail_screen.dart';

enum OrderStatus { delivered, inTransit, cancelled }

class OrderModel {
  final String id;
  final String orderDate;
  final String total;
  final String itemTitle;
  final String itemImageUrl;
  final OrderStatus status;
  final String statusDate;

  // Extra detail needed for the order detail page — kept optional with
  // sensible mock defaults so existing order cards don't need rewriting.
  final String size;
  final int quantity;
  final double subtotal;
  final double shippingCost;
  final double tax;
  final String shippingName;
  final String shippingAddress;
  final String paymentMethod;

  OrderModel({
    required this.id,
    required this.orderDate,
    required this.total,
    required this.itemTitle,
    required this.itemImageUrl,
    required this.status,
    required this.statusDate,
    this.size = 'M',
    this.quantity = 1,
    this.subtotal = 0,
    this.shippingCost = 0,
    this.tax = 0,
    this.shippingName = 'Alex Rivera',
    this.shippingAddress = '123 Main Street, Johannesburg, 2000',
    this.paymentMethod = 'Visa •••• 4242',
  });
}

// MOCK DATA — replace with real order history from backend once wired up.
final List<OrderModel> mockOrders = [
  OrderModel(
    id: '303-3504141-6107504',
    orderDate: 'Aug 28, 2026',
    total: '\$189',
    itemTitle: 'Classic Burgundy Leather Jacket',
    itemImageUrl:
    'https://images.unsplash.com/photo-1551028719-00167b16eac5?q=80&w=200',
    status: OrderStatus.inTransit,
    statusDate: 'Arriving Sep 18',
    size: 'M',
    quantity: 1,
    subtotal: 189,
    shippingCost: 0,
    tax: 0,
  ),
  OrderModel(
    id: '303-7858687-4527538',
    orderDate: 'Aug 14, 2026',
    total: '\$78',
    itemTitle: 'Cream Knit Sweater',
    itemImageUrl:
    'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?q=80&w=200',
    status: OrderStatus.delivered,
    statusDate: 'Arrived Aug 17',
    size: 'S',
    quantity: 1,
    subtotal: 78,
    shippingCost: 0,
    tax: 0,
  ),
  OrderModel(
    id: '303-1120044-9981123',
    orderDate: 'Jul 30, 2026',
    total: '\$130',
    itemTitle: 'Relaxed Denim Jacket',
    itemImageUrl:
    'https://images.unsplash.com/photo-1544022613-e87ca75a784a?q=80&w=200',
    status: OrderStatus.cancelled,
    statusDate: 'Cancelled Jul 31',
    size: 'L',
    quantity: 1,
    subtotal: 130,
    shippingCost: 0,
    tax: 0,
  ),
];

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Your Orders',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: mockOrders.isEmpty
          ? Center(
        child: Text(
          'No orders yet',
          style: TextStyle(color: Colors.grey[500]),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockOrders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          return _OrderCard(order: mockOrders[index]);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORDER PLACED',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                      Text(
                        order.orderDate,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                      Text(
                        order.total,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ORDER #${order.id}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.statusDate,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order.itemImageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: Icon(Icons.image_outlined, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        order.itemTitle,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (order.status == OrderStatus.inTransit) ...[
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: navigate to the track-package screen
                              // once it's built
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Track Package',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailScreen(order: order),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                          child: const Text(
                            'View Order',
                            style: TextStyle(color: Colors.black87, fontSize: 12),
                          ),
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
    );
  }
}
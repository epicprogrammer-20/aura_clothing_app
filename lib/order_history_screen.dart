import 'package:flutter/material.dart';
import 'currency_service.dart';
import 'order_tracking_screen.dart';

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

  // Used by the "My Orders" list and the "Track Order" screen.
  final String colorName;
  final int trackingStage; // 0 = packed, 1 = shipped, 2 = out for delivery, 3 = delivered
  final String trackingLabel;
  bool isReviewed;

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
    this.colorName = 'Black',
    this.trackingStage = 1,
    this.trackingLabel = 'Packet In Delivery',
    this.isReviewed = false,
  });
}

// MOCK DATA — replace with real order history from backend once wired up.
final List<OrderModel> mockOrders = [
  OrderModel(
    id: 'AB1042',
    orderDate: 'Aug 28, 2026',
    total: '\$189',
    itemTitle: 'Black Aura Hoodie',
    itemImageUrl: 'assets/images/products/blavkhood.png',
    status: OrderStatus.inTransit,
    statusDate: 'Arriving Sep 18',
    size: 'M',
    quantity: 1,
    subtotal: 189,
    shippingCost: 0,
    tax: 0,
    colorName: 'Black',
    trackingStage: 2,
    trackingLabel: 'Packet In Delivery',
  ),
  OrderModel(
    id: 'CD2201',
    orderDate: 'Sep 2, 2026',
    total: '\$45',
    itemTitle: 'Aura Cap',
    itemImageUrl: 'assets/images/products/hat.png',
    status: OrderStatus.inTransit,
    statusDate: 'Arriving Sep 21',
    size: 'One Size',
    quantity: 2,
    subtotal: 45,
    shippingCost: 0,
    tax: 0,
    colorName: 'Black',
    trackingStage: 0,
    trackingLabel: 'Order Packed',
  ),
  OrderModel(
    id: 'EF7858',
    orderDate: 'Aug 14, 2026',
    total: '\$78',
    itemTitle: 'Green Aura Hoodie',
    itemImageUrl: 'assets/images/products/greenhood.png',
    status: OrderStatus.delivered,
    statusDate: 'Arrived Aug 17',
    size: 'S',
    quantity: 1,
    subtotal: 78,
    shippingCost: 0,
    tax: 0,
    colorName: 'Green',
    isReviewed: false,
  ),
  OrderModel(
    id: 'GH9043',
    orderDate: 'Jul 20, 2026',
    total: '\$280',
    itemTitle: 'Black Puffer Jacket',
    itemImageUrl: 'assets/images/products/pufferblack.png',
    status: OrderStatus.delivered,
    statusDate: 'Arrived Jul 24',
    size: 'L',
    quantity: 2,
    subtotal: 280,
    shippingCost: 0,
    tax: 0,
    colorName: 'Black',
    isReviewed: true,
  ),
  OrderModel(
    id: 'IJ1120',
    orderDate: 'Jul 30, 2026',
    total: '\$130',
    itemTitle: 'Blue Aura Hoodie',
    itemImageUrl: 'assets/images/products/bluehood.png',
    status: OrderStatus.cancelled,
    statusDate: 'Cancelled Jul 31',
    size: 'L',
    quantity: 1,
    subtotal: 130,
    shippingCost: 0,
    tax: 0,
    colorName: 'Blue',
  ),
];

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _tabIndex = 0; // 0 = Active, 1 = Completed
  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrderModel> get _activeOrders =>
      mockOrders.where((o) => o.status == OrderStatus.inTransit).toList();

  List<OrderModel> get _completedOrders => mockOrders
      .where((o) =>
  o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled)
      .toList();

  List<OrderModel> get _visibleOrders {
    final source = _tabIndex == 0 ? _activeOrders : _completedOrders;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source
        .where((o) =>
    o.itemTitle.toLowerCase().contains(q) ||
        o.id.toLowerCase().contains(q))
        .toList();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  void _trackOrder(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
    );
  }

  void _leaveReview(OrderModel order) {
    showReviewSheet(
      context,
      order,
      onSubmitted: () => setState(() => order.isReviewed = true),
    );
  }

  void _buyAgain(OrderModel order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        content: Text(
          '${order.itemTitle} added to your cart',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
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
          'My Orders',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_searchOpen ? Icons.close : Icons.search,
                color: Colors.black),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabsRow(),
          if (_searchOpen) _buildSearchField(),
          Expanded(child: _buildOrderList()),
        ],
      ),
    );
  }

  Widget _buildTabsRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _tabButton('Active', 0),
          const SizedBox(width: 28),
          _tabButton('Completed', 1),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? Colors.black : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.black : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(color: Colors.black, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search your orders',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black54),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    final allForTab = _tabIndex == 0 ? _activeOrders : _completedOrders;

    if (allForTab.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: _tabIndex == 0
            ? "You don't have an order yet"
            : "You don't have any completed orders",
        subtitle: _tabIndex == 0
            ? "You don't have any active orders at this time"
            : "Orders you've received will show up here",
      );
    }

    final orders = _visibleOrders;

    if (orders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'No order found',
        subtitle: "We couldn't find any order matching your search",
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(
          order: order,
          onTrack: () => _trackOrder(order),
          onLeaveReview: () => _leaveReview(order),
          onBuyAgain: () => _buyAgain(order),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTrack;
  final VoidCallback onLeaveReview;
  final VoidCallback onBuyAgain;

  const _OrderCard({
    required this.order,
    required this.onTrack,
    required this.onLeaveReview,
    required this.onBuyAgain,
  });

  String get _statusLabel {
    switch (order.status) {
      case OrderStatus.inTransit:
        return order.trackingLabel;
      case OrderStatus.delivered:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = order.status == OrderStatus.inTransit;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  order.itemImageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey[200],
                    child: Icon(Icons.image_outlined, color: Colors.grey[400]),
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
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.colorName}  |  Qty = ${order.quantity}',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: isActive
                  ? onTrack
                  : (order.isReviewed ? onBuyAgain : onLeaveReview),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                isActive
                    ? 'Track Order'
                    : (order.isReviewed ? 'Buy Again' : 'Leave Review'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom sheet used from the "Completed" tab's "Leave Review" button.
// `parentContext` (the My Orders screen's own context) is what we use for
// the confirmation snackbar, since the sheet's own context is gone the
// moment it's popped. Content is wrapped in a SingleChildScrollView so it
// never overflows on small screens or when the keyboard is open.
void showReviewSheet(
    BuildContext parentContext,
    OrderModel order, {
      required VoidCallback onSubmitted,
    }) {
  int rating = 0;
  final commentController = TextEditingController();

  showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leave a Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          order.itemImageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey[200],
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
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.colorName}  |  Qty = ${order.quantity}',
                              style:
                              TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      AnimatedBuilder(
                        animation: CurrencyService.instance,
                        builder: (context, _) => Text(
                          CurrencyService.instance.format(order.subtotal),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'How is your order?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please give your rating & also your review...',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final filled = i < rating;
                      return GestureDetector(
                        onTap: () => setSheetState(() => rating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            filled ? Icons.star : Icons.star_border,
                            size: 34,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Very good product & fast delivery!',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              onSubmitted();
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.black,
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    'Thanks for your review!',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
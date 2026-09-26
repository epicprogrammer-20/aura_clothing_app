import 'package:flutter/material.dart';

class TimelineEvent {
  final String title;
  final String description;
  final String timestamp;
  final bool completed;
  final bool current;

  const TimelineEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    this.completed = false,
    this.current = false,
  });
}

class OrderTimelineScreen extends StatelessWidget {
  final String trackingId;
  final List<TimelineEvent> events;

  const OrderTimelineScreen({
    super.key,
    required this.trackingId,
    this.events = const [
      TimelineEvent(
        title: 'Order Placed',
        description: 'Your order has been received',
        timestamp: '2024-01-13, 10:32 AM',
        completed: true,
      ),
      TimelineEvent(
        title: 'Order Confirmed',
        description: "We've confirmed your order",
        timestamp: '2024-01-13, 11:44 AM',
        completed: true,
      ),
      TimelineEvent(
        title: 'Order Processed',
        description: 'Your items are being prepared for shipment',
        timestamp: '2024-01-15, 09:15 AM',
        completed: true,
      ),
      TimelineEvent(
        title: 'Shipped',
        description: 'Your order is on the way',
        timestamp: '2024-01-17, 12:30 PM',
        completed: true,
        current: true,
      ),
      TimelineEvent(
        title: 'Delivered',
        description: 'Expected delivery',
        timestamp: '2024-01-20',
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  const Text(
                    'Order Timeline',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #$trackingId',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 20),
                  for (int i = 0; i < events.length; i++)
                    _buildTimelineTile(events[i], isLast: i == events.length - 1),
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

  Widget _buildTimelineTile(TimelineEvent event, {required bool isLast}) {
    final bool isActive = event.completed || event.current;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.black : Colors.white,
                  border: Border.all(
                    color: isActive ? Colors.black : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: isActive
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: isActive ? Colors.black : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                      if (event.current) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Current',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.timestamp,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
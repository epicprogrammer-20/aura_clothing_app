import 'package:flutter/material.dart';

enum NotificationType { order, social, promo }

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String timeAgo;
  final String? imageUrl; // product/post thumbnail, or null for text-only
  bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timeAgo,
    this.imageUrl,
    this.isRead = false,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.order:
        return Icons.local_shipping_outlined;
      case NotificationType.social:
        return Icons.favorite_border;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────
// MOCK DATA — replace with real notifications from your backend
// once orders, social interactions, and promos are wired up.
// Ordering matters here: newest first, matching how a real feed
// would be sorted by timestamp.
// ─────────────────────────────────────────────────────────
final List<NotificationModel> mockNotifications = [
  NotificationModel(
    id: 'n1',
    type: NotificationType.order,
    title: 'Order shipped',
    message: 'Your Classic Burgundy Leather Jacket is on its way.',
    timeAgo: '2h',
    imageUrl:
    'https://images.unsplash.com/photo-1551028719-00167b16eac5?q=80&w=200',
  ),
  NotificationModel(
    id: 'n2',
    type: NotificationType.social,
    title: 'Mia Santos liked your post',
    message: 'Your Fashion Week Teal Coat look got a like.',
    timeAgo: '5h',
  ),
  NotificationModel(
    id: 'n3',
    type: NotificationType.promo,
    title: 'Fall sale is live',
    message: 'Up to 50% off jackets and outerwear this weekend.',
    timeAgo: '1d',
  ),
  NotificationModel(
    id: 'n4',
    type: NotificationType.order,
    title: 'Order delivered',
    message: 'Your Cream Knit Sweater has been delivered.',
    timeAgo: '2d',
    imageUrl:
    'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?q=80&w=200',
    isRead: true,
  ),
  NotificationModel(
    id: 'n5',
    type: NotificationType.social,
    title: 'Theo Brandt commented on your post',
    message: '"This fit is clean 🔥"',
    timeAgo: '3d',
    isRead: true,
  ),
  NotificationModel(
    id: 'n6',
    type: NotificationType.promo,
    title: 'Price drop',
    message: 'An item on your wishlist just got cheaper.',
    timeAgo: '4d',
    isRead: true,
  ),
];
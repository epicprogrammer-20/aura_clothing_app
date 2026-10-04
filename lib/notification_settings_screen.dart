import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'notification_preferences_service.dart';

/// Settings → Notifications. This is preferences (on/off toggles per
/// category) — the notification *feed* itself (the inbox of past
/// notifications) is a separate screen, notifications_screen.dart, opened
/// from the bell icon on Home.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedBuilder(
        animation: NotificationPreferencesService.instance,
        builder: (context, _) {
          final prefs = NotificationPreferencesService.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _card([
                _toggleRow(
                  icon: Icons.notifications_active_outlined,
                  label: 'All Notifications',
                  subtitle: 'Turn every notification on or off at once',
                  value: prefs.allEnabled,
                  onChanged: prefs.setAll,
                  emphasize: true,
                ),
              ]),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'By Category',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                ),
              ),
              _card([
                _toggleRow(
                  icon: Icons.local_shipping_outlined,
                  label: 'Orders',
                  subtitle: 'Shipping, delivery, and order status updates',
                  value: prefs.ordersEnabled,
                  onChanged: prefs.setOrders,
                ),
                _divider(),
                _toggleRow(
                  icon: Icons.favorite_border,
                  label: 'Social',
                  subtitle: 'Likes, comments, and activity on your posts',
                  value: prefs.socialEnabled,
                  onChanged: prefs.setSocial,
                ),
                _divider(),
                _toggleRow(
                  icon: Icons.local_offer_outlined,
                  label: 'Discounts & Promotions',
                  subtitle: 'Sales, deals, and price drops',
                  value: prefs.promosEnabled,
                  onChanged: prefs.setPromos,
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade100, indent: 48);

  Widget _toggleRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.black87),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

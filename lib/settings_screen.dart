import 'package:flutter/material.dart';
import 'currency_service.dart';
import 'notifications_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';
import 'app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _openCurrencySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CurrencyPickerSheet(),
    );
  }

  void _comingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _sectionLabel('General'),
          _card([
            AnimatedBuilder(
              animation: CurrencyService.instance,
              builder: (context, _) => _settingsRow(
                icon: Icons.attach_money_rounded,
                label: 'Currency',
                trailingText: CurrencyService.instance.currencyCode,
                onTap: _openCurrencySheet,
              ),
            ),
            _divider(),
            _settingsRow(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
          ]),

          const SizedBox(height: 24),
          _sectionLabel('Security'),
          _card([
            _settingsRow(
              icon: Icons.receipt_long_outlined,
              label: 'Transactions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
              },
            ),
            _divider(),
            _settingsRow(
              icon: Icons.payment_outlined,
              label: 'Recent Payments',
              onTap: () => _comingSoon('Recent Payments'),
            ),
            _divider(),
            _settingsRow(
              icon: Icons.person_outline,
              label: 'Account',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade100, indent: 48);

  Widget _settingsRow({
    required IconData icon,
    required String label,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
              ),
            ),
            if (trailingText != null) ...[
              Text(trailingText, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// Currency selection — same automatic/manual logic as before, just
// presented as a bottom sheet instead of its own full screen now.
class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet();

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  bool _switching = false;

  Future<void> _selectCurrency(String code) async {
    setState(() => _switching = true);
    await CurrencyService.instance.setManualCurrency(code);
    if (mounted) setState(() => _switching = false);
  }

  Future<void> _useAutomatic() async {
    setState(() => _switching = true);
    await CurrencyService.instance.useAutomaticDetection();
    if (mounted) setState(() => _switching = false);
  }

  String _statusLabel(CurrencyDetectionStatus status) {
    switch (status) {
      case CurrencyDetectionStatus.detecting:
        return 'Detecting...';
      case CurrencyDetectionStatus.detected:
        return 'Detected from your device region';
      case CurrencyDetectionStatus.error:
        return 'Could not detect — defaulted to USD';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurrencyService.instance,
      builder: (context, _) {
        final service = CurrencyService.instance;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Currency',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
                ),
                const SizedBox(height: 16),
                _row(
                  label: 'Automatic (based on device region)',
                  subtitle: service.isManualOverride ? null : _statusLabel(service.status),
                  selected: !service.isManualOverride,
                  onTap: _useAutomatic,
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 8),
                ...kAvailableCurrencies.map((option) {
                  final isSelected = service.isManualOverride && service.currencyCode == option.code;
                  return _row(
                    label: '${option.label} (${option.code})',
                    subtitle: option.symbol,
                    selected: isSelected,
                    onTap: () => _selectCurrency(option.code),
                  );
                }),
                if (_switching)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _row({
    required String label,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 20, color: AppColors.accent)
            else
              Icon(Icons.circle_outlined, size: 20, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
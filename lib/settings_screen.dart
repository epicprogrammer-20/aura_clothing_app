import 'package:flutter/material.dart';
import 'currency_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedBuilder(
        animation: CurrencyService.instance,
        builder: (context, _) {
          final service = CurrencyService.instance;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'CURRENCY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Automatic detection option
              _currencyRow(
                label: 'Automatic (based on device region)',
                subtitle: service.isManualOverride
                    ? null
                    : _statusLabel(service.status),
                selected: !service.isManualOverride,
                onTap: _useAutomatic,
              ),

              Divider(color: Colors.grey[200], height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'MANUAL SELECTION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              ...kAvailableCurrencies.map((option) {
                final isSelected = service.isManualOverride &&
                    service.currencyCode == option.code;
                return _currencyRow(
                  label: '${option.label} (${option.code})',
                  subtitle: option.symbol,
                  selected: isSelected,
                  onTap: () => _selectCurrency(option.code),
                );
              }),

              if (_switching)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
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

  Widget _currencyRow({
    required String label,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, size: 20, color: Colors.black)
            else
              Icon(Icons.circle_outlined, size: 20, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
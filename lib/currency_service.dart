import 'package:flutter/widgets.dart';

class CurrencyOption {
  final String code;
  final String symbol;
  final String label;

  const CurrencyOption(this.code, this.symbol, this.label);
}

// Manually selectable currencies shown in Profile settings.
const List<CurrencyOption> kAvailableCurrencies = [
  CurrencyOption('USD', '\$', 'US Dollar'),
  CurrencyOption('ZAR', 'R', 'South African Rand'),
  CurrencyOption('GBP', '£', 'British Pound'),
  CurrencyOption('EUR', '€', 'Euro'),
  CurrencyOption('NGN', '₦', 'Nigerian Naira'),
  CurrencyOption('KES', 'KSh', 'Kenyan Shilling'),
  CurrencyOption('CAD', 'CA\$', 'Canadian Dollar'),
  CurrencyOption('AUD', 'AU\$', 'Australian Dollar'),
  CurrencyOption('INR', '₹', 'Indian Rupee'),
  CurrencyOption('JPY', '¥', 'Japanese Yen'),
  CurrencyOption('AED', 'AED ', 'UAE Dirham'),
];

// Mock exchange rates — 1 USD = this many units. All mock product prices
// are treated as USD. Replace with a live rates API once the backend is
// wired up; the rest of the app only ever calls format() /
// formatFromPriceString(), so that swap stays contained to this file.
const Map<String, double> _mockRates = {
  'USD': 1.0,
  'ZAR': 18.50,
  'GBP': 0.79,
  'EUR': 0.92,
  'NGN': 1550.0,
  'KES': 129.0,
  'CAD': 1.37,
  'AUD': 1.52,
  'INR': 83.30,
  'JPY': 149.50,
  'AED': 3.67,
};

// Maps a 2-letter country code (from the device's locale/region setting)
// to a currency code. This is a proxy for location, not real GPS —
// see note in useAutomaticDetection().
const Map<String, String> _countryToCurrency = {
  'US': 'USD',
  'ZA': 'ZAR',
  'GB': 'GBP',
  'DE': 'EUR', 'FR': 'EUR', 'ES': 'EUR', 'IT': 'EUR',
  'NG': 'NGN',
  'KE': 'KES',
  'CA': 'CAD',
  'AU': 'AUD',
  'IN': 'INR',
  'JP': 'JPY',
  'AE': 'AED',
};

enum CurrencyDetectionStatus { detecting, detected, error }

class CurrencyService extends ChangeNotifier {
  CurrencyService._internal();
  static final CurrencyService instance = CurrencyService._internal();

  String currencyCode = 'USD';
  bool _userOverride = false; // true once the person manually picks one
  CurrencyDetectionStatus status = CurrencyDetectionStatus.detecting;

  String get currencySymbol => _symbolFor(currencyCode);

  double get _rateFromUsd => _mockRates[currencyCode] ?? 1.0;

  String _symbolFor(String code) {
    final match = kAvailableCurrencies.where((c) => c.code == code);
    if (match.isNotEmpty) return match.first.symbol;
    return '$code ';
  }

  // Reads the device's region setting (e.g. "en_ZA" -> "ZA") as a proxy
  // for location, and maps it to a currency. No GPS, no permissions,
  // no network call — this is the lightweight stand-in until real
  // GPS-based detection is added back (needs geolocator + geocoding +
  // an Android compileSdk 34+ bump, deferred for now).
  // No-ops if the user has already manually picked a currency.
  Future<void> detectFromLocationOrLocale() async {
    if (_userOverride) return;
    status = CurrencyDetectionStatus.detecting;
    notifyListeners();

    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final countryCode = locale.countryCode ?? 'US';
      currencyCode = _countryToCurrency[countryCode] ?? 'USD';
      status = CurrencyDetectionStatus.detected;
    } catch (_) {
      currencyCode = 'USD';
      status = CurrencyDetectionStatus.error;
    }
    notifyListeners();
  }

  // Called from Profile settings when the person manually picks a currency.
  Future<void> setManualCurrency(String code) async {
    _userOverride = true;
    currencyCode = code;
    status = CurrencyDetectionStatus.detected;
    notifyListeners();
  }

  // Lets the person switch back to automatic (locale) detection.
  Future<void> useAutomaticDetection() async {
    _userOverride = false;
    await detectFromLocationOrLocale();
  }

  bool get isManualOverride => _userOverride;

  String format(double usdAmount) {
    final converted = usdAmount * _rateFromUsd;
    final decimals = currencyCode == 'JPY' ? 0 : 2;
    return '$currencySymbol${converted.toStringAsFixed(decimals)}';
  }

  String formatFromPriceString(String usdPriceString) {
    final cleaned = usdPriceString.replaceAll(RegExp(r'[^0-9.]'), '');
    final usdAmount = double.tryParse(cleaned) ?? 0.0;
    return format(usdAmount);
  }
}
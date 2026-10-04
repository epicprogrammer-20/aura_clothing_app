import 'package:flutter/foundation.dart';

/// Whether each notification category is enabled. Purely in-memory for
/// this prototype — wire this up to actually suppress push notifications
/// (and persist it, e.g. shared_preferences or a backend user-settings
/// endpoint) once that infrastructure exists.
class NotificationPreferencesService extends ChangeNotifier {
  NotificationPreferencesService._internal();
  static final NotificationPreferencesService instance =
  NotificationPreferencesService._internal();

  bool ordersEnabled = true;
  bool socialEnabled = true;
  bool promosEnabled = true;

  // "All notifications" reads as on only when every category is on, and
  // toggling it sets every category to match.
  bool get allEnabled => ordersEnabled && socialEnabled && promosEnabled;

  void setAll(bool value) {
    ordersEnabled = value;
    socialEnabled = value;
    promosEnabled = value;
    notifyListeners();
  }

  void setOrders(bool value) {
    ordersEnabled = value;
    notifyListeners();
  }

  void setSocial(bool value) {
    socialEnabled = value;
    notifyListeners();
  }

  void setPromos(bool value) {
    promosEnabled = value;
    notifyListeners();
  }
}

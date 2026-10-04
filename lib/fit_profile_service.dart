import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The size the app suggests for a product, plus how it got there.
class SizeRecommendation {
  /// e.g. 'M'
  final String size;

  /// Human-readable list of what was used, e.g. "chest, waist and hip".
  final String basis;

  /// true when at least two body measurements (chest/waist/hip) were given.
  final bool strong;

  /// true when the ideal size wasn't available on the product and the
  /// closest available size was suggested instead.
  final bool adjusted;

  const SizeRecommendation({
    required this.size,
    required this.basis,
    required this.strong,
    this.adjusted = false,
  });
}

/// Stores the user's body measurements (entered on the My Size screen) and
/// turns them into a recommended clothing size.
///
/// Measurements are always stored in metric (cm / kg) and saved on the
/// device with shared_preferences. When the backend exists, swap [load] and
/// [save] for API calls so the profile follows the user across devices.
class FitProfileService extends ChangeNotifier {
  FitProfileService._internal();
  static final FitProfileService instance = FitProfileService._internal();

  static const List<String> sizeOrder = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  // Lower bound of each size (XS..XXL) followed by the upper bound of XXL.
  // Chest / waist / hip / height come from the in-app Size Guide table.
  // XS and the weight scale are extrapolated, so tweak them if needed.
  static const List<double> _chest = [88, 92, 96, 100, 105, 110, 115];
  static const List<double> _waist = [72, 76, 80, 84, 89, 94, 99];
  static const List<double> _hip = [88, 92, 96, 100, 105, 110, 115];
  static const List<double> _height = [160, 170, 175, 180, 183, 187, 191];
  static const List<double> _weight = [48, 60, 68, 77, 87, 98, 110];

  // How much each measurement counts towards the final answer.
  static const double _wChest = 3.0;
  static const double _wWaist = 2.0;
  static const double _wHip = 2.0;
  static const double _wWeight = 1.5;
  static const double _wHeight = 0.75;

  static const String _kHeight = 'fit_height_cm';
  static const String _kWeight = 'fit_weight_kg';
  static const String _kChest = 'fit_chest_cm';
  static const String _kWaist = 'fit_waist_cm';
  static const String _kHip = 'fit_hip_cm';
  static const String _kFit = 'fit_pref_index';
  static const String _kImperial = 'fit_use_imperial';

  double? heightCm;
  double? weightKg;
  double? chestCm;
  double? waistCm;
  double? hipCm;

  /// 0 = Skinny (snug), 1 = Regular, 2 = Oversized (roomy)
  int fitIndex = 1;

  /// Display preference only (the numbers are stored in metric).
  bool useImperial = false;

  bool _loaded = false;

  bool get hasAnyMeasurement =>
      heightCm != null ||
      weightKg != null ||
      chestCm != null ||
      waistCm != null ||
      hipCm != null;

  /// Safe to call many times; only reads from disk once.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      heightCm = prefs.getDouble(_kHeight);
      weightKg = prefs.getDouble(_kWeight);
      chestCm = prefs.getDouble(_kChest);
      waistCm = prefs.getDouble(_kWaist);
      hipCm = prefs.getDouble(_kHip);
      fitIndex = prefs.getInt(_kFit) ?? 1;
      useImperial = prefs.getBool(_kImperial) ?? false;
      notifyListeners();
    } catch (_) {
      // Storage unavailable: just behave as "no profile saved yet".
    }
  }

  Future<void> save({
    double? heightCm,
    double? weightKg,
    double? chestCm,
    double? waistCm,
    double? hipCm,
    required int fitIndex,
    required bool useImperial,
  }) async {
    this.heightCm = heightCm;
    this.weightKg = weightKg;
    this.chestCm = chestCm;
    this.waistCm = waistCm;
    this.hipCm = hipCm;
    this.fitIndex = fitIndex;
    this.useImperial = useImperial;
    _loaded = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      Future<void> put(String key, double? v) async {
        if (v == null) {
          await prefs.remove(key);
        } else {
          await prefs.setDouble(key, v);
        }
      }

      await put(_kHeight, heightCm);
      await put(_kWeight, weightKg);
      await put(_kChest, chestCm);
      await put(_kWaist, waistCm);
      await put(_kHip, hipCm);
      await prefs.setInt(_kFit, fitIndex);
      await prefs.setBool(_kImperial, useImperial);
    } catch (_) {}
  }

  Future<void> clear() async {
    await save(
      fitIndex: 1,
      useImperial: useImperial,
    );
  }

  /// Recommendation from the saved profile. Pass [available] (the sizes the
  /// product comes in) so the suggestion is always something you can buy.
  SizeRecommendation? recommend({List<String>? available}) {
    return compute(
      heightCm: heightCm,
      weightKg: weightKg,
      chestCm: chestCm,
      waistCm: waistCm,
      hipCm: hipCm,
      fitIndex: fitIndex,
      available: available,
    );
  }

  // Where a measurement sits on the XS..XXL scale: 0.0 is the very bottom of
  // XS, 1.0 the bottom of S, and so on up to just under 6.0.
  static double _position(double x, List<double> bounds) {
    if (x <= bounds.first) return 0.0;
    for (var i = 0; i < bounds.length - 1; i++) {
      if (x < bounds[i + 1]) {
        return i + (x - bounds[i]) / (bounds[i + 1] - bounds[i]);
      }
    }
    return 5.99;
  }

  /// Pure function so the My Size screen can preview a result as the user
  /// types, before anything is saved.
  static SizeRecommendation? compute({
    double? heightCm,
    double? weightKg,
    double? chestCm,
    double? waistCm,
    double? hipCm,
    int fitIndex = 1,
    List<String>? available,
  }) {
    final bodyCount = [chestCm, waistCm, hipCm].where((v) => v != null).length;
    final hasHeightAndWeight = heightCm != null && weightKg != null;
    if (bodyCount == 0 && !hasHeightAndWeight) return null;

    var total = 0.0;
    var weights = 0.0;
    final used = <String>[];

    void add(double? v, List<double> bounds, double w, String name) {
      if (v == null) return;
      total += _position(v, bounds) * w;
      weights += w;
      used.add(name);
    }

    add(chestCm, _chest, _wChest, 'chest');
    add(waistCm, _waist, _wWaist, 'waist');
    add(hipCm, _hip, _wHip, 'hip');
    add(weightKg, _weight, _wWeight, 'weight');
    add(heightCm, _height, _wHeight, 'height');

    // Skinny = wants it snug, Oversized = wants it roomy.
    const offsets = [-0.5, 0.0, 1.0];
    final average = total / weights;
    var index = (average + offsets[fitIndex.clamp(0, 2)])
        .floor()
        .clamp(0, sizeOrder.length - 1);

    var adjusted = false;
    if (available != null && available.isNotEmpty) {
      final options = available.where(sizeOrder.contains).toList();
      if (options.isNotEmpty && !options.contains(sizeOrder[index])) {
        options.sort((a, b) => (sizeOrder.indexOf(a) - index)
            .abs()
            .compareTo((sizeOrder.indexOf(b) - index).abs()));
        index = sizeOrder.indexOf(options.first);
        adjusted = true;
      }
    }

    return SizeRecommendation(
      size: sizeOrder[index],
      basis: _joinNames(used),
      strong: bodyCount >= 2,
      adjusted: adjusted,
    );
  }

  static String _joinNames(List<String> names) {
    if (names.length == 1) return names.first;
    return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
  }
}

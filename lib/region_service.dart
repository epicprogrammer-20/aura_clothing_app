/// Placeholder region detection.
///
/// This will be replaced later by real region/location detection (device
/// locale, IP lookup, GPS, etc). Until then it defaults to `false`, so
/// region-locked payment methods (InnBucks, EcoCash) correctly show as
/// unavailable everywhere.
///
/// When the real implementation lands, swap the body of [isZimbabwe] for
/// the actual detection logic — everything that reads
/// `RegionService.instance.isZimbabwe` will pick it up automatically.
class RegionService {
  RegionService._();

  static final RegionService instance = RegionService._();

  /// Whether the user's current region is Zimbabwe.
  bool get isZimbabwe => false;
}
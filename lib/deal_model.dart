import 'product_model.dart';

class DealModel {
  final ProductModel product;
  final double discountPercent;
  final DateTime endsAt;
  final String badge;
  final String variantDescription;

  DealModel({
    required this.product,
    required this.discountPercent,
    required this.endsAt,
    this.badge = 'LIMITED DEAL',
    this.variantDescription = '',
  });

  double get discountedPrice => product.priceValue * (1 - discountPercent / 100);
}

// Mock deals — replace with real data once a backend/admin panel exists.
final List<DealModel> mockDeals = [
  DealModel(
    product: mockProducts[0],
    discountPercent: 30,
    endsAt: DateTime.now().add(const Duration(hours: 2, minutes: 14, seconds: 36)),
    variantDescription: 'Black · Leather',
  ),
  DealModel(
    product: mockProducts[3],
    discountPercent: 20,
    endsAt: DateTime.now().add(const Duration(hours: 5, minutes: 40)),
    variantDescription: 'Cream · Knit',
  ),
  DealModel(
    product: mockProducts[5],
    discountPercent: 15,
    endsAt: DateTime.now().add(const Duration(hours: 1, minutes: 5)),
    variantDescription: 'Black · Trench',
  ),
];

// Looks up whether a product currently has an active deal. Once an admin
// panel exists, this is where it'd query real promotion data instead of
// the mock list.
DealModel? dealForProduct(String productId) {
  for (final deal in mockDeals) {
    if (deal.product.id == productId) return deal;
  }
  return null;
}
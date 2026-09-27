import 'package:flutter/material.dart';
import 'product_model.dart';

class CartItem {
  final ProductModel product;
  final String size;
  final Color color;
  int quantity;

  // The discounted price this item was added at, if it came from a deal.
  // Null means "no deal" — use the product's normal price.
  double? dealPrice;

  CartItem({
    required this.product,
    required this.size,
    required this.color,
    this.quantity = 1,
    this.dealPrice,
  });

  double get unitPrice => dealPrice ?? product.priceValue;
  double get total => unitPrice * quantity;
}

class CartService extends ChangeNotifier {
  CartService._internal();
  static final CartService instance = CartService._internal();

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.total);

  void addItem(
      ProductModel product,
      String size,
      Color color, {
        int quantity = 1,
        double? dealPrice,
      }) {
    final index = _items.indexWhere(
          (i) =>
      i.product.id == product.id &&
          i.size == size &&
          i.color.toARGB32() == color.toARGB32() &&
          i.dealPrice == dealPrice,
    );
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(
        product: product,
        size: size,
        color: color,
        quantity: quantity,
        dealPrice: dealPrice,
      ));
    }
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void updateQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      removeItem(item);
    } else {
      item.quantity = quantity;
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
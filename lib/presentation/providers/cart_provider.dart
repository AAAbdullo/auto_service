import 'package:flutter/foundation.dart';
import '../../data/models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {}; // корзина
  final Map<String, CartItem> _bookedItems = {}; // забронированные детали

  Map<String, CartItem> get items => {..._items};
  Map<String, CartItem> get bookedItems => {..._bookedItems};

  int get itemCount => _items.length;
  int get bookedCount => _bookedItems.length;

  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  // --- Корзина ---
  void addItem(ProductModel product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items[product.id] = CartItem(product: product, quantity: 1);
    }
    notifyListeners();
  }

  void addItemWithQuantity(ProductModel product, int quantity) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity + quantity,
        ),
      );
    } else {
      _items[product.id] = CartItem(product: product, quantity: quantity);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity = quantity;
      notifyListeners();
    }
  }

  int getQuantity(String productId) => _items[productId]?.quantity ?? 0;
  bool isInCart(String productId) => _items.containsKey(productId);

  void clear() {
    _items.clear();
    notifyListeners();
  }

  // --- Забронированные детали ---
  void bookItem(ProductModel product, int quantity) {
    if (_bookedItems.containsKey(product.id)) {
      _bookedItems.update(
        product.id,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity + quantity,
        ),
      );
    } else {
      _bookedItems[product.id] = CartItem(product: product, quantity: quantity);
    }
    notifyListeners();
  }

  bool isBooked(String productId) => _bookedItems.containsKey(productId);

  void removeBookedItem(String productId) {
    _bookedItems.remove(productId);
    notifyListeners();
  }
}

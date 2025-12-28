import 'package:flutter/foundation.dart';
import '../../data/models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {}; // корзина (изменено на int)
  final Map<int, CartItem> _bookedItems = {}; // забронированные детали (изменено на int)

  Map<int, CartItem> get items => {..._items};
  Map<int, CartItem> get bookedItems => {..._bookedItems};

  int get itemCount => _items.length;
  int get bookedCount => _bookedItems.length;

  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  // --- Корзина ---
  void addItem(ProductModel product) {
    if (product.id == null) return; // Защита от null
    
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id!,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items[product.id!] = CartItem(product: product, quantity: 1);
    }
    notifyListeners();
  }

  void addItemWithQuantity(ProductModel product, int quantity) {
    if (product.id == null) return; // Защита от null
    
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id!,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity + quantity,
        ),
      );
    } else {
      _items[product.id!] = CartItem(product: product, quantity: quantity);
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(int productId) {
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

  void updateQuantity(int productId, int quantity) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity = quantity;
      notifyListeners();
    }
  }

  int getQuantity(int productId) => _items[productId]?.quantity ?? 0;
  bool isInCart(int productId) => _items.containsKey(productId);

  void clear() {
    _items.clear();
    notifyListeners();
  }

  // --- Забронированные детали ---
  void bookItem(ProductModel product, int quantity) {
    if (product.id == null) return; // Защита от null
    
    if (_bookedItems.containsKey(product.id)) {
      _bookedItems.update(
        product.id!,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity + quantity,
        ),
      );
    } else {
      _bookedItems[product.id!] = CartItem(product: product, quantity: quantity);
    }
    notifyListeners();
  }

  bool isBooked(int productId) => _bookedItems.containsKey(productId);

  void removeBookedItem(int productId) {
    _bookedItems.remove(productId);
    notifyListeners();
  }
}

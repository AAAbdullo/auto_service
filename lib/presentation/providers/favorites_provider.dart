import 'package:flutter/foundation.dart';
import '../../data/datasources/local/local_storage.dart';

class FavoritesProvider with ChangeNotifier {
  final LocalStorage _localStorage = LocalStorage();
  Set<String> _favoriteIds = {};

  Set<String> get favoriteIds => {..._favoriteIds};

  FavoritesProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _localStorage.getFavorites();
    _favoriteIds = favorites.toSet();
    notifyListeners();
  }

  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  Future<void> toggleFavorite(String productId) async {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
      await _localStorage.removeFavorite(productId);
    } else {
      _favoriteIds.add(productId);
      await _localStorage.addFavorite(productId);
    }
    notifyListeners();
  }
}

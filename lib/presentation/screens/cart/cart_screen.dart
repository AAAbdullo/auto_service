import 'package:auto_service/data/datasources/local/local_storage.dart';
import 'package:auto_service/presentation/providers/booking_provider.dart';
import 'package:auto_service/presentation/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  // Безопасный метод перевода названия
  String _getTranslatedName(dynamic product) {
    try {
      if (product.nameKey != null && product.nameKey!.isNotEmpty) {
        return product.nameKey!.tr();
      }
    } catch (_) {}
    return product.name;
  }

  // Безопасный метод перевода описания

  // Безопасный метод перевода гарантии

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('cart_title'.tr()), centerTitle: true),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.itemCount == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'cart_empty'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'cart_empty_subtitle'.tr(),
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final cartItem = cart.items.values.toList()[index];
                    return RepaintBoundary(
                      child: _buildCartItem(context, cartItem, cart),
                    );
                  },
                ),
              ),
              _buildBottomBar(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItem cartItem,
    CartProvider cart,
  ) {
    final product = cartItem.product;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl ?? 'https://via.placeholder.com/100',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTranslatedName(product),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(0)} ${'currency'.tr()}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          cart.removeSingleItem(product.id ?? 0);
                        },
                        icon: Icon(
                          cartItem.quantity > 1
                              ? Icons.remove_circle_outline
                              : Icons.delete_outline,
                          color: Colors.red,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${cartItem.quantity}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          cart.addItem(product);
                        },
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFF0D47A1),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    cart.removeItem(product.id ?? 0);
                  },
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Text(
                  '${cartItem.totalPrice.toStringAsFixed(0)} ${'currency'.tr()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'cart_total'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${cart.totalAmount.toStringAsFixed(0)} ${'currency'.tr()}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 🔹 Кнопки "Оформить заказ" и "Забронировать"
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleCheckout(context, cart, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'cart_checkout'.tr(), // оформить заказ
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleCheckout(
    BuildContext context,
    CartProvider cart,
    bool isBooking,
  ) {
    final title = isBooking ? 'booking_title'.tr() : 'cart_checkout_title'.tr();
    final subtitle = isBooking
        ? 'booking_subtitle'.tr()
        : 'cart_checkout_subtitle'.tr();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(subtitle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              final localStorage = LocalStorage();
              final bookingProvider = Provider.of<BookingProvider>(
                context,
                listen: false,
              );

              if (isBooking) {
                // 🔹 Сохраняем товары как "забронированные"
                for (var item in cart.items.values) {
                  bookingProvider.addBooking(item.product);
                }
              } else {
                // 🔹 Сохраняем товары в локальное хранилище как заказы
                for (var item in cart.items.values) {
                  // Создаем копию продукта с правильным количеством
                  final productWithQuantity = item.product.copyWith(
                    quantity: item.quantity,
                  );
                  await localStorage.addOrder(productWithQuantity);
                }
              }

              cart.clear();

              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isBooking
                          ? 'added_to_booking'.tr()
                          : 'added_to_cart'.tr(),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
            ),
            child: Text(
              'confirm'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

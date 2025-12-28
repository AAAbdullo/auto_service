import 'package:auto_service/data/datasources/local/local_storage.dart';
import 'package:auto_service/data/datasources/repositories/product_repositories.dart';
import 'package:auto_service/data/models/product_model.dart';
import 'package:auto_service/presentation/screens/shop/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late final ProductRepository _ordersRepository;
  List<ProductModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ordersRepository = ProductRepository(LocalStorage());
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      // Загружаем список заказов
      _orders = await _ordersRepository.getOrders();
    } catch (_) {
      _orders = [];
    }

    setState(() => _isLoading = false);
  }

  String _getTranslatedName(ProductModel order) {
    if (order.nameKey != null && order.nameKey!.isNotEmpty) {
      return order.nameKey!.tr();
    }
    return order.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('profile_my_orders'.tr())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? Center(
              child: Text(
                'orders_empty'.tr(),
                style: const TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _orders.length,
              addAutomaticKeepAlives: false, // Оптимизация памяти
              addRepaintBoundaries: true,
              cacheExtent: 500, // Кэш для плавного скролла
              itemBuilder: (context, index) {
                final order = _orders[index];
                final quantity = order.quantity;
                final totalPrice = order.price * quantity;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: order.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: order.imageUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                memCacheWidth: 112, // 2x для retina
                                memCacheHeight: 112,
                                maxWidthDiskCache: 200,
                                maxHeightDiskCache: 200,
                                placeholder: (context, url) => Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 24,
                                  ),
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                      ),
                      title: Text(
                        _getTranslatedName(order),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${'quantity'.tr()}: $quantity ${'pcs'.tr()}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${'total'.tr()}: ${totalPrice.toStringAsFixed(0)} ${'currency'.tr()}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              product: order,
                              initialQuantity: quantity,
                              showActions:
                                  false, // Скрываем кнопки для заказанных товаров
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
